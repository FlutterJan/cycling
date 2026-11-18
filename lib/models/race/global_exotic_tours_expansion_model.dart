import 'dart:math' as math;

import 'race_stage.dart';
import 'stage_segment.dart';
import 'tour_race.dart';

/// Identyfikator pozaeuropejskiego wyścigu w programie globalnej ekspansji UCI.
enum ExoticTourId {
  tourDuRwanda,
  tourDeLangkawi,
  tourOfOman,
  alUlaTour;

  String toJson() => name;

  static ExoticTourId fromJson(String value) {
    return ExoticTourId.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ExoticTourId.tourDuRwanda,
    );
  }
}

/// Region geograficzny nowego rynku pozaeuropejskiego UCI.
enum ExoticMarketRegion {
  eastAfrica,
  southeastAsia,
  arabianPeninsula;

  String toJson() => name;

  static ExoticMarketRegion fromJson(String value) {
    return ExoticMarketRegion.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ExoticMarketRegion.eastAfrica,
    );
  }
}

/// Główne wyzwanie klimatyczno-terenowe danego wyścigu pozaeuropejskiego.
enum ExoticClimateChallenge {
  highAltitudeAndTropicalRain,
  tropicalHeatAndMonsoonHumidity,
  desertHeatAndCoastalCrosswinds,
  aridDesertAndSandstorms;

  String toJson() => name;

  static ExoticClimateChallenge fromJson(String value) {
    return ExoticClimateChallenge.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ExoticClimateChallenge.highAltitudeAndTropicalRain,
    );
  }
}

/// Poziom statusu wyścigu w globalnym kalendarzu UCI.
enum ExoticExpansionTier {
  emergingMarket21,
  establishedProSeries,
  worldTourCandidate,
  promotedWorldTour;

  String toJson() => name;

  static ExoticExpansionTier fromJson(String value) {
    return ExoticExpansionTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ExoticExpansionTier.emergingMarket21,
    );
  }
}

/// Protokół aklimatyzacji zespołu przed startem w wyścigu pozaeuropejskim.
enum AcclimatizationProtocolType {
  none,
  altitudeCamp,
  heatChamberAndHydration,
  combinedJetLagAndHeat;

  String toJson() => name;

  static AcclimatizationProtocolType fromJson(String value) {
    return AcclimatizationProtocolType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AcclimatizationProtocolType.none,
    );
  }
}

/// Charakterystyczna cecha trasy rozpoznawalna dla danego wyścigu.
enum ExoticStageSignatureFeature {
  kigaliCobblesWall,
  gentingHighlandsHc,
  greenMountainSummit,
  harratUwayridSteepRamp,
  crosswindDesertEchelon,
  tropicalMonsoonCircuit;

  String toJson() => name;

  static ExoticStageSignatureFeature fromJson(String value) {
    return ExoticStageSignatureFeature.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ExoticStageSignatureFeature.kigaliCobblesWall,
    );
  }
}

/// Profil logistyki podróży, wysokości i aklimatyzacji dla wyścigu pozaeuropejskiego.
class ExoticLogisticsAndAcclimatizationProfile {
  final double flightHoursFromEurope;
  final int timeZoneOffsetHours;
  final int travelCostPerSquadEur;
  final int recommendedAcclimatizationDays;
  final double baseAltitudeMeters;
  final double peakAltitudeMeters;
  final double avgTemperatureCelsius;
  final double avgHumidityPercent;
  final AcclimatizationProtocolType recommendedProtocol;

  const ExoticLogisticsAndAcclimatizationProfile({
    required this.flightHoursFromEurope,
    required this.timeZoneOffsetHours,
    required this.travelCostPerSquadEur,
    required this.recommendedAcclimatizationDays,
    required this.baseAltitudeMeters,
    required this.peakAltitudeMeters,
    required this.avgTemperatureCelsius,
    required this.avgHumidityPercent,
    required this.recommendedProtocol,
  });

  /// Oblicza wskaźnik gotowości aklimatyzacyjnej zespołu (0.0 – 1.0).
  double computeAcclimatizationReadinessScore({
    required int daysOnSite,
    required AcclimatizationProtocolType protocol,
  }) {
    final safeDays = daysOnSite < 0 ? 0 : daysOnSite;
    final targetDays = math.max(1, recommendedAcclimatizationDays);
    final daysRatio = (safeDays / targetDays).clamp(0.0, 1.0);

    double protocolBonus = 0.0;
    if (protocol == recommendedProtocol) {
      protocolBonus = 0.25;
    } else if (protocol != AcclimatizationProtocolType.none) {
      protocolBonus = 0.12;
    }

    return (daysRatio * 0.75 + protocolBonus).clamp(0.0, 1.0);
  }

  /// Wylicza efektywną karę wydolnościową (%) przy niedostatecznej aklimatyzacji.
  double computeEffectivePerformancePenaltyPercent({
    required int daysOnSite,
    required AcclimatizationProtocolType protocol,
  }) {
    final readiness = computeAcclimatizationReadinessScore(
      daysOnSite: daysOnSite,
      protocol: protocol,
    );
    final altitudeFactor = peakAltitudeMeters > 1800 ? 4.5 : 1.5;
    final heatFactor = avgTemperatureCelsius >= 32.0 ? 4.0 : 1.5;
    final jetLagFactor = timeZoneOffsetHours.abs() >= 4 ? 3.0 : 1.0;
    final maxPenalty = altitudeFactor + heatFactor + jetLagFactor;
    return ((1.0 - readiness) * maxPenalty).clamp(0.0, 15.0);
  }

  ExoticLogisticsAndAcclimatizationProfile copyWith({
    double? flightHoursFromEurope,
    int? timeZoneOffsetHours,
    int? travelCostPerSquadEur,
    int? recommendedAcclimatizationDays,
    double? baseAltitudeMeters,
    double? peakAltitudeMeters,
    double? avgTemperatureCelsius,
    double? avgHumidityPercent,
    AcclimatizationProtocolType? recommendedProtocol,
  }) {
    return ExoticLogisticsAndAcclimatizationProfile(
      flightHoursFromEurope:
          flightHoursFromEurope ?? this.flightHoursFromEurope,
      timeZoneOffsetHours: timeZoneOffsetHours ?? this.timeZoneOffsetHours,
      travelCostPerSquadEur:
          travelCostPerSquadEur ?? this.travelCostPerSquadEur,
      recommendedAcclimatizationDays:
          recommendedAcclimatizationDays ?? this.recommendedAcclimatizationDays,
      baseAltitudeMeters: baseAltitudeMeters ?? this.baseAltitudeMeters,
      peakAltitudeMeters: peakAltitudeMeters ?? this.peakAltitudeMeters,
      avgTemperatureCelsius:
          avgTemperatureCelsius ?? this.avgTemperatureCelsius,
      avgHumidityPercent: avgHumidityPercent ?? this.avgHumidityPercent,
      recommendedProtocol: recommendedProtocol ?? this.recommendedProtocol,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flightHoursFromEurope': flightHoursFromEurope,
      'timeZoneOffsetHours': timeZoneOffsetHours,
      'travelCostPerSquadEur': travelCostPerSquadEur,
      'recommendedAcclimatizationDays': recommendedAcclimatizationDays,
      'baseAltitudeMeters': baseAltitudeMeters,
      'peakAltitudeMeters': peakAltitudeMeters,
      'avgTemperatureCelsius': avgTemperatureCelsius,
      'avgHumidityPercent': avgHumidityPercent,
      'recommendedProtocol': recommendedProtocol.toJson(),
    };
  }

  factory ExoticLogisticsAndAcclimatizationProfile.fromJson(
    Map<String, dynamic> json,
  ) {
    return ExoticLogisticsAndAcclimatizationProfile(
      flightHoursFromEurope:
          (json['flightHoursFromEurope'] as num?)?.toDouble() ?? 6.0,
      timeZoneOffsetHours: (json['timeZoneOffsetHours'] as num?)?.toInt() ?? 1,
      travelCostPerSquadEur:
          (json['travelCostPerSquadEur'] as num?)?.toInt() ?? 35000,
      recommendedAcclimatizationDays:
          (json['recommendedAcclimatizationDays'] as num?)?.toInt() ?? 4,
      baseAltitudeMeters:
          (json['baseAltitudeMeters'] as num?)?.toDouble() ?? 100.0,
      peakAltitudeMeters:
          (json['peakAltitudeMeters'] as num?)?.toDouble() ?? 1200.0,
      avgTemperatureCelsius:
          (json['avgTemperatureCelsius'] as num?)?.toDouble() ?? 28.0,
      avgHumidityPercent:
          (json['avgHumidityPercent'] as num?)?.toDouble() ?? 50.0,
      recommendedProtocol: AcclimatizationProtocolType.fromJson(
        json['recommendedProtocol'] as String? ?? 'none',
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExoticLogisticsAndAcclimatizationProfile &&
        other.flightHoursFromEurope == flightHoursFromEurope &&
        other.timeZoneOffsetHours == timeZoneOffsetHours &&
        other.travelCostPerSquadEur == travelCostPerSquadEur &&
        other.recommendedAcclimatizationDays ==
            recommendedAcclimatizationDays &&
        other.baseAltitudeMeters == baseAltitudeMeters &&
        other.peakAltitudeMeters == peakAltitudeMeters &&
        other.avgTemperatureCelsius == avgTemperatureCelsius &&
        other.avgHumidityPercent == avgHumidityPercent &&
        other.recommendedProtocol == recommendedProtocol;
  }

  @override
  int get hashCode => Object.hash(
        flightHoursFromEurope,
        timeZoneOffsetHours,
        travelCostPerSquadEur,
        recommendedAcclimatizationDays,
        baseAltitudeMeters,
        peakAltitudeMeters,
        avgTemperatureCelsius,
        avgHumidityPercent,
        recommendedProtocol,
      );
}

/// Wpływ komercyjny, punktowy i skautingowy udziału w wyścigu pozaeuropejskim.
class ExoticCommercialAndPrestigeImpact {
  final double sponsorExposureMultiplier;
  final int emergingMarketFanGrowth;
  final int uciPointsWinner;
  final int appearanceFeeEur;
  final double broadcastReachMillions;
  final double localTalentScoutingBonus;

  const ExoticCommercialAndPrestigeImpact({
    required this.sponsorExposureMultiplier,
    required this.emergingMarketFanGrowth,
    required this.uciPointsWinner,
    required this.appearanceFeeEur,
    required this.broadcastReachMillions,
    required this.localTalentScoutingBonus,
  });

  ExoticCommercialAndPrestigeImpact copyWith({
    double? sponsorExposureMultiplier,
    int? emergingMarketFanGrowth,
    int? uciPointsWinner,
    int? appearanceFeeEur,
    double? broadcastReachMillions,
    double? localTalentScoutingBonus,
  }) {
    return ExoticCommercialAndPrestigeImpact(
      sponsorExposureMultiplier:
          sponsorExposureMultiplier ?? this.sponsorExposureMultiplier,
      emergingMarketFanGrowth:
          emergingMarketFanGrowth ?? this.emergingMarketFanGrowth,
      uciPointsWinner: uciPointsWinner ?? this.uciPointsWinner,
      appearanceFeeEur: appearanceFeeEur ?? this.appearanceFeeEur,
      broadcastReachMillions:
          broadcastReachMillions ?? this.broadcastReachMillions,
      localTalentScoutingBonus:
          localTalentScoutingBonus ?? this.localTalentScoutingBonus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sponsorExposureMultiplier': sponsorExposureMultiplier,
      'emergingMarketFanGrowth': emergingMarketFanGrowth,
      'uciPointsWinner': uciPointsWinner,
      'appearanceFeeEur': appearanceFeeEur,
      'broadcastReachMillions': broadcastReachMillions,
      'localTalentScoutingBonus': localTalentScoutingBonus,
    };
  }

  factory ExoticCommercialAndPrestigeImpact.fromJson(
    Map<String, dynamic> json,
  ) {
    return ExoticCommercialAndPrestigeImpact(
      sponsorExposureMultiplier:
          (json['sponsorExposureMultiplier'] as num?)?.toDouble() ?? 1.15,
      emergingMarketFanGrowth:
          (json['emergingMarketFanGrowth'] as num?)?.toInt() ?? 15000,
      uciPointsWinner: (json['uciPointsWinner'] as num?)?.toInt() ?? 125,
      appearanceFeeEur: (json['appearanceFeeEur'] as num?)?.toInt() ?? 45000,
      broadcastReachMillions:
          (json['broadcastReachMillions'] as num?)?.toDouble() ?? 18.0,
      localTalentScoutingBonus:
          (json['localTalentScoutingBonus'] as num?)?.toDouble() ?? 0.25,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExoticCommercialAndPrestigeImpact &&
        other.sponsorExposureMultiplier == sponsorExposureMultiplier &&
        other.emergingMarketFanGrowth == emergingMarketFanGrowth &&
        other.uciPointsWinner == uciPointsWinner &&
        other.appearanceFeeEur == appearanceFeeEur &&
        other.broadcastReachMillions == broadcastReachMillions &&
        other.localTalentScoutingBonus == localTalentScoutingBonus;
  }

  @override
  int get hashCode => Object.hash(
        sponsorExposureMultiplier,
        emergingMarketFanGrowth,
        uciPointsWinner,
        appearanceFeeEur,
        broadcastReachMillions,
        localTalentScoutingBonus,
      );
}

/// Szablon etapu wyścigu pozaeuropejskiego z możliwością konwersji do `RaceStage`.
class ExoticTourStageTemplate {
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
  final ExoticStageSignatureFeature signatureFeature;
  final SegmentSurfaceType finalSurfaceType;

  const ExoticTourStageTemplate({
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
    required this.signatureFeature,
    required this.finalSurfaceType,
  });

  /// Konwertuje szablon na pełny obiekt `RaceStage` z segmentami trasy.
  RaceStage toRaceStage({required String raceId}) {
    final safeDistance = math.max(5.0, distanceKm);
    final approachKm = double.parse((safeDistance * 0.55).toStringAsFixed(1));
    final climbKm = double.parse((safeDistance * 0.30).toStringAsFixed(1));
    final finishKm = double.parse(
      math.max(1.0, safeDistance - approachKm - climbKm).toStringAsFixed(1),
    );
    final midElevation = startElevationM + (elevationGainM * 0.45);
    final peakElevation = math.max(endElevationM, startElevationM + elevationGainM);

    final segments = <StageSegment>[
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: approachKm,
        startElevationM: startElevationM,
        endElevationM: midElevation,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 28.0,
        windDirectionDegrees: 95.0,
        roadBearingDegrees: 180.0,
        sprintOrKomClassification: SegmentClassification.intermediateSprint,
      ),
      StageSegment(
        index: 1,
        startKm: approachKm,
        lengthKm: climbKm,
        startElevationM: midElevation,
        endElevationM: peakElevation,
        surfaceType: finalSurfaceType,
        technicalDifficulty: stageType == StageType.summitFinish ? 68.0 : 42.0,
        windDirectionDegrees: 110.0,
        roadBearingDegrees: 195.0,
        sprintOrKomClassification: stageType == StageType.summitFinish ||
                stageType == StageType.highMountain
            ? SegmentClassification.cat1
            : SegmentClassification.cat3,
      ),
      StageSegment(
        index: 2,
        startKm: approachKm + climbKm,
        lengthKm: finishKm,
        startElevationM: peakElevation,
        endElevationM: endElevationM,
        surfaceType: finalSurfaceType,
        technicalDifficulty: 55.0,
        windDirectionDegrees: 120.0,
        roadBearingDegrees: 210.0,
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

  ExoticTourStageTemplate copyWith({
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
    ExoticStageSignatureFeature? signatureFeature,
    SegmentSurfaceType? finalSurfaceType,
  }) {
    return ExoticTourStageTemplate(
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
      'signatureFeature': signatureFeature.toJson(),
      'finalSurfaceType': finalSurfaceType.toJson(),
    };
  }

  factory ExoticTourStageTemplate.fromJson(Map<String, dynamic> json) {
    return ExoticTourStageTemplate(
      stageNumber: (json['stageNumber'] as num?)?.toInt() ?? 1,
      name: json['name'] as String? ?? 'Etap',
      stageType: StageType.fromJson(json['stageType'] as String? ?? 'flat'),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 140.0,
      elevationGainM: (json['elevationGainM'] as num?)?.toDouble() ?? 1200.0,
      startElevationM: (json['startElevationM'] as num?)?.toDouble() ?? 100.0,
      endElevationM: (json['endElevationM'] as num?)?.toDouble() ?? 150.0,
      baseTemperatureCelsius:
          (json['baseTemperatureCelsius'] as num?)?.toDouble() ?? 26.0,
      weatherCondition: WeatherCondition.fromJson(
        json['weatherCondition'] as String? ?? 'sunny',
      ),
      windSpeedKmh: (json['windSpeedKmh'] as num?)?.toDouble() ?? 15.0,
      signatureFeature: ExoticStageSignatureFeature.fromJson(
        json['signatureFeature'] as String? ?? 'kigaliCobblesWall',
      ),
      finalSurfaceType: SegmentSurfaceType.fromJson(
        json['finalSurfaceType'] as String? ?? 'smoothAsphalt',
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExoticTourStageTemplate &&
        other.stageNumber == stageNumber &&
        other.name == name &&
        other.stageType == stageType &&
        other.distanceKm == distanceKm;
  }

  @override
  int get hashCode => Object.hash(stageNumber, name, stageType, distanceKm);
}

/// Pełna definicja wyścigu pozaeuropejskiego w kalendarzu UCI.
class ExoticTourDefinition {
  final ExoticTourId tourId;
  final String officialName;
  final String countryName;
  final String countryIso;
  final ExoticMarketRegion region;
  final String uciCode;
  final RaceCategory uciCategory;
  final ExoticExpansionTier expansionTier;
  final int startMonth;
  final int startDay;
  final int ridersPerTeam;
  final int prizePoolEur;
  final ExoticClimateChallenge climateChallenge;
  final ExoticLogisticsAndAcclimatizationProfile logistics;
  final ExoticCommercialAndPrestigeImpact commercialImpact;
  final List<ExoticTourStageTemplate> stageTemplates;
  final String culturalSummary;

  const ExoticTourDefinition({
    required this.tourId,
    required this.officialName,
    required this.countryName,
    required this.countryIso,
    required this.region,
    required this.uciCode,
    required this.uciCategory,
    required this.expansionTier,
    required this.startMonth,
    required this.startDay,
    required this.ridersPerTeam,
    required this.prizePoolEur,
    required this.climateChallenge,
    required this.logistics,
    required this.commercialImpact,
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

  int get stageCount => stageTemplates.length;

  /// Konwertuje definicję wyścigu na pełny obiekt `TourRace` do kalendarza sezonu.
  TourRace toTourRace({List<String> participatingTeamIds = const []}) {
    final raceId = 'exotic_${tourId.name}';
    final stages = stageTemplates
        .map((template) => template.toRaceStage(raceId: raceId))
        .toList(growable: false);

    return TourRace(
      id: raceId,
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

  ExoticTourDefinition copyWith({
    ExoticTourId? tourId,
    String? officialName,
    String? countryName,
    String? countryIso,
    ExoticMarketRegion? region,
    String? uciCode,
    RaceCategory? uciCategory,
    ExoticExpansionTier? expansionTier,
    int? startMonth,
    int? startDay,
    int? ridersPerTeam,
    int? prizePoolEur,
    ExoticClimateChallenge? climateChallenge,
    ExoticLogisticsAndAcclimatizationProfile? logistics,
    ExoticCommercialAndPrestigeImpact? commercialImpact,
    List<ExoticTourStageTemplate>? stageTemplates,
    String? culturalSummary,
  }) {
    return ExoticTourDefinition(
      tourId: tourId ?? this.tourId,
      officialName: officialName ?? this.officialName,
      countryName: countryName ?? this.countryName,
      countryIso: countryIso ?? this.countryIso,
      region: region ?? this.region,
      uciCode: uciCode ?? this.uciCode,
      uciCategory: uciCategory ?? this.uciCategory,
      expansionTier: expansionTier ?? this.expansionTier,
      startMonth: startMonth ?? this.startMonth,
      startDay: startDay ?? this.startDay,
      ridersPerTeam: ridersPerTeam ?? this.ridersPerTeam,
      prizePoolEur: prizePoolEur ?? this.prizePoolEur,
      climateChallenge: climateChallenge ?? this.climateChallenge,
      logistics: logistics ?? this.logistics,
      commercialImpact: commercialImpact ?? this.commercialImpact,
      stageTemplates: stageTemplates != null
          ? List<ExoticTourStageTemplate>.unmodifiable(stageTemplates)
          : this.stageTemplates,
      culturalSummary: culturalSummary ?? this.culturalSummary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tourId': tourId.toJson(),
      'officialName': officialName,
      'countryName': countryName,
      'countryIso': countryIso,
      'region': region.toJson(),
      'uciCode': uciCode,
      'uciCategory': uciCategory.toJson(),
      'expansionTier': expansionTier.toJson(),
      'startMonth': startMonth,
      'startDay': startDay,
      'ridersPerTeam': ridersPerTeam,
      'prizePoolEur': prizePoolEur,
      'climateChallenge': climateChallenge.toJson(),
      'logistics': logistics.toJson(),
      'commercialImpact': commercialImpact.toJson(),
      'stageTemplates': stageTemplates.map((e) => e.toJson()).toList(),
      'culturalSummary': culturalSummary,
    };
  }

  factory ExoticTourDefinition.fromJson(Map<String, dynamic> json) {
    return ExoticTourDefinition(
      tourId: ExoticTourId.fromJson(json['tourId'] as String? ?? 'tourDuRwanda'),
      officialName: json['officialName'] as String? ?? 'Exotic Tour',
      countryName: json['countryName'] as String? ?? 'Unknown',
      countryIso: json['countryIso'] as String? ?? 'UCI',
      region: ExoticMarketRegion.fromJson(
        json['region'] as String? ?? 'eastAfrica',
      ),
      uciCode: json['uciCode'] as String? ?? '2.1',
      uciCategory: RaceCategory.fromJson(
        json['uciCategory'] as String? ?? 'class1',
      ),
      expansionTier: ExoticExpansionTier.fromJson(
        json['expansionTier'] as String? ?? 'emergingMarket21',
      ),
      startMonth: (json['startMonth'] as num?)?.toInt() ?? 2,
      startDay: (json['startDay'] as num?)?.toInt() ?? 1,
      ridersPerTeam: (json['ridersPerTeam'] as num?)?.toInt() ?? 6,
      prizePoolEur: (json['prizePoolEur'] as num?)?.toInt() ?? 100000,
      climateChallenge: ExoticClimateChallenge.fromJson(
        json['climateChallenge'] as String? ?? 'highAltitudeAndTropicalRain',
      ),
      logistics: ExoticLogisticsAndAcclimatizationProfile.fromJson(
        json['logistics'] as Map<String, dynamic>? ?? const {},
      ),
      commercialImpact: ExoticCommercialAndPrestigeImpact.fromJson(
        json['commercialImpact'] as Map<String, dynamic>? ?? const {},
      ),
      stageTemplates: (json['stageTemplates'] as List<dynamic>? ?? const [])
          .map(
            (e) => ExoticTourStageTemplate.fromJson(
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
    return other is ExoticTourDefinition &&
        other.tourId == tourId &&
        other.uciCode == uciCode &&
        other.expansionTier == expansionTier;
  }

  @override
  int get hashCode => Object.hash(tourId, uciCode, expansionTier);
}

/// Zapis historycznego udziału drużyny gracza w wyścigu pozaeuropejskim.
class TeamExoticTourParticipationRecord {
  final ExoticTourId tourId;
  final int seasonYear;
  final int daysAcclimatized;
  final AcclimatizationProtocolType protocol;
  final int? bestGcRank;
  final int stageWins;
  final int uciPointsEarned;
  final int netFinancialBalanceEur;
  final int fansGained;

  const TeamExoticTourParticipationRecord({
    required this.tourId,
    required this.seasonYear,
    required this.daysAcclimatized,
    required this.protocol,
    this.bestGcRank,
    required this.stageWins,
    required this.uciPointsEarned,
    required this.netFinancialBalanceEur,
    required this.fansGained,
  });

  Map<String, dynamic> toJson() {
    return {
      'tourId': tourId.toJson(),
      'seasonYear': seasonYear,
      'daysAcclimatized': daysAcclimatized,
      'protocol': protocol.toJson(),
      'bestGcRank': bestGcRank,
      'stageWins': stageWins,
      'uciPointsEarned': uciPointsEarned,
      'netFinancialBalanceEur': netFinancialBalanceEur,
      'fansGained': fansGained,
    };
  }

  factory TeamExoticTourParticipationRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    return TeamExoticTourParticipationRecord(
      tourId: ExoticTourId.fromJson(json['tourId'] as String? ?? 'tourDuRwanda'),
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      daysAcclimatized: (json['daysAcclimatized'] as num?)?.toInt() ?? 0,
      protocol: AcclimatizationProtocolType.fromJson(
        json['protocol'] as String? ?? 'none',
      ),
      bestGcRank: (json['bestGcRank'] as num?)?.toInt(),
      stageWins: (json['stageWins'] as num?)?.toInt() ?? 0,
      uciPointsEarned: (json['uciPointsEarned'] as num?)?.toInt() ?? 0,
      netFinancialBalanceEur:
          (json['netFinancialBalanceEur'] as num?)?.toInt() ?? 0,
      fansGained: (json['fansGained'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamExoticTourParticipationRecord &&
        other.tourId == tourId &&
        other.seasonYear == seasonYear &&
        other.bestGcRank == bestGcRank &&
        other.stageWins == stageWins;
  }

  @override
  int get hashCode => Object.hash(tourId, seasonYear, bestGcRank, stageWins);
}

/// Raport oceny opłacalności i przygotowania zespołu do wyjazdu na wyścig pozaeuropejski.
class ExoticExpansionEvaluationReport {
  final ExoticTourId tourId;
  final double readinessScore;
  final double performancePenaltyPercent;
  final int projectedNetFinancialEur;
  final int projectedUciPoints;
  final int projectedFanGrowth;
  final bool isFinanciallyViable;
  final String recommendationSummary;

  const ExoticExpansionEvaluationReport({
    required this.tourId,
    required this.readinessScore,
    required this.performancePenaltyPercent,
    required this.projectedNetFinancialEur,
    required this.projectedUciPoints,
    required this.projectedFanGrowth,
    required this.isFinanciallyViable,
    required this.recommendationSummary,
  });
}

/// Model globalnej ekspansji kalendarza UCI na rynki pozaeuropejskie
/// (*Tour du Rwanda*, *Tour de Langkawi*, *Tour of Oman*, *AlUla Tour*).
class GlobalExoticToursExpansionModel {
  final int seasonYear;
  final List<ExoticTourDefinition> tours;
  final List<ExoticTourId> promotedTourIds;
  final List<TeamExoticTourParticipationRecord> participationHistory;
  final double globalExpansionReputation;
  final int nonEuropeanFanBase;

  const GlobalExoticToursExpansionModel({
    required this.seasonYear,
    required this.tours,
    required this.promotedTourIds,
    required this.participationHistory,
    required this.globalExpansionReputation,
    required this.nonEuropeanFanBase,
  });

  /// Tworzy domyślny stan globalnej ekspansji z 4 flagowymi wyścigami pozaeuropejskimi.
  factory GlobalExoticToursExpansionModel.initial({int seasonYear = 2026}) {
    return GlobalExoticToursExpansionModel(
      seasonYear: seasonYear,
      tours: List<ExoticTourDefinition>.unmodifiable(_defaultExoticTours()),
      promotedTourIds: const [],
      participationHistory: const [],
      globalExpansionReputation: 25.0,
      nonEuropeanFanBase: 12000,
    );
  }

  /// Wyszukuje definicję wyścigu po jego identyfikatorze.
  ExoticTourDefinition? tourById(ExoticTourId id) {
    for (final tour in tours) {
      if (tour.tourId == id) return tour;
    }
    return null;
  }

  /// Zwraca wyścigi z danego regionu pozaeuropejskiego.
  List<ExoticTourDefinition> toursByRegion(ExoticMarketRegion region) {
    return tours
        .where((tour) => tour.region == region)
        .toList(growable: false);
  }

  /// Zwraca wyścigi zaplanowane na wskazany miesiąc kalendarzowy (1–12).
  List<ExoticTourDefinition> toursForMonth(int month) {
    return tours
        .where((tour) => tour.startMonth == month)
        .toList(growable: false);
  }

  /// Ocenia przygotowanie aklimatyzacyjne oraz prognozowany bilans finansowy i punktowy.
  ExoticExpansionEvaluationReport evaluateTourParticipation({
    required ExoticTourId tourId,
    required int daysAcclimatized,
    required AcclimatizationProtocolType protocol,
    int expectedGcFinishRank = 5,
  }) {
    final tour = tourById(tourId);
    if (tour == null) {
      return ExoticExpansionEvaluationReport(
        tourId: tourId,
        readinessScore: 0.0,
        performancePenaltyPercent: 15.0,
        projectedNetFinancialEur: 0,
        projectedUciPoints: 0,
        projectedFanGrowth: 0,
        isFinanciallyViable: false,
        recommendationSummary: 'Wyścig nie znajduje się w aktywnym kalendarzu ekspansji.',
      );
    }

    final readiness = tour.logistics.computeAcclimatizationReadinessScore(
      daysOnSite: daysAcclimatized,
      protocol: protocol,
    );
    final penalty = tour.logistics.computeEffectivePerformancePenaltyPercent(
      daysOnSite: daysAcclimatized,
      protocol: protocol,
    );

    final safeRank = expectedGcFinishRank.clamp(1, 30);
    final prizeShare = safeRank == 1
        ? 0.25
        : safeRank <= 3
            ? 0.14
            : safeRank <= 10
                ? 0.06
                : 0.02;
    final protocolCost = protocol == AcclimatizationProtocolType.none
        ? 0
        : protocol == AcclimatizationProtocolType.combinedJetLagAndHeat
            ? 14000
            : 8500;

    final grossIncome = tour.commercialImpact.appearanceFeeEur +
        (tour.prizePoolEur * prizeShare).round();
    final totalCost = tour.logistics.travelCostPerSquadEur + protocolCost;
    final netFinancial = grossIncome - totalCost;

    final rankPointsFactor = (1.0 - ((safeRank - 1) / 25.0)).clamp(0.15, 1.0);
    final projectedPoints =
        (tour.commercialImpact.uciPointsWinner * rankPointsFactor).round();
    final projectedFans =
        (tour.commercialImpact.emergingMarketFanGrowth * readiness).round();

    final viable = netFinancial >= -15000 && readiness >= 0.45;
    final summary = readiness >= 0.80
        ? 'Optymalna aklimatyzacja do ${tour.officialName}; pełna gotowość na ${tour.countryName}.'
        : 'Zalecane ${tour.logistics.recommendedAcclimatizationDays} dni aklimatyzacji i protokół ${tour.logistics.recommendedProtocol.name}.';

    return ExoticExpansionEvaluationReport(
      tourId: tourId,
      readinessScore: readiness,
      performancePenaltyPercent: penalty,
      projectedNetFinancialEur: netFinancial,
      projectedUciPoints: projectedPoints,
      projectedFanGrowth: projectedFans,
      isFinanciallyViable: viable,
      recommendationSummary: summary,
    );
  }

  /// Awansuje wyścig pozaeuropejski na wyższy poziom prestiżu w kalendarzu UCI.
  GlobalExoticToursExpansionModel promoteTourTier(ExoticTourId tourId) {
    final updatedTours = tours.map((tour) {
      if (tour.tourId != tourId) return tour;

      final nextTier = switch (tour.expansionTier) {
        ExoticExpansionTier.emergingMarket21 =>
          ExoticExpansionTier.establishedProSeries,
        ExoticExpansionTier.establishedProSeries =>
          ExoticExpansionTier.worldTourCandidate,
        ExoticExpansionTier.worldTourCandidate =>
          ExoticExpansionTier.promotedWorldTour,
        ExoticExpansionTier.promotedWorldTour =>
          ExoticExpansionTier.promotedWorldTour,
      };

      if (nextTier == tour.expansionTier) return tour;

      final nextCategory = nextTier == ExoticExpansionTier.promotedWorldTour
          ? RaceCategory.worldTourStageRace
          : RaceCategory.proSeries;
      final nextUciCode =
          nextTier == ExoticExpansionTier.promotedWorldTour ? '2.UWT' : '2.Pro';

      return tour.copyWith(
        expansionTier: nextTier,
        uciCategory: nextCategory,
        uciCode: nextUciCode,
        prizePoolEur: (tour.prizePoolEur * 1.45).round(),
        commercialImpact: tour.commercialImpact.copyWith(
          uciPointsWinner: (tour.commercialImpact.uciPointsWinner * 1.5).round(),
          appearanceFeeEur:
              (tour.commercialImpact.appearanceFeeEur * 1.35).round(),
          sponsorExposureMultiplier: double.parse(
            (tour.commercialImpact.sponsorExposureMultiplier + 0.15)
                .toStringAsFixed(2),
          ),
        ),
      );
    }).toList(growable: false);

    final updatedPromoted = promotedTourIds.contains(tourId)
        ? promotedTourIds
        : <ExoticTourId>[...promotedTourIds, tourId];

    return copyWith(
      tours: updatedTours,
      promotedTourIds: List<ExoticTourId>.unmodifiable(updatedPromoted),
      globalExpansionReputation:
          (globalExpansionReputation + 8.0).clamp(0.0, 100.0),
    );
  }

  /// Rejestruje ukończony udział drużyny i aktualizuje reputację oraz bazę fanów.
  GlobalExoticToursExpansionModel recordParticipation(
    TeamExoticTourParticipationRecord record,
  ) {
    final updatedHistory = <TeamExoticTourParticipationRecord>[
      ...participationHistory,
      record,
    ];
    final repGain = 3.5 +
        (record.stageWins * 1.5) +
        (record.bestGcRank != null && record.bestGcRank! <= 3 ? 4.0 : 1.0);

    return copyWith(
      participationHistory:
          List<TeamExoticTourParticipationRecord>.unmodifiable(updatedHistory),
      globalExpansionReputation:
          (globalExpansionReputation + repGain).clamp(0.0, 100.0),
      nonEuropeanFanBase: nonEuropeanFanBase + math.max(0, record.fansGained),
    );
  }

  /// Generuje pełną listę obiektów `TourRace` gotowych do wpięcia w `SeasonCalendar`.
  List<TourRace> buildCalendarTourRaces({
    List<String> participatingTeamIds = const [],
  }) {
    return tours
        .map(
          (tour) => tour.toTourRace(participatingTeamIds: participatingTeamIds),
        )
        .toList(growable: false);
  }

  GlobalExoticToursExpansionModel copyWith({
    int? seasonYear,
    List<ExoticTourDefinition>? tours,
    List<ExoticTourId>? promotedTourIds,
    List<TeamExoticTourParticipationRecord>? participationHistory,
    double? globalExpansionReputation,
    int? nonEuropeanFanBase,
  }) {
    return GlobalExoticToursExpansionModel(
      seasonYear: seasonYear ?? this.seasonYear,
      tours: tours != null
          ? List<ExoticTourDefinition>.unmodifiable(tours)
          : this.tours,
      promotedTourIds: promotedTourIds != null
          ? List<ExoticTourId>.unmodifiable(promotedTourIds)
          : this.promotedTourIds,
      participationHistory: participationHistory != null
          ? List<TeamExoticTourParticipationRecord>.unmodifiable(
              participationHistory,
            )
          : this.participationHistory,
      globalExpansionReputation:
          globalExpansionReputation ?? this.globalExpansionReputation,
      nonEuropeanFanBase: nonEuropeanFanBase ?? this.nonEuropeanFanBase,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seasonYear': seasonYear,
      'tours': tours.map((e) => e.toJson()).toList(),
      'promotedTourIds': promotedTourIds.map((e) => e.toJson()).toList(),
      'participationHistory':
          participationHistory.map((e) => e.toJson()).toList(),
      'globalExpansionReputation': globalExpansionReputation,
      'nonEuropeanFanBase': nonEuropeanFanBase,
    };
  }

  factory GlobalExoticToursExpansionModel.fromJson(Map<String, dynamic> json) {
    final parsedTours = (json['tours'] as List<dynamic>?)
            ?.map(
              (e) => ExoticTourDefinition.fromJson(e as Map<String, dynamic>),
            )
            .toList(growable: false) ??
        _defaultExoticTours();

    return GlobalExoticToursExpansionModel(
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      tours: List<ExoticTourDefinition>.unmodifiable(
        parsedTours.isEmpty ? _defaultExoticTours() : parsedTours,
      ),
      promotedTourIds: List<ExoticTourId>.unmodifiable(
        (json['promotedTourIds'] as List<dynamic>? ?? const [])
            .map((e) => ExoticTourId.fromJson(e as String)),
      ),
      participationHistory: List<TeamExoticTourParticipationRecord>.unmodifiable(
        (json['participationHistory'] as List<dynamic>? ?? const []).map(
          (e) => TeamExoticTourParticipationRecord.fromJson(
            e as Map<String, dynamic>,
          ),
        ),
      ),
      globalExpansionReputation:
          (json['globalExpansionReputation'] as num?)?.toDouble() ?? 25.0,
      nonEuropeanFanBase: (json['nonEuropeanFanBase'] as num?)?.toInt() ?? 12000,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GlobalExoticToursExpansionModel &&
        other.seasonYear == seasonYear &&
        other.tours.length == tours.length &&
        other.promotedTourIds.length == promotedTourIds.length &&
        other.participationHistory.length == participationHistory.length &&
        other.globalExpansionReputation == globalExpansionReputation &&
        other.nonEuropeanFanBase == nonEuropeanFanBase;
  }

  @override
  int get hashCode => Object.hash(
        seasonYear,
        tours.length,
        promotedTourIds.length,
        participationHistory.length,
        globalExpansionReputation,
        nonEuropeanFanBase,
      );

  @override
  String toString() =>
      'GlobalExoticToursExpansionModel($seasonYear: ${tours.length} tours, rep=${globalExpansionReputation.toStringAsFixed(1)}, fans=$nonEuropeanFanBase)';
}

List<ExoticTourDefinition> _defaultExoticTours() {
  return const [
    ExoticTourDefinition(
      tourId: ExoticTourId.tourDuRwanda,
      officialName: 'Tour du Rwanda',
      countryName: 'Rwanda',
      countryIso: 'RWA',
      region: ExoticMarketRegion.eastAfrica,
      uciCode: '2.1',
      uciCategory: RaceCategory.class1,
      expansionTier: ExoticExpansionTier.emergingMarket21,
      startMonth: 2,
      startDay: 22,
      ridersPerTeam: 5,
      prizePoolEur: 85000,
      climateChallenge: ExoticClimateChallenge.highAltitudeAndTropicalRain,
      logistics: ExoticLogisticsAndAcclimatizationProfile(
        flightHoursFromEurope: 9.5,
        timeZoneOffsetHours: 1,
        travelCostPerSquadEur: 32000,
        recommendedAcclimatizationDays: 5,
        baseAltitudeMeters: 1550.0,
        peakAltitudeMeters: 2450.0,
        avgTemperatureCelsius: 24.5,
        avgHumidityPercent: 72.0,
        recommendedProtocol: AcclimatizationProtocolType.altitudeCamp,
      ),
      commercialImpact: ExoticCommercialAndPrestigeImpact(
        sponsorExposureMultiplier: 1.22,
        emergingMarketFanGrowth: 28000,
        uciPointsWinner: 125,
        appearanceFeeEur: 38000,
        broadcastReachMillions: 14.5,
        localTalentScoutingBonus: 0.45,
      ),
      stageTemplates: [
        ExoticTourStageTemplate(
          stageNumber: 1,
          name: 'Kigali Prologue (Kimihurura Cobbles)',
          stageType: StageType.individualTimeTrial,
          distanceKm: 4.2,
          elevationGainM: 110,
          startElevationM: 1480,
          endElevationM: 1560,
          baseTemperatureCelsius: 24.0,
          weatherCondition: WeatherCondition.sunny,
          windSpeedKmh: 10.0,
          signatureFeature: ExoticStageSignatureFeature.kigaliCobblesWall,
          finalSurfaceType: SegmentSurfaceType.cobblestonesSector3,
        ),
        ExoticTourStageTemplate(
          stageNumber: 2,
          name: 'Kigali – Musanze (Virunga Foothills)',
          stageType: StageType.highMountain,
          distanceKm: 132.0,
          elevationGainM: 2850,
          startElevationM: 1510,
          endElevationM: 1860,
          baseTemperatureCelsius: 21.5,
          weatherCondition: WeatherCondition.lightRain,
          windSpeedKmh: 14.0,
          signatureFeature: ExoticStageSignatureFeature.kigaliCobblesWall,
          finalSurfaceType: SegmentSurfaceType.roughAsphalt,
        ),
        ExoticTourStageTemplate(
          stageNumber: 3,
          name: 'Rubavu – Mount Kigali Summit',
          stageType: StageType.summitFinish,
          distanceKm: 148.0,
          elevationGainM: 3150,
          startElevationM: 1465,
          endElevationM: 1850,
          baseTemperatureCelsius: 23.5,
          weatherCondition: WeatherCondition.overcast,
          windSpeedKmh: 12.0,
          signatureFeature: ExoticStageSignatureFeature.kigaliCobblesWall,
          finalSurfaceType: SegmentSurfaceType.cobblestonesSector4,
        ),
        ExoticTourStageTemplate(
          stageNumber: 4,
          name: 'Kigali Canal Circuit (Mur de Kigali)',
          stageType: StageType.hilly,
          distanceKm: 98.0,
          elevationGainM: 2100,
          startElevationM: 1490,
          endElevationM: 1575,
          baseTemperatureCelsius: 25.0,
          weatherCondition: WeatherCondition.sunny,
          windSpeedKmh: 11.0,
          signatureFeature: ExoticStageSignatureFeature.kigaliCobblesWall,
          finalSurfaceType: SegmentSurfaceType.cobblestonesSector3,
        ),
      ],
      culturalSummary:
          'Afrykański fenomen kolarski z setkami tysięcy kibiców przy brukowanym Mur de Kigali na wysokości powyżej 1500 m n.p.m.',
    ),
    ExoticTourDefinition(
      tourId: ExoticTourId.tourDeLangkawi,
      officialName: 'Tour de Langkawi',
      countryName: 'Malaysia',
      countryIso: 'MAS',
      region: ExoticMarketRegion.southeastAsia,
      uciCode: '2.Pro',
      uciCategory: RaceCategory.proSeries,
      expansionTier: ExoticExpansionTier.establishedProSeries,
      startMonth: 10,
      startDay: 1,
      ridersPerTeam: 6,
      prizePoolEur: 175000,
      climateChallenge: ExoticClimateChallenge.tropicalHeatAndMonsoonHumidity,
      logistics: ExoticLogisticsAndAcclimatizationProfile(
        flightHoursFromEurope: 13.0,
        timeZoneOffsetHours: 7,
        travelCostPerSquadEur: 54000,
        recommendedAcclimatizationDays: 6,
        baseAltitudeMeters: 20.0,
        peakAltitudeMeters: 1765.0,
        avgTemperatureCelsius: 33.0,
        avgHumidityPercent: 86.0,
        recommendedProtocol: AcclimatizationProtocolType.combinedJetLagAndHeat,
      ),
      commercialImpact: ExoticCommercialAndPrestigeImpact(
        sponsorExposureMultiplier: 1.38,
        emergingMarketFanGrowth: 42000,
        uciPointsWinner: 200,
        appearanceFeeEur: 75000,
        broadcastReachMillions: 36.0,
        localTalentScoutingBonus: 0.30,
      ),
      stageTemplates: [
        ExoticTourStageTemplate(
          stageNumber: 1,
          name: 'Langkawi Island Coastal Sprint',
          stageType: StageType.flat,
          distanceKm: 112.0,
          elevationGainM: 480,
          startElevationM: 12,
          endElevationM: 15,
          baseTemperatureCelsius: 33.5,
          weatherCondition: WeatherCondition.extremeHeat,
          windSpeedKmh: 18.0,
          signatureFeature: ExoticStageSignatureFeature.tropicalMonsoonCircuit,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
        ExoticTourStageTemplate(
          stageNumber: 2,
          name: 'Kuala Lumpur – Cameron Highlands',
          stageType: StageType.hilly,
          distanceKm: 164.0,
          elevationGainM: 2450,
          startElevationM: 45,
          endElevationM: 1440,
          baseTemperatureCelsius: 29.0,
          weatherCondition: WeatherCondition.lightRain,
          windSpeedKmh: 12.0,
          signatureFeature: ExoticStageSignatureFeature.tropicalMonsoonCircuit,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
        ExoticTourStageTemplate(
          stageNumber: 3,
          name: 'Genting Highlands Queen Stage (HC)',
          stageType: StageType.summitFinish,
          distanceKm: 152.0,
          elevationGainM: 3320,
          startElevationM: 60,
          endElevationM: 1765,
          baseTemperatureCelsius: 31.0,
          weatherCondition: WeatherCondition.heavyStorm,
          windSpeedKmh: 16.0,
          signatureFeature: ExoticStageSignatureFeature.gentingHighlandsHc,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
        ExoticTourStageTemplate(
          stageNumber: 4,
          name: 'Putrajaya – Kuala Lumpur Petronas Finale',
          stageType: StageType.flat,
          distanceKm: 138.0,
          elevationGainM: 620,
          startElevationM: 30,
          endElevationM: 35,
          baseTemperatureCelsius: 34.0,
          weatherCondition: WeatherCondition.sunny,
          windSpeedKmh: 14.0,
          signatureFeature: ExoticStageSignatureFeature.tropicalMonsoonCircuit,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
      ],
      culturalSummary:
          'Najważniejsza etapówka Azji Południowo-Wschodniej łącząca tropikalną wilgotność monsunową z monumentalnym podjazdem Genting Highlands.',
    ),
    ExoticTourDefinition(
      tourId: ExoticTourId.tourOfOman,
      officialName: 'Tour of Oman',
      countryName: 'Oman',
      countryIso: 'OMA',
      region: ExoticMarketRegion.arabianPeninsula,
      uciCode: '2.Pro',
      uciCategory: RaceCategory.proSeries,
      expansionTier: ExoticExpansionTier.establishedProSeries,
      startMonth: 2,
      startDay: 10,
      ridersPerTeam: 7,
      prizePoolEur: 190000,
      climateChallenge: ExoticClimateChallenge.desertHeatAndCoastalCrosswinds,
      logistics: ExoticLogisticsAndAcclimatizationProfile(
        flightHoursFromEurope: 7.0,
        timeZoneOffsetHours: 3,
        travelCostPerSquadEur: 46000,
        recommendedAcclimatizationDays: 4,
        baseAltitudeMeters: 15.0,
        peakAltitudeMeters: 1340.0,
        avgTemperatureCelsius: 30.5,
        avgHumidityPercent: 38.0,
        recommendedProtocol:
            AcclimatizationProtocolType.heatChamberAndHydration,
      ),
      commercialImpact: ExoticCommercialAndPrestigeImpact(
        sponsorExposureMultiplier: 1.35,
        emergingMarketFanGrowth: 24000,
        uciPointsWinner: 200,
        appearanceFeeEur: 82000,
        broadcastReachMillions: 29.0,
        localTalentScoutingBonus: 0.18,
      ),
      stageTemplates: [
        ExoticTourStageTemplate(
          stageNumber: 1,
          name: 'Muscat – Oman Convention Centre',
          stageType: StageType.flat,
          distanceKm: 174.0,
          elevationGainM: 650,
          startElevationM: 10,
          endElevationM: 18,
          baseTemperatureCelsius: 30.0,
          weatherCondition: WeatherCondition.crosswindGale,
          windSpeedKmh: 34.0,
          signatureFeature: ExoticStageSignatureFeature.crosswindDesertEchelon,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
        ExoticTourStageTemplate(
          stageNumber: 2,
          name: 'Sultan Qaboos University – Qurayyat',
          stageType: StageType.hilly,
          distanceKm: 168.0,
          elevationGainM: 1750,
          startElevationM: 45,
          endElevationM: 210,
          baseTemperatureCelsius: 31.0,
          weatherCondition: WeatherCondition.sunny,
          windSpeedKmh: 22.0,
          signatureFeature: ExoticStageSignatureFeature.crosswindDesertEchelon,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
        ExoticTourStageTemplate(
          stageNumber: 3,
          name: 'Samail – Jabal Al Akhdhar (Green Mountain)',
          stageType: StageType.summitFinish,
          distanceKm: 152.0,
          elevationGainM: 2450,
          startElevationM: 320,
          endElevationM: 1340,
          baseTemperatureCelsius: 28.5,
          weatherCondition: WeatherCondition.sunny,
          windSpeedKmh: 18.0,
          signatureFeature: ExoticStageSignatureFeature.greenMountainSummit,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
        ExoticTourStageTemplate(
          stageNumber: 4,
          name: 'Al الموج – Matrah Corniche',
          stageType: StageType.flat,
          distanceKm: 139.0,
          elevationGainM: 520,
          startElevationM: 8,
          endElevationM: 10,
          baseTemperatureCelsius: 30.5,
          weatherCondition: WeatherCondition.sunny,
          windSpeedKmh: 24.0,
          signatureFeature: ExoticStageSignatureFeature.crosswindDesertEchelon,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
      ],
      culturalSummary:
          'Wczesnosezonowy sprawdzian górali i sprinterów nad Zatoką Omańską z legendarną ścianą Jabal Al Akhdhar (Green Mountain).',
    ),
    ExoticTourDefinition(
      tourId: ExoticTourId.alUlaTour,
      officialName: 'AlUla Tour',
      countryName: 'Saudi Arabia',
      countryIso: 'KSA',
      region: ExoticMarketRegion.arabianPeninsula,
      uciCode: '2.1',
      uciCategory: RaceCategory.class1,
      expansionTier: ExoticExpansionTier.worldTourCandidate,
      startMonth: 1,
      startDay: 28,
      ridersPerTeam: 7,
      prizePoolEur: 155000,
      climateChallenge: ExoticClimateChallenge.aridDesertAndSandstorms,
      logistics: ExoticLogisticsAndAcclimatizationProfile(
        flightHoursFromEurope: 6.5,
        timeZoneOffsetHours: 2,
        travelCostPerSquadEur: 49000,
        recommendedAcclimatizationDays: 3,
        baseAltitudeMeters: 680.0,
        peakAltitudeMeters: 1180.0,
        avgTemperatureCelsius: 26.5,
        avgHumidityPercent: 22.0,
        recommendedProtocol:
            AcclimatizationProtocolType.heatChamberAndHydration,
      ),
      commercialImpact: ExoticCommercialAndPrestigeImpact(
        sponsorExposureMultiplier: 1.44,
        emergingMarketFanGrowth: 31000,
        uciPointsWinner: 125,
        appearanceFeeEur: 95000,
        broadcastReachMillions: 31.5,
        localTalentScoutingBonus: 0.20,
      ),
      stageTemplates: [
        ExoticTourStageTemplate(
          stageNumber: 1,
          name: 'AlManshiyah Train Station Desert Echelon',
          stageType: StageType.flat,
          distanceKm: 149.0,
          elevationGainM: 640,
          startElevationM: 680,
          endElevationM: 710,
          baseTemperatureCelsius: 25.5,
          weatherCondition: WeatherCondition.crosswindGale,
          windSpeedKmh: 38.0,
          signatureFeature: ExoticStageSignatureFeature.crosswindDesertEchelon,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
        ExoticTourStageTemplate(
          stageNumber: 2,
          name: 'Winter Park – Sharaan Nature Reserve',
          stageType: StageType.hilly,
          distanceKm: 162.0,
          elevationGainM: 1280,
          startElevationM: 700,
          endElevationM: 860,
          baseTemperatureCelsius: 27.0,
          weatherCondition: WeatherCondition.sunny,
          windSpeedKmh: 26.0,
          signatureFeature: ExoticStageSignatureFeature.crosswindDesertEchelon,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
        ExoticTourStageTemplate(
          stageNumber: 3,
          name: 'AlUla Old Town – Skyviews of Harrat Uwayrid',
          stageType: StageType.summitFinish,
          distanceKm: 142.0,
          elevationGainM: 1690,
          startElevationM: 690,
          endElevationM: 1180,
          baseTemperatureCelsius: 26.0,
          weatherCondition: WeatherCondition.sunny,
          windSpeedKmh: 24.0,
          signatureFeature:
              ExoticStageSignatureFeature.harratUwayridSteepRamp,
          finalSurfaceType: SegmentSurfaceType.roughAsphalt,
        ),
        ExoticTourStageTemplate(
          stageNumber: 4,
          name: 'Hegra UNESCO – Maraya Mirror Hall',
          stageType: StageType.flat,
          distanceKm: 144.0,
          elevationGainM: 510,
          startElevationM: 720,
          endElevationM: 735,
          baseTemperatureCelsius: 27.5,
          weatherCondition: WeatherCondition.sunny,
          windSpeedKmh: 31.0,
          signatureFeature: ExoticStageSignatureFeature.crosswindDesertEchelon,
          finalSurfaceType: SegmentSurfaceType.smoothAsphalt,
        ),
      ],
      culturalSummary:
          'Pustynny wyścig wśród kanionów AlUla i zabytków Hegry z brutalną, ponad 12-procentową rampą na wulkaniczny płaskowyż Harrat Uwayrid.',
    ),
  ];
}
