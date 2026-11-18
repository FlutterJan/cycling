import 'dart:math' as math;

import 'race_stage.dart';
import 'stage_segment.dart';
import 'tour_race.dart';

/// Identyfikator wyścigu w ekspansji kalendarza UCI na Ameryki i Oceanię.
enum AmericasOceaniaRaceId {
  santosTourDownUnder,
  cadelEvansGreatOceanRoadRace,
  tourColombia21,
  vueltaASanJuan,
  gpCyclisteDeQuebec,
  gpCyclisteDeMontreal;

  String toJson() => name;

  static AmericasOceaniaRaceId fromJson(String value) {
    return AmericasOceaniaRaceId.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AmericasOceaniaRaceId.santosTourDownUnder,
    );
  }
}

/// Kontynentalny region wyścigowy ekspansji UCI poza Europę.
enum AmericasOceaniaRegion {
  oceaniaAustralia,
  southAmerica,
  northAmerica;

  String toJson() => name;

  static AmericasOceaniaRegion fromJson(String value) {
    return AmericasOceaniaRegion.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AmericasOceaniaRegion.oceaniaAustralia,
    );
  }
}

/// Okno kalendarzowe w sezonie kolarskim UCI.
enum SeasonWindowPhase {
  seasonOpener,
  seasonCloser;

  String toJson() => name;

  static SeasonWindowPhase fromJson(String value) {
    return SeasonWindowPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SeasonWindowPhase.seasonOpener,
    );
  }
}

/// Dominujące wyzwanie klimatyczno-terenowe w regionie Ameryk lub Oceanii.
enum AmericasOceaniaClimateHazard {
  australianOutbackExtremeHeat,
  southernOceanCoastalCrosswind,
  andeanHighAltitudeHypoxia,
  urbanPuncheurCircuitHumidity;

  String toJson() => name;

  static AmericasOceaniaClimateHazard fromJson(String value) {
    return AmericasOceaniaClimateHazard.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AmericasOceaniaClimateHazard.australianOutbackExtremeHeat,
    );
  }
}

/// Charakterystyczny sektor lub finałowy podjazd danego wyścigu.
enum AmericasOceaniaSignatureFeature {
  willungaHillExplosiveClimb,
  southernOceanEchelonCoast,
  altoDelColorado3265mSummit,
  colombianAndesAltitudePass,
  quebecCoteDeLaMontagneCircuit,
  montrealCamillienHoudeCircuit;

  String toJson() => name;

  static AmericasOceaniaSignatureFeature fromJson(String value) {
    return AmericasOceaniaSignatureFeature.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AmericasOceaniaSignatureFeature.willungaHillExplosiveClimb,
    );
  }
}

/// Protokół przygotowania drużyny przed startem międzykontynentalnym.
enum AmericasOceaniaAcclimatizationMethod {
  none,
  heatChamberAndIceCooling,
  crosswindEchelonBriefing,
  hypobaricAltitudeCamp,
  puncheurVo2MaxSharpening;

  String toJson() => name;

  static AmericasOceaniaAcclimatizationMethod fromJson(String value) {
    return AmericasOceaniaAcclimatizationMethod.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AmericasOceaniaAcclimatizationMethod.none,
    );
  }
}

/// Profil logistyki lotniczej, termiki, wiatru i wysokości n.p.m.
class AmericasOceaniaLogisticsProfile {
  final double flightHoursFromEurope;
  final int timeZoneOffsetHours;
  final int travelCostPerSquadEur;
  final int recommendedAcclimatizationDays;
  final double startAltitudeMeters;
  final double peakAltitudeMeters;
  final double minTemperatureCelsius;
  final double maxTemperatureCelsius;
  final double maxCrosswindKmh;
  final AmericasOceaniaAcclimatizationMethod recommendedMethod;

  const AmericasOceaniaLogisticsProfile({
    required this.flightHoursFromEurope,
    required this.timeZoneOffsetHours,
    required this.travelCostPerSquadEur,
    required this.recommendedAcclimatizationDays,
    required this.startAltitudeMeters,
    required this.peakAltitudeMeters,
    required this.minTemperatureCelsius,
    required this.maxTemperatureCelsius,
    required this.maxCrosswindKmh,
    required this.recommendedMethod,
  });

  /// Wskaźnik gotowości aklimatyzacyjnej zespołu (0.0 – 1.0).
  double computeReadinessScore({
    required int daysOnSite,
    required AmericasOceaniaAcclimatizationMethod method,
  }) {
    final safeDays = math.max(0, daysOnSite);
    final targetDays = math.max(1, recommendedAcclimatizationDays);
    final daysRatio = (safeDays / targetDays).clamp(0.0, 1.0);

    double methodBonus = 0.0;
    if (method == recommendedMethod) {
      methodBonus = 0.25;
    } else if (method != AmericasOceaniaAcclimatizationMethod.none) {
      methodBonus = 0.12;
    }

    return (daysRatio * 0.75 + methodBonus).clamp(0.0, 1.0);
  }

  /// Szacowany spadek mocy tlenowej (%) na dużej wysokości bez pełnej adaptacji.
  double computeHypoxiaPowerDropPercent() {
    if (peakAltitudeMeters <= 1500.0) return 0.0;
    final excessMeters = peakAltitudeMeters - 1500.0;
    return (excessMeters / 1000.0 * 6.2).clamp(0.0, 14.0);
  }

  /// Indeks stresu cieplnego (0.0 – 1.0), kluczowy dla upałów 38–43°C w Australii.
  double computeHeatStressIndex() {
    if (maxTemperatureCelsius <= 26.0) return 0.15;
    return ((maxTemperatureCelsius - 26.0) / 18.0).clamp(0.0, 1.0);
  }

  /// Efektywna kara wydolnościowa (%) wynikająca z jet lagu, upału lub wysokości.
  double computeClimateAndAltitudePenaltyPercent({
    required int daysOnSite,
    required AmericasOceaniaAcclimatizationMethod method,
  }) {
    final readiness = computeReadinessScore(
      daysOnSite: daysOnSite,
      method: method,
    );
    final altitudePenalty = computeHypoxiaPowerDropPercent() * 0.55;
    final heatPenalty = computeHeatStressIndex() * 4.5;
    final jetLagPenalty = timeZoneOffsetHours.abs() >= 6 ? 3.2 : 1.5;
    final totalMaxPenalty = altitudePenalty + heatPenalty + jetLagPenalty;
    return ((1.0 - readiness) * totalMaxPenalty).clamp(0.0, 16.0);
  }

  AmericasOceaniaLogisticsProfile copyWith({
    double? flightHoursFromEurope,
    int? timeZoneOffsetHours,
    int? travelCostPerSquadEur,
    int? recommendedAcclimatizationDays,
    double? startAltitudeMeters,
    double? peakAltitudeMeters,
    double? minTemperatureCelsius,
    double? maxTemperatureCelsius,
    double? maxCrosswindKmh,
    AmericasOceaniaAcclimatizationMethod? recommendedMethod,
  }) {
    return AmericasOceaniaLogisticsProfile(
      flightHoursFromEurope:
          flightHoursFromEurope ?? this.flightHoursFromEurope,
      timeZoneOffsetHours: timeZoneOffsetHours ?? this.timeZoneOffsetHours,
      travelCostPerSquadEur:
          travelCostPerSquadEur ?? this.travelCostPerSquadEur,
      recommendedAcclimatizationDays:
          recommendedAcclimatizationDays ?? this.recommendedAcclimatizationDays,
      startAltitudeMeters: startAltitudeMeters ?? this.startAltitudeMeters,
      peakAltitudeMeters: peakAltitudeMeters ?? this.peakAltitudeMeters,
      minTemperatureCelsius:
          minTemperatureCelsius ?? this.minTemperatureCelsius,
      maxTemperatureCelsius:
          maxTemperatureCelsius ?? this.maxTemperatureCelsius,
      maxCrosswindKmh: maxCrosswindKmh ?? this.maxCrosswindKmh,
      recommendedMethod: recommendedMethod ?? this.recommendedMethod,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flightHoursFromEurope': flightHoursFromEurope,
      'timeZoneOffsetHours': timeZoneOffsetHours,
      'travelCostPerSquadEur': travelCostPerSquadEur,
      'recommendedAcclimatizationDays': recommendedAcclimatizationDays,
      'startAltitudeMeters': startAltitudeMeters,
      'peakAltitudeMeters': peakAltitudeMeters,
      'minTemperatureCelsius': minTemperatureCelsius,
      'maxTemperatureCelsius': maxTemperatureCelsius,
      'maxCrosswindKmh': maxCrosswindKmh,
      'recommendedMethod': recommendedMethod.toJson(),
    };
  }

  factory AmericasOceaniaLogisticsProfile.fromJson(Map<String, dynamic> json) {
    return AmericasOceaniaLogisticsProfile(
      flightHoursFromEurope:
          (json['flightHoursFromEurope'] as num?)?.toDouble() ?? 14.0,
      timeZoneOffsetHours: (json['timeZoneOffsetHours'] as num?)?.toInt() ?? 0,
      travelCostPerSquadEur:
          (json['travelCostPerSquadEur'] as num?)?.toInt() ?? 52000,
      recommendedAcclimatizationDays:
          (json['recommendedAcclimatizationDays'] as num?)?.toInt() ?? 5,
      startAltitudeMeters:
          (json['startAltitudeMeters'] as num?)?.toDouble() ?? 50.0,
      peakAltitudeMeters:
          (json['peakAltitudeMeters'] as num?)?.toDouble() ?? 500.0,
      minTemperatureCelsius:
          (json['minTemperatureCelsius'] as num?)?.toDouble() ?? 20.0,
      maxTemperatureCelsius:
          (json['maxTemperatureCelsius'] as num?)?.toDouble() ?? 30.0,
      maxCrosswindKmh:
          (json['maxCrosswindKmh'] as num?)?.toDouble() ?? 22.0,
      recommendedMethod: AmericasOceaniaAcclimatizationMethod.fromJson(
        json['recommendedMethod'] as String? ?? 'none',
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AmericasOceaniaLogisticsProfile &&
        other.flightHoursFromEurope == flightHoursFromEurope &&
        other.timeZoneOffsetHours == timeZoneOffsetHours &&
        other.travelCostPerSquadEur == travelCostPerSquadEur &&
        other.recommendedAcclimatizationDays ==
            recommendedAcclimatizationDays &&
        other.startAltitudeMeters == startAltitudeMeters &&
        other.peakAltitudeMeters == peakAltitudeMeters &&
        other.minTemperatureCelsius == minTemperatureCelsius &&
        other.maxTemperatureCelsius == maxTemperatureCelsius &&
        other.maxCrosswindKmh == maxCrosswindKmh &&
        other.recommendedMethod == recommendedMethod;
  }

  @override
  int get hashCode => Object.hash(
        flightHoursFromEurope,
        timeZoneOffsetHours,
        travelCostPerSquadEur,
        recommendedAcclimatizationDays,
        startAltitudeMeters,
        peakAltitudeMeters,
        minTemperatureCelsius,
        maxTemperatureCelsius,
        maxCrosswindKmh,
        recommendedMethod,
      );
}

/// Szablon pojedynczego etapu lub wyścigu jednodniowego w Amerykach / Oceanii.
class AmericasOceaniaStageTemplate {
  final int stageNumber;
  final String name;
  final StageType stageType;
  final double distanceKm;
  final double elevationGainM;
  final double startElevationM;
  final double endElevationM;
  final double baseTemperatureCelsius;
  final WeatherCondition weatherCondition;
  final double windSpeedKmh;
  final double roadBearingDegrees;
  final double windDirectionDegrees;
  final int lapCount;
  final AmericasOceaniaSignatureFeature signatureFeature;
  final SegmentSurfaceType finalSurfaceType;

  const AmericasOceaniaStageTemplate({
    required this.stageNumber,
    required this.name,
    required this.stageType,
    required this.distanceKm,
    required this.elevationGainM,
    required this.startElevationM,
    required this.endElevationM,
    required this.baseTemperatureCelsius,
    required this.weatherCondition,
    required this.windSpeedKmh,
    required this.roadBearingDegrees,
    required this.windDirectionDegrees,
    this.lapCount = 1,
    required this.signatureFeature,
    required this.finalSurfaceType,
  });

  /// Buduje pełny obiekt `RaceStage` z realistycznymi segmentami `StageSegment`.
  RaceStage toRaceStage({required String raceId}) {
    final safeDistance = math.max(12.0, distanceKm);
    final introKm = double.parse((safeDistance * 0.45).toStringAsFixed(1));
    final keySectorKm = double.parse((safeDistance * 0.35).toStringAsFixed(1));
    final finalKm = double.parse(
      math.max(2.0, safeDistance - introKm - keySectorKm).toStringAsFixed(1),
    );

    final midAltitude = startElevationM + (elevationGainM * 0.42);
    final keyPeakAltitude = math.max(
      endElevationM,
      startElevationM + elevationGainM * 0.85,
    );

    final keyClassification = switch (signatureFeature) {
      AmericasOceaniaSignatureFeature.willungaHillExplosiveClimb =>
        SegmentClassification.cat1,
      AmericasOceaniaSignatureFeature.altoDelColorado3265mSummit =>
        SegmentClassification.horsCategorie,
      AmericasOceaniaSignatureFeature.colombianAndesAltitudePass =>
        SegmentClassification.horsCategorie,
      AmericasOceaniaSignatureFeature.montrealCamillienHoudeCircuit =>
        SegmentClassification.cat2,
      AmericasOceaniaSignatureFeature.quebecCoteDeLaMontagneCircuit =>
        SegmentClassification.cat3,
      AmericasOceaniaSignatureFeature.southernOceanEchelonCoast =>
        SegmentClassification.intermediateSprint,
    };

    final keyTechnical = switch (signatureFeature) {
      AmericasOceaniaSignatureFeature.quebecCoteDeLaMontagneCircuit ||
      AmericasOceaniaSignatureFeature.montrealCamillienHoudeCircuit =>
        78.0,
      AmericasOceaniaSignatureFeature.southernOceanEchelonCoast => 68.0,
      AmericasOceaniaSignatureFeature.willungaHillExplosiveClimb => 54.0,
      AmericasOceaniaSignatureFeature.altoDelColorado3265mSummit => 48.0,
      AmericasOceaniaSignatureFeature.colombianAndesAltitudePass => 52.0,
    };

    final segments = <StageSegment>[
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: introKm,
        startElevationM: startElevationM,
        endElevationM: midAltitude,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 32.0,
        windDirectionDegrees: windDirectionDegrees,
        roadBearingDegrees: roadBearingDegrees,
        sprintOrKomClassification: SegmentClassification.intermediateSprint,
      ),
      StageSegment(
        index: 1,
        startKm: introKm,
        lengthKm: keySectorKm,
        startElevationM: midAltitude,
        endElevationM: keyPeakAltitude,
        surfaceType: finalSurfaceType,
        technicalDifficulty: keyTechnical,
        windDirectionDegrees: windDirectionDegrees,
        roadBearingDegrees: (roadBearingDegrees + 35.0) % 360.0,
        sprintOrKomClassification: keyClassification,
      ),
      StageSegment(
        index: 2,
        startKm: introKm + keySectorKm,
        lengthKm: finalKm,
        startElevationM: keyPeakAltitude,
        endElevationM: endElevationM,
        surfaceType: finalSurfaceType,
        technicalDifficulty: keyTechnical * 0.85,
        windDirectionDegrees: windDirectionDegrees,
        roadBearingDegrees: roadBearingDegrees,
        sprintOrKomClassification: SegmentClassification.finishLine,
      ),
    ];

    return RaceStage(
      id: '${raceId}_stage_$stageNumber',
      stageNumber: stageNumber,
      name: name,
      stageType: stageType,
      segments: List<StageSegment>.unmodifiable(segments),
      baseTemperatureCelsius: baseTemperatureCelsius,
      weatherCondition: weatherCondition,
      windSpeedKmh: windSpeedKmh,
    );
  }

  AmericasOceaniaStageTemplate copyWith({
    int? stageNumber,
    String? name,
    StageType? stageType,
    double? distanceKm,
    double? elevationGainM,
    double? startElevationM,
    double? endElevationM,
    double? baseTemperatureCelsius,
    WeatherCondition? weatherCondition,
    double? windSpeedKmh,
    double? roadBearingDegrees,
    double? windDirectionDegrees,
    int? lapCount,
    AmericasOceaniaSignatureFeature? signatureFeature,
    SegmentSurfaceType? finalSurfaceType,
  }) {
    return AmericasOceaniaStageTemplate(
      stageNumber: stageNumber ?? this.stageNumber,
      name: name ?? this.name,
      stageType: stageType ?? this.stageType,
      distanceKm: distanceKm ?? this.distanceKm,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      startElevationM: startElevationM ?? this.startElevationM,
      endElevationM: endElevationM ?? this.endElevationM,
      baseTemperatureCelsius:
          baseTemperatureCelsius ?? this.baseTemperatureCelsius,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      windSpeedKmh: windSpeedKmh ?? this.windSpeedKmh,
      roadBearingDegrees: roadBearingDegrees ?? this.roadBearingDegrees,
      windDirectionDegrees: windDirectionDegrees ?? this.windDirectionDegrees,
      lapCount: lapCount ?? this.lapCount,
      signatureFeature: signatureFeature ?? this.signatureFeature,
      finalSurfaceType: finalSurfaceType ?? this.finalSurfaceType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stageNumber': stageNumber,
      'name': name,
      'stageType': stageType.toJson(),
      'distanceKm': distanceKm,
      'elevationGainM': elevationGainM,
      'startElevationM': startElevationM,
      'endElevationM': endElevationM,
      'baseTemperatureCelsius': baseTemperatureCelsius,
      'weatherCondition': weatherCondition.toJson(),
      'windSpeedKmh': windSpeedKmh,
      'roadBearingDegrees': roadBearingDegrees,
      'windDirectionDegrees': windDirectionDegrees,
      'lapCount': lapCount,
      'signatureFeature': signatureFeature.toJson(),
      'finalSurfaceType': finalSurfaceType.toJson(),
    };
  }

  factory AmericasOceaniaStageTemplate.fromJson(Map<String, dynamic> json) {
    return AmericasOceaniaStageTemplate(
      stageNumber: (json['stageNumber'] as num?)?.toInt() ?? 1,
      name: json['name'] as String? ?? 'Stage',
      stageType: StageType.fromJson(json['stageType'] as String? ?? 'hilly'),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 150.0,
      elevationGainM: (json['elevationGainM'] as num?)?.toDouble() ?? 1600.0,
      startElevationM: (json['startElevationM'] as num?)?.toDouble() ?? 100.0,
      endElevationM: (json['endElevationM'] as num?)?.toDouble() ?? 250.0,
      baseTemperatureCelsius:
          (json['baseTemperatureCelsius'] as num?)?.toDouble() ?? 26.0,
      weatherCondition: WeatherCondition.fromJson(
        json['weatherCondition'] as String? ?? 'sunny',
      ),
      windSpeedKmh: (json['windSpeedKmh'] as num?)?.toDouble() ?? 18.0,
      roadBearingDegrees:
          (json['roadBearingDegrees'] as num?)?.toDouble() ?? 90.0,
      windDirectionDegrees:
          (json['windDirectionDegrees'] as num?)?.toDouble() ?? 180.0,
      lapCount: (json['lapCount'] as num?)?.toInt() ?? 1,
      signatureFeature: AmericasOceaniaSignatureFeature.fromJson(
        json['signatureFeature'] as String? ?? 'willungaHillExplosiveClimb',
      ),
      finalSurfaceType: SegmentSurfaceType.fromJson(
        json['finalSurfaceType'] as String? ?? 'smoothAsphalt',
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AmericasOceaniaStageTemplate &&
        other.stageNumber == stageNumber &&
        other.name == name &&
        other.stageType == stageType &&
        other.distanceKm == distanceKm &&
        other.endElevationM == endElevationM &&
        other.signatureFeature == signatureFeature;
  }

  @override
  int get hashCode => Object.hash(
        stageNumber,
        name,
        stageType,
        distanceKm,
        endElevationM,
        signatureFeature,
      );
}

/// Pełna definicja wyścigu w Amerykach lub Oceanii w kalendarzu UCI.
class AmericasOceaniaRaceDefinition {
  final AmericasOceaniaRaceId raceId;
  final String officialName;
  final String countryName;
  final String countryIso;
  final AmericasOceaniaRegion region;
  final SeasonWindowPhase seasonWindow;
  final String uciCode;
  final RaceCategory uciCategory;
  final bool isOneDayClassic;
  final int startMonth;
  final int startDay;
  final int ridersPerTeam;
  final int prizePoolEur;
  final int uciPointsWinner;
  final AmericasOceaniaClimateHazard climateHazard;
  final AmericasOceaniaLogisticsProfile logistics;
  final List<AmericasOceaniaStageTemplate> stageTemplates;
  final String culturalSummary;

  const AmericasOceaniaRaceDefinition({
    required this.raceId,
    required this.officialName,
    required this.countryName,
    required this.countryIso,
    required this.region,
    required this.seasonWindow,
    required this.uciCode,
    required this.uciCategory,
    required this.isOneDayClassic,
    required this.startMonth,
    required this.startDay,
    required this.ridersPerTeam,
    required this.prizePoolEur,
    required this.uciPointsWinner,
    required this.climateHazard,
    required this.logistics,
    required this.stageTemplates,
    required this.culturalSummary,
  });

  double get totalDistanceKm => stageTemplates.fold<double>(
        0.0,
        (sum, stage) => sum + stage.distanceKm,
      );

  double get totalElevationGainM => stageTemplates.fold<double>(
        0.0,
        (sum, stage) => sum + stage.elevationGainM,
      );

  double get peakAltitudeMeters {
    if (stageTemplates.isEmpty) return logistics.peakAltitudeMeters;
    double highest = logistics.peakAltitudeMeters;
    for (final stage in stageTemplates) {
      highest = math.max(
        highest,
        math.max(stage.startElevationM, stage.endElevationM),
      );
    }
    return highest;
  }

  int get stageCount => stageTemplates.length;

  /// Konwertuje definicję wyścigu na pełny obiekt `TourRace` do `SeasonCalendar`.
  TourRace toTourRace({List<String> participatingTeamIds = const []}) {
    final id = 'americas_oceania_${raceId.name}';
    final stages = stageTemplates
        .map((template) => template.toRaceStage(raceId: id))
        .toList(growable: false);

    return TourRace(
      id: id,
      name: officialName,
      countryIso: countryIso,
      uciCategory: uciCategory,
      startMonth: startMonth,
      startDay: startDay,
      stages: stages,
      prizePoolEur: prizePoolEur,
      participatingTeamIds: List<String>.unmodifiable(participatingTeamIds),
      ridersPerTeam: ridersPerTeam,
      classifications: const RaceClassifications(
        generalClassification: [],
        pointsClassification: [],
        mountainsClassification: [],
        youthClassification: [],
        teamClassification: [],
      ),
    );
  }

  AmericasOceaniaRaceDefinition copyWith({
    AmericasOceaniaRaceId? raceId,
    String? officialName,
    String? countryName,
    String? countryIso,
    AmericasOceaniaRegion? region,
    SeasonWindowPhase? seasonWindow,
    String? uciCode,
    RaceCategory? uciCategory,
    bool? isOneDayClassic,
    int? startMonth,
    int? startDay,
    int? ridersPerTeam,
    int? prizePoolEur,
    int? uciPointsWinner,
    AmericasOceaniaClimateHazard? climateHazard,
    AmericasOceaniaLogisticsProfile? logistics,
    List<AmericasOceaniaStageTemplate>? stageTemplates,
    String? culturalSummary,
  }) {
    return AmericasOceaniaRaceDefinition(
      raceId: raceId ?? this.raceId,
      officialName: officialName ?? this.officialName,
      countryName: countryName ?? this.countryName,
      countryIso: countryIso ?? this.countryIso,
      region: region ?? this.region,
      seasonWindow: seasonWindow ?? this.seasonWindow,
      uciCode: uciCode ?? this.uciCode,
      uciCategory: uciCategory ?? this.uciCategory,
      isOneDayClassic: isOneDayClassic ?? this.isOneDayClassic,
      startMonth: startMonth ?? this.startMonth,
      startDay: startDay ?? this.startDay,
      ridersPerTeam: ridersPerTeam ?? this.ridersPerTeam,
      prizePoolEur: prizePoolEur ?? this.prizePoolEur,
      uciPointsWinner: uciPointsWinner ?? this.uciPointsWinner,
      climateHazard: climateHazard ?? this.climateHazard,
      logistics: logistics ?? this.logistics,
      stageTemplates: stageTemplates != null
          ? List<AmericasOceaniaStageTemplate>.unmodifiable(stageTemplates)
          : this.stageTemplates,
      culturalSummary: culturalSummary ?? this.culturalSummary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'raceId': raceId.toJson(),
      'officialName': officialName,
      'countryName': countryName,
      'countryIso': countryIso,
      'region': region.toJson(),
      'seasonWindow': seasonWindow.toJson(),
      'uciCode': uciCode,
      'uciCategory': uciCategory.toJson(),
      'isOneDayClassic': isOneDayClassic,
      'startMonth': startMonth,
      'startDay': startDay,
      'ridersPerTeam': ridersPerTeam,
      'prizePoolEur': prizePoolEur,
      'uciPointsWinner': uciPointsWinner,
      'climateHazard': climateHazard.toJson(),
      'logistics': logistics.toJson(),
      'stageTemplates': stageTemplates.map((e) => e.toJson()).toList(),
      'culturalSummary': culturalSummary,
    };
  }

  factory AmericasOceaniaRaceDefinition.fromJson(Map<String, dynamic> json) {
    return AmericasOceaniaRaceDefinition(
      raceId: AmericasOceaniaRaceId.fromJson(
        json['raceId'] as String? ?? 'santosTourDownUnder',
      ),
      officialName: json['officialName'] as String? ?? 'Americas & Oceania Race',
      countryName: json['countryName'] as String? ?? 'Australia',
      countryIso: json['countryIso'] as String? ?? 'AUS',
      region: AmericasOceaniaRegion.fromJson(
        json['region'] as String? ?? 'oceaniaAustralia',
      ),
      seasonWindow: SeasonWindowPhase.fromJson(
        json['seasonWindow'] as String? ?? 'seasonOpener',
      ),
      uciCode: json['uciCode'] as String? ?? '2.UWT',
      uciCategory: RaceCategory.fromJson(
        json['uciCategory'] as String? ?? 'worldTourStageRace',
      ),
      isOneDayClassic: json['isOneDayClassic'] as bool? ?? false,
      startMonth: (json['startMonth'] as num?)?.toInt() ?? 1,
      startDay: (json['startDay'] as num?)?.toInt() ?? 20,
      ridersPerTeam: (json['ridersPerTeam'] as num?)?.toInt() ?? 7,
      prizePoolEur: (json['prizePoolEur'] as num?)?.toInt() ?? 180000,
      uciPointsWinner: (json['uciPointsWinner'] as num?)?.toInt() ?? 500,
      climateHazard: AmericasOceaniaClimateHazard.fromJson(
        json['climateHazard'] as String? ?? 'australianOutbackExtremeHeat',
      ),
      logistics: AmericasOceaniaLogisticsProfile.fromJson(
        json['logistics'] as Map<String, dynamic>? ?? const {},
      ),
      stageTemplates: (json['stageTemplates'] as List<dynamic>? ?? const [])
          .map(
            (e) => AmericasOceaniaStageTemplate.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      culturalSummary: json['culturalSummary'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AmericasOceaniaRaceDefinition &&
        other.raceId == raceId &&
        other.uciCode == uciCode &&
        other.seasonWindow == seasonWindow;
  }

  @override
  int get hashCode => Object.hash(raceId, uciCode, seasonWindow);
}

/// Rekord historyczny startu drużyny w wyścigu w Amerykach lub Oceanii.
class AmericasOceaniaParticipationRecord {
  final AmericasOceaniaRaceId raceId;
  final int seasonYear;
  final int daysAcclimatized;
  final AmericasOceaniaAcclimatizationMethod acclimatizationMethod;
  final int? bestRank;
  final int stageWins;
  final int uciPointsEarned;
  final int netTravelBalanceEur;

  const AmericasOceaniaParticipationRecord({
    required this.raceId,
    required this.seasonYear,
    required this.daysAcclimatized,
    required this.acclimatizationMethod,
    this.bestRank,
    required this.stageWins,
    required this.uciPointsEarned,
    required this.netTravelBalanceEur,
  });

  AmericasOceaniaParticipationRecord copyWith({
    AmericasOceaniaRaceId? raceId,
    int? seasonYear,
    int? daysAcclimatized,
    AmericasOceaniaAcclimatizationMethod? acclimatizationMethod,
    int? bestRank,
    int? stageWins,
    int? uciPointsEarned,
    int? netTravelBalanceEur,
  }) {
    return AmericasOceaniaParticipationRecord(
      raceId: raceId ?? this.raceId,
      seasonYear: seasonYear ?? this.seasonYear,
      daysAcclimatized: daysAcclimatized ?? this.daysAcclimatized,
      acclimatizationMethod:
          acclimatizationMethod ?? this.acclimatizationMethod,
      bestRank: bestRank ?? this.bestRank,
      stageWins: stageWins ?? this.stageWins,
      uciPointsEarned: uciPointsEarned ?? this.uciPointsEarned,
      netTravelBalanceEur: netTravelBalanceEur ?? this.netTravelBalanceEur,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'raceId': raceId.toJson(),
      'seasonYear': seasonYear,
      'daysAcclimatized': daysAcclimatized,
      'acclimatizationMethod': acclimatizationMethod.toJson(),
      'bestRank': bestRank,
      'stageWins': stageWins,
      'uciPointsEarned': uciPointsEarned,
      'netTravelBalanceEur': netTravelBalanceEur,
    };
  }

  factory AmericasOceaniaParticipationRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    return AmericasOceaniaParticipationRecord(
      raceId: AmericasOceaniaRaceId.fromJson(
        json['raceId'] as String? ?? 'santosTourDownUnder',
      ),
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      daysAcclimatized: (json['daysAcclimatized'] as num?)?.toInt() ?? 4,
      acclimatizationMethod: AmericasOceaniaAcclimatizationMethod.fromJson(
        json['acclimatizationMethod'] as String? ?? 'none',
      ),
      bestRank: (json['bestRank'] as num?)?.toInt(),
      stageWins: (json['stageWins'] as num?)?.toInt() ?? 0,
      uciPointsEarned: (json['uciPointsEarned'] as num?)?.toInt() ?? 0,
      netTravelBalanceEur: (json['netTravelBalanceEur'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AmericasOceaniaParticipationRecord &&
        other.raceId == raceId &&
        other.seasonYear == seasonYear &&
        other.uciPointsEarned == uciPointsEarned;
  }

  @override
  int get hashCode => Object.hash(raceId, seasonYear, uciPointsEarned);
}

/// Raport oceny przygotowania drużyny przed startem w Amerykach / Oceanii.
class AmericasOceaniaTourEvaluation {
  final AmericasOceaniaRaceId raceId;
  final String officialName;
  final double readinessScore;
  final double climatePenaltyPercent;
  final double hypoxiaPowerDropPercent;
  final double heatStressIndex;
  final bool isRecommendedForSquad;
  final String tacticalBrief;

  const AmericasOceaniaTourEvaluation({
    required this.raceId,
    required this.officialName,
    required this.readinessScore,
    required this.climatePenaltyPercent,
    required this.hypoxiaPowerDropPercent,
    required this.heatStressIndex,
    required this.isRecommendedForSquad,
    required this.tacticalBrief,
  });
}

/// Główny model ekspansji kalendarza UCI na Amerykę Południową, Północną i Oceanię.
class AmericasAndOceaniaToursModel {
  final int seasonYear;
  final List<AmericasOceaniaRaceDefinition> races;
  final List<AmericasOceaniaParticipationRecord> participationHistory;
  final double americasOceaniaPrestigeScore;
  final double internationalSponsorReachMultiplier;

  const AmericasAndOceaniaToursModel({
    required this.seasonYear,
    required this.races,
    required this.participationHistory,
    required this.americasOceaniaPrestigeScore,
    required this.internationalSponsorReachMultiplier,
  });

  /// Tworzy domyślny, autentyczny kalendarz ekspansji Ameryk i Oceanii.
  factory AmericasAndOceaniaToursModel.standard({int seasonYear = 2026}) {
    return AmericasAndOceaniaToursModel(
      seasonYear: seasonYear,
      races: List<AmericasOceaniaRaceDefinition>.unmodifiable(
        _defaultAmericasAndOceaniaRaces(),
      ),
      participationHistory: const [],
      americasOceaniaPrestigeScore: 30.0,
      internationalSponsorReachMultiplier: 1.12,
    );
  }

  /// Wyścigi otwierające sezon (Australia, Argentyna, Kolumbia).
  List<AmericasOceaniaRaceDefinition> get seasonOpeners => races
      .where((r) => r.seasonWindow == SeasonWindowPhase.seasonOpener)
      .toList(growable: false);

  /// Wyścigi zamykające sezon WorldTour (Québec i Montréal).
  List<AmericasOceaniaRaceDefinition> get seasonClosers => races
      .where((r) => r.seasonWindow == SeasonWindowPhase.seasonCloser)
      .toList(growable: false);

  /// Filtruje wyścigi według kontynentu / regionu.
  List<AmericasOceaniaRaceDefinition> racesByRegion(
    AmericasOceaniaRegion region,
  ) {
    return races.where((r) => r.region == region).toList(growable: false);
  }

  /// Wyszukuje definicję wyścigu po identyfikatorze.
  AmericasOceaniaRaceDefinition? findById(AmericasOceaniaRaceId raceId) {
    for (final race in races) {
      if (race.raceId == raceId) return race;
    }
    return null;
  }

  /// Ocenia gotowość drużyny i ryzyko klimatyczno-wysokościowe przed startem.
  AmericasOceaniaTourEvaluation evaluateRaceEntry({
    required AmericasOceaniaRaceId raceId,
    required int daysOnSite,
    required AmericasOceaniaAcclimatizationMethod method,
    required int availableBudgetEur,
  }) {
    final race = findById(raceId) ?? races.first;
    final readiness = race.logistics.computeReadinessScore(
      daysOnSite: daysOnSite,
      method: method,
    );
    final penalty = race.logistics.computeClimateAndAltitudePenaltyPercent(
      daysOnSite: daysOnSite,
      method: method,
    );
    final hypoxia = race.logistics.computeHypoxiaPowerDropPercent();
    final heatIndex = race.logistics.computeHeatStressIndex();
    final canAfford = availableBudgetEur >= race.logistics.travelCostPerSquadEur;
    final recommended = canAfford && readiness >= 0.65;

    final brief = switch (race.raceId) {
      AmericasOceaniaRaceId.santosTourDownUnder =>
        'Upały 38–43°C wymagają kamizelek chłodzących i nawadniania; decydujący atak na Willunga Hill.',
      AmericasOceaniaRaceId.cadelEvansGreatOceanRoadRace =>
        'Nadmorski wiatr boczny z Oceanu Południowego tworzy wachlarze przed rundą w Geelong.',
      AmericasOceaniaRaceId.tourColombia21 =>
        'Rzadkie powietrze Andów powyżej 2500 m faworyzuje lekkich górali z obozem wysokościowym.',
      AmericasOceaniaRaceId.vueltaASanJuan =>
        'Start na 2500 m i finisz na Alto del Colorado (3265 m n.p.m.) bezlitośnie weryfikują VO2max.',
      AmericasOceaniaRaceId.gpCyclisteDeQuebec =>
        'Miejskie rundy Puncheur z Côte de la Montagne premiują eksplozywne przyspieszenia na ostatnim kilometrze.',
      AmericasOceaniaRaceId.gpCyclisteDeMontreal =>
        'Ponad 4000 m przewyższenia na Voie Camillien-Houde zamienia klasyk w wyścig na wyniszczenie.',
    };

    return AmericasOceaniaTourEvaluation(
      raceId: race.raceId,
      officialName: race.officialName,
      readinessScore: readiness,
      climatePenaltyPercent: penalty,
      hypoxiaPowerDropPercent: hypoxia,
      heatStressIndex: heatIndex,
      isRecommendedForSquad: recommended,
      tacticalBrief: brief,
    );
  }

  /// Zapisuje udział drużyny i aktualizuje prestiż międzynarodowy oraz zasięg.
  AmericasAndOceaniaToursModel recordParticipation(
    AmericasOceaniaParticipationRecord record,
  ) {
    final updatedHistory = <AmericasOceaniaParticipationRecord>[
      ...participationHistory,
      record,
    ];
    final rankBonus =
        record.bestRank != null && record.bestRank! <= 3 ? 5.0 : 1.5;
    final prestigeGain = 2.5 + (record.stageWins * 1.4) + rankBonus;
    final reachGain = record.uciPointsEarned >= 100 ? 0.04 : 0.015;

    return copyWith(
      participationHistory:
          List<AmericasOceaniaParticipationRecord>.unmodifiable(updatedHistory),
      americasOceaniaPrestigeScore:
          (americasOceaniaPrestigeScore + prestigeGain).clamp(0.0, 100.0),
      internationalSponsorReachMultiplier: double.parse(
        (internationalSponsorReachMultiplier + reachGain)
            .clamp(1.0, 2.5)
            .toStringAsFixed(3),
      ),
    );
  }

  /// Generuje wszystkie wyścigi `TourRace` gotowe do wpięcia w `SeasonCalendar`.
  List<TourRace> buildCalendarTourRaces({
    List<String> participatingTeamIds = const [],
  }) {
    return races
        .map(
          (race) => race.toTourRace(participatingTeamIds: participatingTeamIds),
        )
        .toList(growable: false);
  }

  /// Generuje wyścigi otwierające sezon (Australia, Argentyna, Kolumbia).
  List<TourRace> buildSeasonOpenerRaces({
    List<String> participatingTeamIds = const [],
  }) {
    return seasonOpeners
        .map(
          (race) => race.toTourRace(participatingTeamIds: participatingTeamIds),
        )
        .toList(growable: false);
  }

  /// Generuje północnoamerykańskie klasyki zamykające sezon (Québec & Montréal).
  List<TourRace> buildSeasonCloserRaces({
    List<String> participatingTeamIds = const [],
  }) {
    return seasonClosers
        .map(
          (race) => race.toTourRace(participatingTeamIds: participatingTeamIds),
        )
        .toList(growable: false);
  }

  AmericasAndOceaniaToursModel copyWith({
    int? seasonYear,
    List<AmericasOceaniaRaceDefinition>? races,
    List<AmericasOceaniaParticipationRecord>? participationHistory,
    double? americasOceaniaPrestigeScore,
    double? internationalSponsorReachMultiplier,
  }) {
    return AmericasAndOceaniaToursModel(
      seasonYear: seasonYear ?? this.seasonYear,
      races: races != null
          ? List<AmericasOceaniaRaceDefinition>.unmodifiable(races)
          : this.races,
      participationHistory: participationHistory != null
          ? List<AmericasOceaniaParticipationRecord>.unmodifiable(
              participationHistory,
            )
          : this.participationHistory,
      americasOceaniaPrestigeScore:
          americasOceaniaPrestigeScore ?? this.americasOceaniaPrestigeScore,
      internationalSponsorReachMultiplier:
          internationalSponsorReachMultiplier ??
              this.internationalSponsorReachMultiplier,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seasonYear': seasonYear,
      'races': races.map((e) => e.toJson()).toList(),
      'participationHistory':
          participationHistory.map((e) => e.toJson()).toList(),
      'americasOceaniaPrestigeScore': americasOceaniaPrestigeScore,
      'internationalSponsorReachMultiplier':
          internationalSponsorReachMultiplier,
    };
  }

  factory AmericasAndOceaniaToursModel.fromJson(Map<String, dynamic> json) {
    final parsedRaces = (json['races'] as List<dynamic>?)
            ?.map(
              (e) => AmericasOceaniaRaceDefinition.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(growable: false) ??
        _defaultAmericasAndOceaniaRaces();

    return AmericasAndOceaniaToursModel(
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      races: List<AmericasOceaniaRaceDefinition>.unmodifiable(
        parsedRaces.isEmpty ? _defaultAmericasAndOceaniaRaces() : parsedRaces,
      ),
      participationHistory:
          List<AmericasOceaniaParticipationRecord>.unmodifiable(
        (json['participationHistory'] as List<dynamic>? ?? const []).map(
          (e) => AmericasOceaniaParticipationRecord.fromJson(
            e as Map<String, dynamic>,
          ),
        ),
      ),
      americasOceaniaPrestigeScore:
          (json['americasOceaniaPrestigeScore'] as num?)?.toDouble() ?? 30.0,
      internationalSponsorReachMultiplier:
          (json['internationalSponsorReachMultiplier'] as num?)?.toDouble() ??
              1.12,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AmericasAndOceaniaToursModel &&
        other.seasonYear == seasonYear &&
        other.races.length == races.length &&
        other.participationHistory.length == participationHistory.length &&
        other.americasOceaniaPrestigeScore == americasOceaniaPrestigeScore &&
        other.internationalSponsorReachMultiplier ==
            internationalSponsorReachMultiplier;
  }

  @override
  int get hashCode => Object.hash(
        seasonYear,
        races.length,
        participationHistory.length,
        americasOceaniaPrestigeScore,
        internationalSponsorReachMultiplier,
      );

  @override
  String toString() =>
      'AmericasAndOceaniaToursModel($seasonYear: ${races.length} races, prestige=${americasOceaniaPrestigeScore.toStringAsFixed(1)})';
}

List<AmericasOceaniaRaceDefinition> _defaultAmericasAndOceaniaRaces() {
  return const [
    AmericasOceaniaRaceDefinition(
      raceId: AmericasOceaniaRaceId.santosTourDownUnder,
      officialName: 'Santos Tour Down Under',
      countryName: 'Australia',
      countryIso: 'AUS',
      region: AmericasOceaniaRegion.oceaniaAustralia,
      seasonWindow: SeasonWindowPhase.seasonOpener,
      uciCode: '2.UWT',
      uciCategory: RaceCategory.worldTourStageRace,
      isOneDayClassic: false,
      startMonth: 1,
      startDay: 20,
      ridersPerTeam: 7,
      prizePoolEur: 240000,
      uciPointsWinner: 500,
      climateHazard:
          AmericasOceaniaClimateHazard.australianOutbackExtremeHeat,
      logistics: AmericasOceaniaLogisticsProfile(
        flightHoursFromEurope: 21.5,
        timeZoneOffsetHours: 9,
        travelCostPerSquadEur: 74000,
        recommendedAcclimatizationDays: 7,
        startAltitudeMeters: 35.0,
        peakAltitudeMeters: 460.0,
        minTemperatureCelsius: 38.0,
        maxTemperatureCelsius: 43.0,
        maxCrosswindKmh: 28.0,
        recommendedMethod:
            AmericasOceaniaAcclimatizationMethod.heatChamberAndIceCooling,
      ),
      stageTemplates: [
        AmericasOceaniaStageTemplate(
          stageNumber: 1,
          name: 'Tanunda – Barossa Valley',
          stageType: StageType.flat,
          distanceKm: 144.0,
          elevationGainM: 1210.0,
          startElevationM: 265.0,
          endElevationM: 270.0,
          baseTemperatureCelsius: 39.5,
          weatherCondition: WeatherCondition.extremeHeat,
          windSpeedKmh: 21.0,
          roadBearingDegrees: 195.0,
          windDirectionDegrees: 240.0,
          signatureFeature:
              AmericasOceaniaSignatureFeature.willungaHillExplosiveClimb,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
        AmericasOceaniaStageTemplate(
          stageNumber: 2,
          name: 'Norwood – Uraidla (Adelaide Hills)',
          stageType: StageType.hilly,
          distanceKm: 148.5,
          elevationGainM: 2640.0,
          startElevationM: 95.0,
          endElevationM: 455.0,
          baseTemperatureCelsius: 41.0,
          weatherCondition: WeatherCondition.extremeHeat,
          windSpeedKmh: 19.0,
          roadBearingDegrees: 115.0,
          windDirectionDegrees: 220.0,
          signatureFeature:
              AmericasOceaniaSignatureFeature.willungaHillExplosiveClimb,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
        AmericasOceaniaStageTemplate(
          stageNumber: 3,
          name: 'McLaren Vale – Willunga Hill',
          stageType: StageType.summitFinish,
          distanceKm: 131.5,
          elevationGainM: 1980.0,
          startElevationM: 65.0,
          endElevationM: 430.0,
          baseTemperatureCelsius: 42.8,
          weatherCondition: WeatherCondition.extremeHeat,
          windSpeedKmh: 26.0,
          roadBearingDegrees: 170.0,
          windDirectionDegrees: 255.0,
          signatureFeature:
              AmericasOceaniaSignatureFeature.willungaHillExplosiveClimb,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
        AmericasOceaniaStageTemplate(
          stageNumber: 4,
          name: 'Brighton – Mount Lofty',
          stageType: StageType.hilly,
          distanceKm: 128.0,
          elevationGainM: 2350.0,
          startElevationM: 12.0,
          endElevationM: 460.0,
          baseTemperatureCelsius: 38.4,
          weatherCondition: WeatherCondition.extremeHeat,
          windSpeedKmh: 24.0,
          roadBearingDegrees: 85.0,
          windDirectionDegrees: 210.0,
          signatureFeature:
              AmericasOceaniaSignatureFeature.willungaHillExplosiveClimb,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
      ],
      culturalSummary:
          'Otwarcie sezonu UCI WorldTour w Australii Południowej w bezlitosnym upale 38–43°C z kultowym, eksplozywnym podjazdem Willunga Hill.',
    ),
    AmericasOceaniaRaceDefinition(
      raceId: AmericasOceaniaRaceId.cadelEvansGreatOceanRoadRace,
      officialName: 'Cadel Evans Great Ocean Road Race',
      countryName: 'Australia',
      countryIso: 'AUS',
      region: AmericasOceaniaRegion.oceaniaAustralia,
      seasonWindow: SeasonWindowPhase.seasonOpener,
      uciCode: '1.UWT',
      uciCategory: RaceCategory.worldTourOneDay,
      isOneDayClassic: true,
      startMonth: 2,
      startDay: 1,
      ridersPerTeam: 7,
      prizePoolEur: 140000,
      uciPointsWinner: 300,
      climateHazard:
          AmericasOceaniaClimateHazard.southernOceanCoastalCrosswind,
      logistics: AmericasOceaniaLogisticsProfile(
        flightHoursFromEurope: 22.0,
        timeZoneOffsetHours: 10,
        travelCostPerSquadEur: 62000,
        recommendedAcclimatizationDays: 6,
        startAltitudeMeters: 15.0,
        peakAltitudeMeters: 210.0,
        minTemperatureCelsius: 23.0,
        maxTemperatureCelsius: 32.0,
        maxCrosswindKmh: 52.0,
        recommendedMethod:
            AmericasOceaniaAcclimatizationMethod.crosswindEchelonBriefing,
      ),
      stageTemplates: [
        AmericasOceaniaStageTemplate(
          stageNumber: 1,
          name: 'Geelong – Torquay – Challambra Crescent',
          stageType: StageType.hilly,
          distanceKm: 174.3,
          elevationGainM: 1960.0,
          startElevationM: 15.0,
          endElevationM: 22.0,
          baseTemperatureCelsius: 27.5,
          weatherCondition: WeatherCondition.crosswindGale,
          windSpeedKmh: 48.0,
          roadBearingDegrees: 245.0,
          windDirectionDegrees: 160.0,
          lapCount: 4,
          signatureFeature:
              AmericasOceaniaSignatureFeature.southernOceanEchelonCoast,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
      ],
      culturalSummary:
          'Jednodniowy klasyk WorldTour w stanie Wiktoria, gdzie porywisty wiatr boczny z Oceanu Południowego rwie peleton na nadmorskich klifach przed rundą w Geelong.',
    ),
    AmericasOceaniaRaceDefinition(
      raceId: AmericasOceaniaRaceId.tourColombia21,
      officialName: 'Tour Colombia 2.1',
      countryName: 'Colombia',
      countryIso: 'COL',
      region: AmericasOceaniaRegion.southAmerica,
      seasonWindow: SeasonWindowPhase.seasonOpener,
      uciCode: '2.1',
      uciCategory: RaceCategory.class1,
      isOneDayClassic: false,
      startMonth: 2,
      startDay: 6,
      ridersPerTeam: 6,
      prizePoolEur: 115000,
      uciPointsWinner: 125,
      climateHazard: AmericasOceaniaClimateHazard.andeanHighAltitudeHypoxia,
      logistics: AmericasOceaniaLogisticsProfile(
        flightHoursFromEurope: 11.5,
        timeZoneOffsetHours: -6,
        travelCostPerSquadEur: 49000,
        recommendedAcclimatizationDays: 8,
        startAltitudeMeters: 2480.0,
        peakAltitudeMeters: 2920.0,
        minTemperatureCelsius: 14.0,
        maxTemperatureCelsius: 24.0,
        maxCrosswindKmh: 20.0,
        recommendedMethod:
            AmericasOceaniaAcclimatizationMethod.hypobaricAltitudeCamp,
      ),
      stageTemplates: [
        AmericasOceaniaStageTemplate(
          stageNumber: 1,
          name: 'Paipa – Duitama',
          stageType: StageType.flat,
          distanceKm: 155.0,
          elevationGainM: 940.0,
          startElevationM: 2525.0,
          endElevationM: 2530.0,
          baseTemperatureCelsius: 21.0,
          weatherCondition: WeatherCondition.sunny,
          windSpeedKmh: 16.0,
          roadBearingDegrees: 45.0,
          windDirectionDegrees: 110.0,
          signatureFeature:
              AmericasOceaniaSignatureFeature.colombianAndesAltitudePass,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
        AmericasOceaniaStageTemplate(
          stageNumber: 2,
          name: 'Tunja – Santa Rosa de Viterbo',
          stageType: StageType.hilly,
          distanceKm: 168.0,
          elevationGainM: 2420.0,
          startElevationM: 2690.0,
          endElevationM: 2750.0,
          baseTemperatureCelsius: 19.5,
          weatherCondition: WeatherCondition.overcast,
          windSpeedKmh: 18.0,
          roadBearingDegrees: 30.0,
          windDirectionDegrees: 95.0,
          signatureFeature:
              AmericasOceaniaSignatureFeature.colombianAndesAltitudePass,
          finalSurfaceType: SegmentSurfaceType.roughAsphalt,
        ),
        AmericasOceaniaStageTemplate(
          stageNumber: 3,
          name: 'Zipaquirá – Alto del Vino',
          stageType: StageType.summitFinish,
          distanceKm: 172.0,
          elevationGainM: 3480.0,
          startElevationM: 2550.0,
          endElevationM: 2854.0,
          baseTemperatureCelsius: 16.0,
          weatherCondition: WeatherCondition.lightRain,
          windSpeedKmh: 22.0,
          roadBearingDegrees: 280.0,
          windDirectionDegrees: 190.0,
          signatureFeature:
              AmericasOceaniaSignatureFeature.colombianAndesAltitudePass,
          finalSurfaceType: SegmentSurfaceType.roughAsphalt,
        ),
      ],
      culturalSummary:
          'Święto kolumbijskiego kolarstwa w wysokich Andach (2500–2920 m n.p.m.) z fanatycznymi tłumami kibiców i finałem na przełęczy Alto del Vino.',
    ),
    AmericasOceaniaRaceDefinition(
      raceId: AmericasOceaniaRaceId.vueltaASanJuan,
      officialName: 'Vuelta a San Juan',
      countryName: 'Argentina',
      countryIso: 'ARG',
      region: AmericasOceaniaRegion.southAmerica,
      seasonWindow: SeasonWindowPhase.seasonOpener,
      uciCode: '2.Pro',
      uciCategory: RaceCategory.proSeries,
      isOneDayClassic: false,
      startMonth: 1,
      startDay: 24,
      ridersPerTeam: 6,
      prizePoolEur: 145000,
      uciPointsWinner: 200,
      climateHazard: AmericasOceaniaClimateHazard.andeanHighAltitudeHypoxia,
      logistics: AmericasOceaniaLogisticsProfile(
        flightHoursFromEurope: 14.5,
        timeZoneOffsetHours: -4,
        travelCostPerSquadEur: 54000,
        recommendedAcclimatizationDays: 8,
        startAltitudeMeters: 2500.0,
        peakAltitudeMeters: 3265.0,
        minTemperatureCelsius: 18.0,
        maxTemperatureCelsius: 36.0,
        maxCrosswindKmh: 34.0,
        recommendedMethod:
            AmericasOceaniaAcclimatizationMethod.hypobaricAltitudeCamp,
      ),
      stageTemplates: [
        AmericasOceaniaStageTemplate(
          stageNumber: 1,
          name: 'San Juan – Pocito',
          stageType: StageType.flat,
          distanceKm: 143.5,
          elevationGainM: 610.0,
          startElevationM: 640.0,
          endElevationM: 630.0,
          baseTemperatureCelsius: 35.0,
          weatherCondition: WeatherCondition.sunny,
          windSpeedKmh: 24.0,
          roadBearingDegrees: 180.0,
          windDirectionDegrees: 250.0,
          signatureFeature:
              AmericasOceaniaSignatureFeature.altoDelColorado3265mSummit,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
        AmericasOceaniaStageTemplate(
          stageNumber: 2,
          name: 'Circuito Villicum (ITT)',
          stageType: StageType.individualTimeTrial,
          distanceKm: 15.8,
          elevationGainM: 180.0,
          startElevationM: 710.0,
          endElevationM: 715.0,
          baseTemperatureCelsius: 34.0,
          weatherCondition: WeatherCondition.sunny,
          windSpeedKmh: 28.0,
          roadBearingDegrees: 90.0,
          windDirectionDegrees: 175.0,
          signatureFeature:
              AmericasOceaniaSignatureFeature.altoDelColorado3265mSummit,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
        AmericasOceaniaStageTemplate(
          stageNumber: 3,
          name: 'Iglesia – Alto del Colorado (3265 m)',
          stageType: StageType.summitFinish,
          distanceKm: 158.0,
          elevationGainM: 2850.0,
          startElevationM: 2500.0,
          endElevationM: 3265.0,
          baseTemperatureCelsius: 21.0,
          weatherCondition: WeatherCondition.sunny,
          windSpeedKmh: 33.0,
          roadBearingDegrees: 315.0,
          windDirectionDegrees: 230.0,
          signatureFeature:
              AmericasOceaniaSignatureFeature.altoDelColorado3265mSummit,
          finalSurfaceType: SegmentSurfaceType.roughAsphalt,
        ),
      ],
      culturalSummary:
          'Argentyńska perła początku sezonu, której królewski etap startuje na 2500 m i wspina się na morderczy szczyt Alto del Colorado (3265 m n.p.m.).',
    ),
    AmericasOceaniaRaceDefinition(
      raceId: AmericasOceaniaRaceId.gpCyclisteDeQuebec,
      officialName: 'Grand Prix Cycliste de Québec',
      countryName: 'Canada',
      countryIso: 'CAN',
      region: AmericasOceaniaRegion.northAmerica,
      seasonWindow: SeasonWindowPhase.seasonCloser,
      uciCode: '1.UWT',
      uciCategory: RaceCategory.worldTourOneDay,
      isOneDayClassic: true,
      startMonth: 9,
      startDay: 11,
      ridersPerTeam: 7,
      prizePoolEur: 185000,
      uciPointsWinner: 500,
      climateHazard:
          AmericasOceaniaClimateHazard.urbanPuncheurCircuitHumidity,
      logistics: AmericasOceaniaLogisticsProfile(
        flightHoursFromEurope: 7.5,
        timeZoneOffsetHours: -6,
        travelCostPerSquadEur: 44000,
        recommendedAcclimatizationDays: 4,
        startAltitudeMeters: 45.0,
        peakAltitudeMeters: 115.0,
        minTemperatureCelsius: 14.0,
        maxTemperatureCelsius: 22.0,
        maxCrosswindKmh: 24.0,
        recommendedMethod:
            AmericasOceaniaAcclimatizationMethod.puncheurVo2MaxSharpening,
      ),
      stageTemplates: [
        AmericasOceaniaStageTemplate(
          stageNumber: 1,
          name: 'Grande Allée – Côte de la Montagne (16 rund)',
          stageType: StageType.hilly,
          distanceKm: 201.6,
          elevationGainM: 2976.0,
          startElevationM: 92.0,
          endElevationM: 98.0,
          baseTemperatureCelsius: 18.5,
          weatherCondition: WeatherCondition.overcast,
          windSpeedKmh: 21.0,
          roadBearingDegrees: 65.0,
          windDirectionDegrees: 145.0,
          lapCount: 16,
          signatureFeature:
              AmericasOceaniaSignatureFeature.quebecCoteDeLaMontagneCircuit,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
      ],
      culturalSummary:
          'Północnoamerykański klasyk WorldTour zamykający sezon: 16 morderczych rund miejskich dla Puncheurów z krótką, stromą ścianą Côte de la Montagne.',
    ),
    AmericasOceaniaRaceDefinition(
      raceId: AmericasOceaniaRaceId.gpCyclisteDeMontreal,
      officialName: 'Grand Prix Cycliste de Montréal',
      countryName: 'Canada',
      countryIso: 'CAN',
      region: AmericasOceaniaRegion.northAmerica,
      seasonWindow: SeasonWindowPhase.seasonCloser,
      uciCode: '1.UWT',
      uciCategory: RaceCategory.worldTourOneDay,
      isOneDayClassic: true,
      startMonth: 9,
      startDay: 13,
      ridersPerTeam: 7,
      prizePoolEur: 185000,
      uciPointsWinner: 500,
      climateHazard:
          AmericasOceaniaClimateHazard.urbanPuncheurCircuitHumidity,
      logistics: AmericasOceaniaLogisticsProfile(
        flightHoursFromEurope: 7.5,
        timeZoneOffsetHours: -6,
        travelCostPerSquadEur: 44000,
        recommendedAcclimatizationDays: 4,
        startAltitudeMeters: 62.0,
        peakAltitudeMeters: 211.0,
        minTemperatureCelsius: 14.0,
        maxTemperatureCelsius: 23.0,
        maxCrosswindKmh: 22.0,
        recommendedMethod:
            AmericasOceaniaAcclimatizationMethod.puncheurVo2MaxSharpening,
      ),
      stageTemplates: [
        AmericasOceaniaStageTemplate(
          stageNumber: 1,
          name: 'Avenue du Parc – Voie Camillien-Houde (17 rund)',
          stageType: StageType.highMountain,
          distanceKm: 209.1,
          elevationGainM: 4573.0,
          startElevationM: 62.0,
          endElevationM: 74.0,
          baseTemperatureCelsius: 19.0,
          weatherCondition: WeatherCondition.sunny,
          windSpeedKmh: 18.0,
          roadBearingDegrees: 320.0,
          windDirectionDegrees: 245.0,
          lapCount: 17,
          signatureFeature:
              AmericasOceaniaSignatureFeature.montrealCamillienHoudeCircuit,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
      ],
      culturalSummary:
          'Drugi z kanadyjskich klasyków zamykających sezon — 17 rund wokół wzgórza Mont-Royal i podjazdu Voie Camillien-Houde generuje ponad 4500 m przewyższenia.',
    ),
  ];
}
