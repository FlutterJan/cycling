import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';

/// Typ frontu lub komórki burzowej obserwowanej na radarze meteorologicznym.
enum StormFrontType {
  coldFront,
  squallLine,
  orographicCell,
  coastalGale,
  convectiveSupercell;

  String toJson() => name;

  static StormFrontType fromJson(String value) {
    return StormFrontType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => StormFrontType.coldFront,
    );
  }

  String get labelPl {
    switch (this) {
      case StormFrontType.coldFront:
        return 'Chłodny front burzowy';
      case StormFrontType.squallLine:
        return 'Linia szkwału';
      case StormFrontType.orographicCell:
        return 'Komórka orograficzna';
      case StormFrontType.coastalGale:
        return 'Sztorm przybrzeżny';
      case StormFrontType.convectiveSupercell:
        return 'Superkomórka burzowa';
    }
  }

  String get shortTag {
    switch (this) {
      case StormFrontType.coldFront:
        return 'FRONT';
      case StormFrontType.squallLine:
        return 'SZKWAŁ';
      case StormFrontType.orographicCell:
        return 'GÓRY';
      case StormFrontType.coastalGale:
        return 'WICHURA';
      case StormFrontType.convectiveSupercell:
        return 'SUPER';
    }
  }
}

/// Klasa intensywności opadów wyznaczana na podstawie odbiciowości radaru (dBZ).
enum RadarPrecipitationIntensity {
  none,
  lightShower,
  moderateRain,
  heavyDownpour,
  torrentialHail;

  String toJson() => name;

  static RadarPrecipitationIntensity fromJson(String value) {
    return RadarPrecipitationIntensity.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RadarPrecipitationIntensity.none,
    );
  }

  String get labelPl {
    switch (this) {
      case RadarPrecipitationIntensity.none:
        return 'Sucho / Bez opadów';
      case RadarPrecipitationIntensity.lightShower:
        return 'Przelotny deszcz';
      case RadarPrecipitationIntensity.moderateRain:
        return 'Umiarkowany deszcz';
      case RadarPrecipitationIntensity.heavyDownpour:
        return 'Ulewny deszcz';
      case RadarPrecipitationIntensity.torrentialHail:
        return 'Nawałnica z gradem';
    }
  }

  WeatherCondition toWeatherCondition({required double crosswindKmh}) {
    switch (this) {
      case RadarPrecipitationIntensity.none:
        return crosswindKmh >= 35.0
            ? WeatherCondition.crosswindGale
            : WeatherCondition.sunny;
      case RadarPrecipitationIntensity.lightShower:
        return WeatherCondition.lightRain;
      case RadarPrecipitationIntensity.moderateRain:
      case RadarPrecipitationIntensity.heavyDownpour:
      case RadarPrecipitationIntensity.torrentialHail:
        return WeatherCondition.heavyStorm;
    }
  }

  Color get radarColor {
    switch (this) {
      case RadarPrecipitationIntensity.none:
        return AppColors.textSecondary;
      case RadarPrecipitationIntensity.lightShower:
        return AppColors.statusSuccess;
      case RadarPrecipitationIntensity.moderateRain:
        return AppColors.accentBlue;
      case RadarPrecipitationIntensity.heavyDownpour:
        return AppColors.amberWarning;
      case RadarPrecipitationIntensity.torrentialHail:
        return AppColors.crimsonAlert;
    }
  }
}

/// Poziom alarmu meteorologicznego dla Dyrektora Sportowego i peletonu.
enum WeatherShiftAlertLevel {
  clear,
  approaching,
  imminent,
  activeImpact,
  clearing;

  String toJson() => name;

  static WeatherShiftAlertLevel fromJson(String value) {
    return WeatherShiftAlertLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WeatherShiftAlertLevel.clear,
    );
  }

  String get labelPl {
    switch (this) {
      case WeatherShiftAlertLevel.clear:
        return 'Stabilnie';
      case WeatherShiftAlertLevel.approaching:
        return 'Front w natarciu';
      case WeatherShiftAlertLevel.imminent:
        return 'Uderzenie < 15 min';
      case WeatherShiftAlertLevel.activeImpact:
        return 'Uderzenie na trasie';
      case WeatherShiftAlertLevel.clearing:
        return 'Przejaśnienie';
    }
  }

  Color get badgeColor {
    switch (this) {
      case WeatherShiftAlertLevel.clear:
        return AppColors.statusSuccess;
      case WeatherShiftAlertLevel.approaching:
        return AppColors.accentBlue;
      case WeatherShiftAlertLevel.imminent:
        return AppColors.amberWarning;
      case WeatherShiftAlertLevel.activeImpact:
        return AppColors.crimsonAlert;
      case WeatherShiftAlertLevel.clearing:
        return AppColors.cyanAccent;
    }
  }
}

/// Horyzont czasowy podglądu radaru prognozy.
enum RadarForecastHorizon {
  now(0, 'Teraz'),
  plus15m(15, '+15 min'),
  plus30m(30, '+30 min'),
  plus60m(60, '+60 min');

  const RadarForecastHorizon(this.minutesAhead, this.labelPl);

  final int minutesAhead;
  final String labelPl;

  String toJson() => name;

  static RadarForecastHorizon fromJson(String value) {
    return RadarForecastHorizon.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RadarForecastHorizon.now,
    );
  }
}

/// Punkt trasy wyścigu zrzutowany na dwuwymiarową siatkę radaru [km].
class RadarRoutePoint {
  final double routeKm;
  final double xKm;
  final double yKm;
  final double elevationM;
  final double roadBearingDegrees;

  const RadarRoutePoint({
    required this.routeKm,
    required this.xKm,
    required this.yKm,
    required this.elevationM,
    required this.roadBearingDegrees,
  });

  Map<String, dynamic> toJson() => {
        'routeKm': routeKm,
        'xKm': xKm,
        'yKm': yKm,
        'elevationM': elevationM,
        'roadBearingDegrees': roadBearingDegrees,
      };

  factory RadarRoutePoint.fromJson(Map<String, dynamic> json) {
    return RadarRoutePoint(
      routeKm: (json['routeKm'] as num?)?.toDouble() ?? 0.0,
      xKm: (json['xKm'] as num?)?.toDouble() ?? 0.0,
      yKm: (json['yKm'] as num?)?.toDouble() ?? 0.0,
      elevationM: (json['elevationM'] as num?)?.toDouble() ?? 0.0,
      roadBearingDegrees: (json['roadBearingDegrees'] as num?)?.toDouble() ?? 90.0,
    );
  }
}

/// Aktywna komórka lub front burzowy przesuwający się po mapie radarowej.
class StormFrontCell {
  final String id;
  final String name;
  final StormFrontType frontType;
  final double centerXKm;
  final double centerYKm;
  final double radiusKm;
  final double elongationRatio;
  final double orientationDeg;
  final double velocityXKmPerHour;
  final double velocityYKmPerHour;
  final double peakIntensityDbz;
  final double precipitationMmPerHour;
  final double windGustKmh;
  final double windDirectionDeg;
  final double temperatureDropC;
  final double lightningRisk;
  final double hailProbability;
  final bool isDissipating;

  const StormFrontCell({
    required this.id,
    required this.name,
    required this.frontType,
    required this.centerXKm,
    required this.centerYKm,
    required this.radiusKm,
    this.elongationRatio = 1.4,
    this.orientationDeg = 35.0,
    required this.velocityXKmPerHour,
    required this.velocityYKmPerHour,
    required this.peakIntensityDbz,
    required this.precipitationMmPerHour,
    required this.windGustKmh,
    required this.windDirectionDeg,
    required this.temperatureDropC,
    this.lightningRisk = 0.25,
    this.hailProbability = 0.05,
    this.isDissipating = false,
  });

  double get speedKmPerHour =>
      math.sqrt(velocityXKmPerHour * velocityXKmPerHour +
          velocityYKmPerHour * velocityYKmPerHour);

  double get movementBearingDeg {
    final rad = math.atan2(velocityXKmPerHour, velocityYKmPerHour);
    return (rad * 180.0 / math.pi + 360.0) % 360.0;
  }

  StormFrontCell copyWith({
    String? id,
    String? name,
    StormFrontType? frontType,
    double? centerXKm,
    double? centerYKm,
    double? radiusKm,
    double? elongationRatio,
    double? orientationDeg,
    double? velocityXKmPerHour,
    double? velocityYKmPerHour,
    double? peakIntensityDbz,
    double? precipitationMmPerHour,
    double? windGustKmh,
    double? windDirectionDeg,
    double? temperatureDropC,
    double? lightningRisk,
    double? hailProbability,
    bool? isDissipating,
  }) {
    return StormFrontCell(
      id: id ?? this.id,
      name: name ?? this.name,
      frontType: frontType ?? this.frontType,
      centerXKm: centerXKm ?? this.centerXKm,
      centerYKm: centerYKm ?? this.centerYKm,
      radiusKm: radiusKm ?? this.radiusKm,
      elongationRatio: elongationRatio ?? this.elongationRatio,
      orientationDeg: orientationDeg ?? this.orientationDeg,
      velocityXKmPerHour: velocityXKmPerHour ?? this.velocityXKmPerHour,
      velocityYKmPerHour: velocityYKmPerHour ?? this.velocityYKmPerHour,
      peakIntensityDbz: peakIntensityDbz ?? this.peakIntensityDbz,
      precipitationMmPerHour:
          precipitationMmPerHour ?? this.precipitationMmPerHour,
      windGustKmh: windGustKmh ?? this.windGustKmh,
      windDirectionDeg: windDirectionDeg ?? this.windDirectionDeg,
      temperatureDropC: temperatureDropC ?? this.temperatureDropC,
      lightningRisk: lightningRisk ?? this.lightningRisk,
      hailProbability: hailProbability ?? this.hailProbability,
      isDissipating: isDissipating ?? this.isDissipating,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'frontType': frontType.toJson(),
        'centerXKm': centerXKm,
        'centerYKm': centerYKm,
        'radiusKm': radiusKm,
        'elongationRatio': elongationRatio,
        'orientationDeg': orientationDeg,
        'velocityXKmPerHour': velocityXKmPerHour,
        'velocityYKmPerHour': velocityYKmPerHour,
        'peakIntensityDbz': peakIntensityDbz,
        'precipitationMmPerHour': precipitationMmPerHour,
        'windGustKmh': windGustKmh,
        'windDirectionDeg': windDirectionDeg,
        'temperatureDropC': temperatureDropC,
        'lightningRisk': lightningRisk,
        'hailProbability': hailProbability,
        'isDissipating': isDissipating,
      };

  factory StormFrontCell.fromJson(Map<String, dynamic> json) {
    return StormFrontCell(
      id: json['id'] as String? ?? 'cell_0',
      name: json['name'] as String? ?? 'Komórka burzowa',
      frontType: StormFrontType.fromJson(json['frontType'] as String? ?? ''),
      centerXKm: (json['centerXKm'] as num?)?.toDouble() ?? 0.0,
      centerYKm: (json['centerYKm'] as num?)?.toDouble() ?? 0.0,
      radiusKm: (json['radiusKm'] as num?)?.toDouble() ?? 12.0,
      elongationRatio: (json['elongationRatio'] as num?)?.toDouble() ?? 1.4,
      orientationDeg: (json['orientationDeg'] as num?)?.toDouble() ?? 35.0,
      velocityXKmPerHour:
          (json['velocityXKmPerHour'] as num?)?.toDouble() ?? 24.0,
      velocityYKmPerHour:
          (json['velocityYKmPerHour'] as num?)?.toDouble() ?? -10.0,
      peakIntensityDbz: (json['peakIntensityDbz'] as num?)?.toDouble() ?? 42.0,
      precipitationMmPerHour:
          (json['precipitationMmPerHour'] as num?)?.toDouble() ?? 8.0,
      windGustKmh: (json['windGustKmh'] as num?)?.toDouble() ?? 36.0,
      windDirectionDeg:
          (json['windDirectionDeg'] as num?)?.toDouble() ?? 285.0,
      temperatureDropC: (json['temperatureDropC'] as num?)?.toDouble() ?? 4.5,
      lightningRisk: (json['lightningRisk'] as num?)?.toDouble() ?? 0.25,
      hailProbability: (json['hailProbability'] as num?)?.toDouble() ?? 0.05,
      isDissipating: json['isDissipating'] as bool? ?? false,
    );
  }
}

/// Próbka warunków atmosferycznych wyliczona dla konkretnego kilometra trasy.
class RouteWeatherImpactSample {
  final double routeKm;
  final int forecastMinutesAhead;
  final RadarPrecipitationIntensity intensity;
  final double dbz;
  final double precipitationMmPerHour;
  final double windSpeedKmh;
  final double windDirectionDeg;
  final double crosswindComponentKmh;
  final double temperatureC;
  final double asphaltGripMultiplier;
  final double crrPenaltyMultiplier;
  final double visibilityMeters;
  final double lightningRisk;
  final List<String> activeFrontIds;

  const RouteWeatherImpactSample({
    required this.routeKm,
    required this.forecastMinutesAhead,
    required this.intensity,
    required this.dbz,
    required this.precipitationMmPerHour,
    required this.windSpeedKmh,
    required this.windDirectionDeg,
    required this.crosswindComponentKmh,
    required this.temperatureC,
    required this.asphaltGripMultiplier,
    required this.crrPenaltyMultiplier,
    required this.visibilityMeters,
    required this.lightningRisk,
    required this.activeFrontIds,
  });

  bool get isStormActive =>
      intensity == RadarPrecipitationIntensity.heavyDownpour ||
      intensity == RadarPrecipitationIntensity.torrentialHail ||
      crosswindComponentKmh >= 32.0;

  WeatherCondition get standardCondition =>
      intensity.toWeatherCondition(crosswindKmh: crosswindComponentKmh);
}

/// Prognoza przesunięcia frontu i wpływu na peleton w zadanym horyzoncie czasowym.
class WeatherShiftForecastTimelineEntry {
  final int minutesAhead;
  final double pelotonProjectedKm;
  final RouteWeatherImpactSample impactAtPeloton;
  final double? frontPeakKmOnRoute;
  final double peakRouteDbz;
  final WeatherShiftAlertLevel alertLevel;
  final String recommendedTacticPl;

  const WeatherShiftForecastTimelineEntry({
    required this.minutesAhead,
    required this.pelotonProjectedKm,
    required this.impactAtPeloton,
    required this.frontPeakKmOnRoute,
    required this.peakRouteDbz,
    required this.alertLevel,
    required this.recommendedTacticPl,
  });
}

/// Zdarzenie nagłego przesunięcia prognozy wykryte podczas wyścigu.
class ForecastShiftAlertEvent {
  final double raceTimeMinutes;
  final WeatherShiftAlertLevel previousLevel;
  final WeatherShiftAlertLevel newLevel;
  final double deltaDbz;
  final double deltaCrosswindKmh;
  final String headlinePl;
  final String tacticalAdvicePl;

  const ForecastShiftAlertEvent({
    required this.raceTimeMinutes,
    required this.previousLevel,
    required this.newLevel,
    required this.deltaDbz,
    required this.deltaCrosswindKmh,
    required this.headlinePl,
    required this.tacticalAdvicePl,
  });
}

/// Pełny stan dynamicznego radaru burzowego w trakcie etapu.
class WeatherRadarLiveState {
  final String stageName;
  final double stageDistanceKm;
  final double raceTimeMinutes;
  final double pelotonKm;
  final double breakawayKm;
  final double pelotonSpeedKmh;
  final double baseTemperatureC;
  final double baseWindKmh;
  final double baseWindDirectionDeg;
  final List<RadarRoutePoint> routePoints;
  final List<StormFrontCell> stormCells;
  final List<WeatherShiftForecastTimelineEntry> timelineForecast;
  final WeatherShiftAlertLevel alertLevel;
  final bool autoSweepEnabled;
  final RadarForecastHorizon selectedHorizon;
  final String? selectedCellId;
  final bool isPaused;
  final double playbackSpeedMultiplier;
  final String lastShiftMessagePl;

  const WeatherRadarLiveState({
    required this.stageName,
    required this.stageDistanceKm,
    required this.raceTimeMinutes,
    required this.pelotonKm,
    required this.breakawayKm,
    required this.pelotonSpeedKmh,
    required this.baseTemperatureC,
    required this.baseWindKmh,
    required this.baseWindDirectionDeg,
    required this.routePoints,
    required this.stormCells,
    required this.timelineForecast,
    required this.alertLevel,
    this.autoSweepEnabled = true,
    this.selectedHorizon = RadarForecastHorizon.now,
    this.selectedCellId,
    this.isPaused = false,
    this.playbackSpeedMultiplier = 1.0,
    this.lastShiftMessagePl =
        'Radar meteorologiczny aktywny. Monitorowanie komórek konwekcyjnych.',
  });

  StormFrontCell? get selectedCell {
    if (selectedCellId == null) return null;
    for (final cell in stormCells) {
      if (cell.id == selectedCellId) return cell;
    }
    return null;
  }

  WeatherShiftForecastTimelineEntry? get activeHorizonEntry {
    for (final entry in timelineForecast) {
      if (entry.minutesAhead == selectedHorizon.minutesAhead) {
        return entry;
      }
    }
    return timelineForecast.isNotEmpty ? timelineForecast.first : null;
  }

  WeatherRadarLiveState copyWith({
    String? stageName,
    double? stageDistanceKm,
    double? raceTimeMinutes,
    double? pelotonKm,
    double? breakawayKm,
    double? pelotonSpeedKmh,
    double? baseTemperatureC,
    double? baseWindKmh,
    double? baseWindDirectionDeg,
    List<RadarRoutePoint>? routePoints,
    List<StormFrontCell>? stormCells,
    List<WeatherShiftForecastTimelineEntry>? timelineForecast,
    WeatherShiftAlertLevel? alertLevel,
    bool? autoSweepEnabled,
    RadarForecastHorizon? selectedHorizon,
    String? selectedCellId,
    bool clearSelectedCell = false,
    bool? isPaused,
    double? playbackSpeedMultiplier,
    String? lastShiftMessagePl,
  }) {
    return WeatherRadarLiveState(
      stageName: stageName ?? this.stageName,
      stageDistanceKm: stageDistanceKm ?? this.stageDistanceKm,
      raceTimeMinutes: raceTimeMinutes ?? this.raceTimeMinutes,
      pelotonKm: pelotonKm ?? this.pelotonKm,
      breakawayKm: breakawayKm ?? this.breakawayKm,
      pelotonSpeedKmh: pelotonSpeedKmh ?? this.pelotonSpeedKmh,
      baseTemperatureC: baseTemperatureC ?? this.baseTemperatureC,
      baseWindKmh: baseWindKmh ?? this.baseWindKmh,
      baseWindDirectionDeg: baseWindDirectionDeg ?? this.baseWindDirectionDeg,
      routePoints: routePoints ?? this.routePoints,
      stormCells: stormCells ?? this.stormCells,
      timelineForecast: timelineForecast ?? this.timelineForecast,
      alertLevel: alertLevel ?? this.alertLevel,
      autoSweepEnabled: autoSweepEnabled ?? this.autoSweepEnabled,
      selectedHorizon: selectedHorizon ?? this.selectedHorizon,
      selectedCellId:
          clearSelectedCell ? null : (selectedCellId ?? this.selectedCellId),
      isPaused: isPaused ?? this.isPaused,
      playbackSpeedMultiplier:
          playbackSpeedMultiplier ?? this.playbackSpeedMultiplier,
      lastShiftMessagePl: lastShiftMessagePl ?? this.lastShiftMessagePl,
    );
  }
}

/// Silnik obliczeniowy dynamicznego radaru frontów burzowych i przesunięć prognozy.
class WeatherRadarLiveForecastShiftEngine {
  const WeatherRadarLiveForecastShiftEngine();

  /// Buduje dwuwymiarową geometrię trasy wyścigu na podstawie segmentów [RaceStage].
  List<RadarRoutePoint> buildCoursePolylineFromStage(RaceStage stage) {
    if (stage.segments.isEmpty) {
      return createDemoAlpineStormScenario().routePoints;
    }

    final rawPoints = <RadarRoutePoint>[];
    double x = 0.0;
    double y = 0.0;
    final firstSeg = stage.segments.first;
    rawPoints.add(
      RadarRoutePoint(
        routeKm: firstSeg.startKm,
        xKm: x,
        yKm: y,
        elevationM: firstSeg.startElevationM,
        roadBearingDegrees: firstSeg.roadBearingDegrees,
      ),
    );

    for (final seg in stage.segments) {
      final bearingRad = seg.roadBearingDegrees * math.pi / 180.0;
      x += math.sin(bearingRad) * seg.lengthKm;
      y += math.cos(bearingRad) * seg.lengthKm;
      rawPoints.add(
        RadarRoutePoint(
          routeKm: seg.endKm,
          xKm: x,
          yKm: y,
          elevationM: seg.endElevationM,
          roadBearingDegrees: seg.roadBearingDegrees,
        ),
      );
    }

    // Wyśrodkowanie polilinii wokół (0, 0) na siatce radarowej.
    double minX = rawPoints.first.xKm;
    double maxX = rawPoints.first.xKm;
    double minY = rawPoints.first.yKm;
    double maxY = rawPoints.first.yKm;
    for (final p in rawPoints) {
      if (p.xKm < minX) minX = p.xKm;
      if (p.xKm > maxX) maxX = p.xKm;
      if (p.yKm < minY) minY = p.yKm;
      if (p.yKm > maxY) maxY = p.yKm;
    }
    final cx = (minX + maxX) * 0.5;
    final cy = (minY + maxY) * 0.5;

    return rawPoints
        .map(
          (p) => RadarRoutePoint(
            routeKm: p.routeKm,
            xKm: p.xKm - cx,
            yKm: p.yKm - cy,
            elevationM: p.elevationM,
            roadBearingDegrees: p.roadBearingDegrees,
          ),
        )
        .toList(growable: false);
  }

  /// Tworzy realistyczny scenariusz alpejski z trzema przemieszczającymi się frontami.
  WeatherRadarLiveState createDemoAlpineStormScenario() {
    const totalKm = 168.0;
    final routePoints = <RadarRoutePoint>[];
    const steps = 28;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final km = t * totalKm;
      final xKm = -42.0 + t * 84.0 + math.sin(t * math.pi * 2.2) * 11.0;
      final yKm = -26.0 + t * 52.0 - math.cos(t * math.pi * 1.6) * 9.0;
      final elevation = 420.0 +
          math.sin(t * math.pi * 1.4).abs() * 1450.0 +
          (t > 0.65 ? (t - 0.65) * 1200.0 : 0.0);
      final bearing = (58.0 + math.cos(t * math.pi * 2.2) * 24.0 + 360.0) % 360.0;
      routePoints.add(
        RadarRoutePoint(
          routeKm: km,
          xKm: xKm,
          yKm: yKm,
          elevationM: elevation,
          roadBearingDegrees: bearing,
        ),
      );
    }

    const initialCells = <StormFrontCell>[
      StormFrontCell(
        id: 'front_alpha',
        name: 'Front Północno-Zachodni',
        frontType: StormFrontType.squallLine,
        centerXKm: -18.0,
        centerYKm: 18.0,
        radiusKm: 18.5,
        elongationRatio: 1.75,
        orientationDeg: 28.0,
        velocityXKmPerHour: 32.0,
        velocityYKmPerHour: -22.0,
        peakIntensityDbz: 52.0,
        precipitationMmPerHour: 18.4,
        windGustKmh: 54.0,
        windDirectionDeg: 305.0,
        temperatureDropC: 7.2,
        lightningRisk: 0.68,
        hailProbability: 0.18,
      ),
      StormFrontCell(
        id: 'cell_galibier',
        name: 'Komórka Orograficzna Col',
        frontType: StormFrontType.orographicCell,
        centerXKm: 24.0,
        centerYKm: 8.0,
        radiusKm: 13.0,
        elongationRatio: 1.25,
        orientationDeg: 65.0,
        velocityXKmPerHour: 11.0,
        velocityYKmPerHour: 12.0,
        peakIntensityDbz: 46.0,
        precipitationMmPerHour: 11.5,
        windGustKmh: 42.0,
        windDirectionDeg: 245.0,
        temperatureDropC: 5.5,
        lightningRisk: 0.42,
        hailProbability: 0.12,
      ),
      StormFrontCell(
        id: 'cell_valley',
        name: 'Przelotna Chmura Doliny',
        frontType: StormFrontType.coldFront,
        centerXKm: -34.0,
        centerYKm: -14.0,
        radiusKm: 14.0,
        elongationRatio: 1.4,
        orientationDeg: 15.0,
        velocityXKmPerHour: 24.0,
        velocityYKmPerHour: 16.0,
        peakIntensityDbz: 34.0,
        precipitationMmPerHour: 3.8,
        windGustKmh: 28.0,
        windDirectionDeg: 265.0,
        temperatureDropC: 2.8,
        lightningRisk: 0.10,
        hailProbability: 0.0,
        isDissipating: true,
      ),
    ];

    final timeline = computeForecastTimeline(
      routePoints: routePoints,
      stormCells: initialCells,
      pelotonKm: 64.0,
      pelotonSpeedKmh: 41.5,
      baseTemperatureC: 21.5,
      baseWindKmh: 16.0,
      baseWindDirectionDeg: 270.0,
    );

    final alert = _resolveOverallAlertLevel(timeline);

    return WeatherRadarLiveState(
      stageName: 'Etap 17: Bourg-d\'Oisans — Col du Galibier',
      stageDistanceKm: totalKm,
      raceTimeMinutes: 94.0,
      pelotonKm: 64.0,
      breakawayKm: 72.5,
      pelotonSpeedKmh: 41.5,
      baseTemperatureC: 21.5,
      baseWindKmh: 16.0,
      baseWindDirectionDeg: 270.0,
      routePoints: routePoints,
      stormCells: initialCells,
      timelineForecast: timeline,
      alertLevel: alert,
      lastShiftMessagePl:
          'Front Północno-Zachodni przyspiesza (+39 km/h) w stronę doliny przed podjazdem.',
    );
  }

  /// Tworzy stan początkowy radaru bezpośrednio z obiektu [RaceStage].
  WeatherRadarLiveState createStateFromStage(
    RaceStage stage, {
    double pelotonKm = 0.0,
    double breakawayKm = 4.0,
    double pelotonSpeedKmh = 42.0,
  }) {
    final routePoints = buildCoursePolylineFromStage(stage);
    final totalKm = math.max(1.0, stage.totalDistanceKm);

    final initialCells = <StormFrontCell>[
      StormFrontCell(
        id: 'stage_front_1',
        name: 'Front Atmosferyczny Etapu',
        frontType: stage.weatherCondition == WeatherCondition.crosswindGale
            ? StormFrontType.coastalGale
            : StormFrontType.coldFront,
        centerXKm: -22.0,
        centerYKm: 20.0,
        radiusKm: 19.0,
        elongationRatio: 1.65,
        orientationDeg: 30.0,
        velocityXKmPerHour: 29.0,
        velocityYKmPerHour: -18.0,
        peakIntensityDbz:
            stage.weatherCondition == WeatherCondition.heavyStorm ? 56.0 : 44.0,
        precipitationMmPerHour:
            stage.weatherCondition == WeatherCondition.heavyStorm ? 21.0 : 9.5,
        windGustKmh: math.max(26.0, stage.windSpeedKmh * 1.45),
        windDirectionDeg: stage.segments.isNotEmpty
            ? stage.segments.first.windDirectionDegrees
            : 280.0,
        temperatureDropC: 6.0,
        lightningRisk:
            stage.weatherCondition == WeatherCondition.heavyStorm ? 0.65 : 0.25,
        hailProbability:
            stage.weatherCondition == WeatherCondition.heavyStorm ? 0.2 : 0.04,
      ),
    ];

    final timeline = computeForecastTimeline(
      routePoints: routePoints,
      stormCells: initialCells,
      pelotonKm: pelotonKm.clamp(0.0, totalKm),
      pelotonSpeedKmh: pelotonSpeedKmh,
      baseTemperatureC: stage.baseTemperatureCelsius,
      baseWindKmh: stage.windSpeedKmh,
      baseWindDirectionDeg: stage.segments.isNotEmpty
          ? stage.segments.first.windDirectionDegrees
          : 270.0,
    );

    return WeatherRadarLiveState(
      stageName: stage.name,
      stageDistanceKm: totalKm,
      raceTimeMinutes: 0.0,
      pelotonKm: pelotonKm.clamp(0.0, totalKm),
      breakawayKm: breakawayKm.clamp(0.0, totalKm),
      pelotonSpeedKmh: pelotonSpeedKmh,
      baseTemperatureC: stage.baseTemperatureCelsius,
      baseWindKmh: stage.windSpeedKmh,
      baseWindDirectionDeg: stage.segments.isNotEmpty
          ? stage.segments.first.windDirectionDegrees
          : 270.0,
      routePoints: routePoints,
      stormCells: initialCells,
      timelineForecast: timeline,
      alertLevel: _resolveOverallAlertLevel(timeline),
    );
  }

  /// Przesuwa komórki burzowe o zadany krok czasowy [dtMinutes].
  List<StormFrontCell> advanceStormCells(
    List<StormFrontCell> cells,
    double dtMinutes, {
    double raceTimeMinutes = 0.0,
  }) {
    if (dtMinutes <= 0.0 || cells.isEmpty) return cells;
    final dtHours = dtMinutes / 60.0;

    return cells.map((cell) {
      // Subtelna adwekcja falowa (meandrowanie prądu strumieniowego).
      final waveAngle = (raceTimeMinutes * 0.045) + cell.id.hashCode * 0.37;
      final vx = cell.velocityXKmPerHour + math.sin(waveAngle) * 2.4;
      final vy = cell.velocityYKmPerHour + math.cos(waveAngle) * 1.8;

      var nextX = cell.centerXKm + vx * dtHours;
      var nextY = cell.centerYKm + vy * dtHours;

      // Zawijanie poza obszarem radaru [-75, 75] km, aby fronty krążyły w pętli.
      if (nextX > 72.0) nextX = -72.0;
      if (nextX < -72.0) nextX = 72.0;
      if (nextY > 72.0) nextY = -72.0;
      if (nextY < -72.0) nextY = 72.0;

      final dbzDelta = cell.isDissipating
          ? -0.28 * dtMinutes
          : math.sin(waveAngle * 1.3) * 0.18 * dtMinutes;
      final nextDbz = (cell.peakIntensityDbz + dbzDelta).clamp(18.0, 64.0);
      final nextPrecip = _dbzToRainRate(nextDbz);
      final nextDissipating =
          cell.isDissipating ? nextDbz > 22.0 : nextDbz > 59.0;

      return cell.copyWith(
        centerXKm: nextX,
        centerYKm: nextY,
        peakIntensityDbz: nextDbz,
        precipitationMmPerHour: nextPrecip,
        isDissipating: nextDissipating,
      );
    }).toList(growable: false);
  }

  /// Interpoluje punkt na trasie dla zadanego kilometra [routeKm].
  RadarRoutePoint interpolateRoutePoint(
    List<RadarRoutePoint> routePoints,
    double routeKm,
  ) {
    if (routePoints.isEmpty) {
      return const RadarRoutePoint(
        routeKm: 0.0,
        xKm: 0.0,
        yKm: 0.0,
        elevationM: 500.0,
        roadBearingDegrees: 90.0,
      );
    }
    if (routeKm <= routePoints.first.routeKm) return routePoints.first;
    if (routeKm >= routePoints.last.routeKm) return routePoints.last;

    for (int i = 0; i < routePoints.length - 1; i++) {
      final a = routePoints[i];
      final b = routePoints[i + 1];
      if (routeKm >= a.routeKm && routeKm <= b.routeKm) {
        final span = b.routeKm - a.routeKm;
        final t = span <= 1e-6 ? 0.0 : (routeKm - a.routeKm) / span;
        return RadarRoutePoint(
          routeKm: routeKm,
          xKm: a.xKm + (b.xKm - a.xKm) * t,
          yKm: a.yKm + (b.yKm - a.yKm) * t,
          elevationM: a.elevationM + (b.elevationM - a.elevationM) * t,
          roadBearingDegrees: a.roadBearingDegrees,
        );
      }
    }
    return routePoints.last;
  }

  /// Wylicza odbiciowość radaru [dBZ] w dowolnym punkcie (xKm, yKm).
  double evaluateDbzAtCoordinates(
    double xKm,
    double yKm,
    List<StormFrontCell> cells,
  ) {
    double maxDbz = 0.0;
    double combinedEnergy = 0.0;

    for (final cell in cells) {
      if (cell.radiusKm <= 0.1) continue;
      final dx = xKm - cell.centerXKm;
      final dy = yKm - cell.centerYKm;
      final rad = cell.orientationDeg * math.pi / 180.0;
      final cosA = math.cos(rad);
      final sinA = math.sin(rad);

      // Rzut na osie elipsy frontu burzowego.
      final localX = dx * cosA + dy * sinA;
      final localY = -dx * sinA + dy * cosA;
      final majorR = cell.radiusKm * cell.elongationRatio;
      final minorR = cell.radiusKm;

      final normDistSq =
          (localX * localX) / (majorR * majorR) + (localY * localY) / (minorR * minorR);
      if (normDistSq >= 3.2) continue;

      final attenuation = math.exp(-normDistSq * 1.15);
      final cellDbz = cell.peakIntensityDbz * attenuation;
      if (cellDbz > maxDbz) {
        maxDbz = cellDbz;
      }
      combinedEnergy += attenuation * (cell.peakIntensityDbz / 60.0);
    }

    if (maxDbz <= 4.0) return 0.0;
    return (maxDbz + math.min(6.0, combinedEnergy * 2.5)).clamp(0.0, 66.0);
  }

  /// Ocenia szczegółowy wpływ pogody w punkcie [routeKm] w przyszłości [forecastMinutesAhead].
  RouteWeatherImpactSample evaluateImpactAtRouteKm({
    required List<RadarRoutePoint> routePoints,
    required List<StormFrontCell> stormCells,
    required double routeKm,
    required int forecastMinutesAhead,
    required double baseTemperatureC,
    required double baseWindKmh,
    required double baseWindDirectionDeg,
  }) {
    final projectedCells = forecastMinutesAhead <= 0
        ? stormCells
        : advanceStormCells(stormCells, forecastMinutesAhead.toDouble());
    final pt = interpolateRoutePoint(routePoints, routeKm);

    double totalPrecip = 0.0;
    double maxDbz = 0.0;
    double peakGust = baseWindKmh;
    double windDir = baseWindDirectionDeg;
    double tempDrop = 0.0;
    double maxLightning = 0.0;
    final activeIds = <String>[];

    for (final cell in projectedCells) {
      final dbzAtPt = evaluateDbzAtCoordinates(pt.xKm, pt.yKm, [cell]);
      if (dbzAtPt >= 14.0) {
        activeIds.add(cell.id);
        final ratio = (dbzAtPt / math.max(1.0, cell.peakIntensityDbz)).clamp(0.0, 1.0);
        if (dbzAtPt > maxDbz) maxDbz = dbzAtPt;
        totalPrecip += cell.precipitationMmPerHour * ratio;
        final cellWind = baseWindKmh + (cell.windGustKmh - baseWindKmh) * ratio;
        if (cellWind > peakGust) {
          peakGust = cellWind;
          windDir = cell.windDirectionDeg;
        }
        tempDrop = math.max(tempDrop, cell.temperatureDropC * ratio);
        maxLightning = math.max(maxLightning, cell.lightningRisk * ratio);
      }
    }

    final intensity = _classifyDbz(maxDbz);
    final windAngleRad = (windDir - pt.roadBearingDegrees) * math.pi / 180.0;
    final crosswind = (peakGust * math.sin(windAngleRad)).abs();

    // Wpływ wysokości n.p.m. na temperaturę (-0.65°C na każde 100 m powyżej 500 m).
    final altitudeCooling = math.max(0.0, (pt.elevationM - 500.0) / 100.0) * 0.65;
    final localTemp = (baseTemperatureC - altitudeCooling - tempDrop).clamp(-4.0, 42.0);

    final grip = switch (intensity) {
      RadarPrecipitationIntensity.none => 1.0,
      RadarPrecipitationIntensity.lightShower => 0.84,
      RadarPrecipitationIntensity.moderateRain => 0.71,
      RadarPrecipitationIntensity.heavyDownpour => 0.58,
      RadarPrecipitationIntensity.torrentialHail => 0.48,
    };

    final crrMult = switch (intensity) {
      RadarPrecipitationIntensity.none => 1.0,
      RadarPrecipitationIntensity.lightShower => 1.04,
      RadarPrecipitationIntensity.moderateRain => 1.08,
      RadarPrecipitationIntensity.heavyDownpour => 1.14,
      RadarPrecipitationIntensity.torrentialHail => 1.22,
    };

    final visibility = switch (intensity) {
      RadarPrecipitationIntensity.none => 9500.0,
      RadarPrecipitationIntensity.lightShower => 4200.0,
      RadarPrecipitationIntensity.moderateRain => 1800.0,
      RadarPrecipitationIntensity.heavyDownpour => 650.0,
      RadarPrecipitationIntensity.torrentialHail => 280.0,
    };

    return RouteWeatherImpactSample(
      routeKm: routeKm,
      forecastMinutesAhead: forecastMinutesAhead,
      intensity: intensity,
      dbz: maxDbz,
      precipitationMmPerHour: totalPrecip,
      windSpeedKmh: peakGust,
      windDirectionDeg: windDir,
      crosswindComponentKmh: crosswind,
      temperatureC: localTemp,
      asphaltGripMultiplier: grip,
      crrPenaltyMultiplier: crrMult,
      visibilityMeters: visibility,
      lightningRisk: maxLightning,
      activeFrontIds: activeIds,
    );
  }

  /// Wylicza pełną oś czasu prognozy przesuwania się frontów dla 4 horyzontów.
  List<WeatherShiftForecastTimelineEntry> computeForecastTimeline({
    required List<RadarRoutePoint> routePoints,
    required List<StormFrontCell> stormCells,
    required double pelotonKm,
    required double pelotonSpeedKmh,
    required double baseTemperatureC,
    required double baseWindKmh,
    required double baseWindDirectionDeg,
  }) {
    final totalKm = routePoints.isNotEmpty ? routePoints.last.routeKm : 160.0;
    const horizons = <int>[0, 15, 30, 60];
    final entries = <WeatherShiftForecastTimelineEntry>[];

    for (final mins in horizons) {
      final projectedKm =
          (pelotonKm + pelotonSpeedKmh * (mins / 60.0)).clamp(0.0, totalKm);
      final impactAtPeloton = evaluateImpactAtRouteKm(
        routePoints: routePoints,
        stormCells: stormCells,
        routeKm: projectedKm,
        forecastMinutesAhead: mins,
        baseTemperatureC: baseTemperatureC,
        baseWindKmh: baseWindKmh,
        baseWindDirectionDeg: baseWindDirectionDeg,
      );

      // Skanowanie trasy w poszukiwaniu maksymalnego rdzenia burzowego w horyzoncie [mins].
      double peakDbz = 0.0;
      double? peakKm;
      for (final rp in routePoints) {
        final s = evaluateImpactAtRouteKm(
          routePoints: routePoints,
          stormCells: stormCells,
          routeKm: rp.routeKm,
          forecastMinutesAhead: mins,
          baseTemperatureC: baseTemperatureC,
          baseWindKmh: baseWindKmh,
          baseWindDirectionDeg: baseWindDirectionDeg,
        );
        if (s.dbz > peakDbz) {
          peakDbz = s.dbz;
          peakKm = rp.routeKm;
        }
      }

      final alertLevel = _classifyHorizonAlert(
        minutesAhead: mins,
        pelotonImpact: impactAtPeloton,
        peakRouteDbz: peakDbz,
      );

      final tactic = _buildTacticalAdvice(
        impact: impactAtPeloton,
        alertLevel: alertLevel,
        minutesAhead: mins,
      );

      entries.add(
        WeatherShiftForecastTimelineEntry(
          minutesAhead: mins,
          pelotonProjectedKm: projectedKm,
          impactAtPeloton: impactAtPeloton,
          frontPeakKmOnRoute: peakKm,
          peakRouteDbz: peakDbz,
          alertLevel: alertLevel,
          recommendedTacticPl: tactic,
        ),
      );
    }

    return entries;
  }

  /// Wykrywa istotną zmianę prognozy względem poprzedniego kroku symulacji.
  ForecastShiftAlertEvent? detectForecastShiftEvent(
    WeatherRadarLiveState previous,
    WeatherRadarLiveState current,
  ) {
    final prevNow = previous.timelineForecast.isNotEmpty
        ? previous.timelineForecast.first
        : null;
    final currNow = current.timelineForecast.isNotEmpty
        ? current.timelineForecast.first
        : null;
    if (prevNow == null || currNow == null) return null;

    final levelChanged = previous.alertLevel != current.alertLevel;
    final dbzJump = currNow.impactAtPeloton.dbz - prevNow.impactAtPeloton.dbz;
    final windJump = currNow.impactAtPeloton.crosswindComponentKmh -
        prevNow.impactAtPeloton.crosswindComponentKmh;

    if (!levelChanged && dbzJump.abs() < 12.0 && windJump.abs() < 14.0) {
      return null;
    }

    final headline = levelChanged
        ? 'Zmiana statusu pogody: ${current.alertLevel.labelPl}'
        : (dbzJump >= 12.0
            ? 'Gwałtowne nasilenie opadów (+${dbzJump.round()} dBZ)'
            : 'Nagły podmuch wiatru bocznego (${currNow.impactAtPeloton.crosswindComponentKmh.round()} km/h)');

    return ForecastShiftAlertEvent(
      raceTimeMinutes: current.raceTimeMinutes,
      previousLevel: previous.alertLevel,
      newLevel: current.alertLevel,
      deltaDbz: dbzJump,
      deltaCrosswindKmh: windJump,
      headlinePl: headline,
      tacticalAdvicePl: currNow.recommendedTacticPl,
    );
  }

  RadarPrecipitationIntensity _classifyDbz(double dbz) {
    if (dbz < 14.0) return RadarPrecipitationIntensity.none;
    if (dbz < 30.0) return RadarPrecipitationIntensity.lightShower;
    if (dbz < 42.0) return RadarPrecipitationIntensity.moderateRain;
    if (dbz < 53.0) return RadarPrecipitationIntensity.heavyDownpour;
    return RadarPrecipitationIntensity.torrentialHail;
  }

  double _dbzToRainRate(double dbz) {
    if (dbz < 14.0) return 0.0;
    // Zależność Marshalla-Palmera Z = 200 * R^1.6
    final z = math.pow(10.0, dbz / 10.0);
    return math.pow(z / 200.0, 1.0 / 1.6).toDouble().clamp(0.2, 65.0);
  }

  WeatherShiftAlertLevel _classifyHorizonAlert({
    required int minutesAhead,
    required RouteWeatherImpactSample pelotonImpact,
    required double peakRouteDbz,
  }) {
    if (pelotonImpact.intensity == RadarPrecipitationIntensity.heavyDownpour ||
        pelotonImpact.intensity == RadarPrecipitationIntensity.torrentialHail ||
        pelotonImpact.crosswindComponentKmh >= 38.0) {
      return minutesAhead == 0
          ? WeatherShiftAlertLevel.activeImpact
          : WeatherShiftAlertLevel.imminent;
    }
    if (pelotonImpact.intensity == RadarPrecipitationIntensity.moderateRain ||
        pelotonImpact.intensity == RadarPrecipitationIntensity.lightShower) {
      return minutesAhead <= 15
          ? WeatherShiftAlertLevel.imminent
          : WeatherShiftAlertLevel.approaching;
    }
    if (peakRouteDbz >= 36.0) {
      return WeatherShiftAlertLevel.approaching;
    }
    return WeatherShiftAlertLevel.clear;
  }

  WeatherShiftAlertLevel _resolveOverallAlertLevel(
    List<WeatherShiftForecastTimelineEntry> timeline,
  ) {
    if (timeline.isEmpty) return WeatherShiftAlertLevel.clear;
    final nowEntry = timeline.first;
    if (nowEntry.alertLevel == WeatherShiftAlertLevel.activeImpact) {
      return WeatherShiftAlertLevel.activeImpact;
    }
    for (final entry in timeline) {
      if (entry.minutesAhead <= 15 &&
          (entry.alertLevel == WeatherShiftAlertLevel.imminent ||
              entry.alertLevel == WeatherShiftAlertLevel.activeImpact)) {
        return WeatherShiftAlertLevel.imminent;
      }
    }
    for (final entry in timeline) {
      if (entry.alertLevel == WeatherShiftAlertLevel.approaching ||
          entry.alertLevel == WeatherShiftAlertLevel.imminent) {
        return WeatherShiftAlertLevel.approaching;
      }
    }
    return WeatherShiftAlertLevel.clear;
  }

  String _buildTacticalAdvice({
    required RouteWeatherImpactSample impact,
    required WeatherShiftAlertLevel alertLevel,
    required int minutesAhead,
  }) {
    if (impact.intensity == RadarPrecipitationIntensity.torrentialHail) {
      return 'Alarm gradobicia! Schowaj liderów w głębi grupy, nakaz ostrożnych zjazdów.';
    }
    if (impact.intensity == RadarPrecipitationIntensity.heavyDownpour) {
      return 'Ulewa na trasie: załóż peleryny przeciwdeszczowe i pilnuj pozycji przed zakrętami.';
    }
    if (impact.crosswindComponentKmh >= 34.0) {
      return 'Silny wiatr boczny (${impact.crosswindComponentKmh.round()} km/h): sformuj wachlarz na czole peletonu!';
    }
    if (impact.intensity == RadarPrecipitationIntensity.moderateRain ||
        impact.intensity == RadarPrecipitationIntensity.lightShower) {
      return 'Mokry asfalt (przyczepność ${(impact.asphaltGripMultiplier * 100).round()}%): wydłuż dystans hamowania.';
    }
    if (alertLevel == WeatherShiftAlertLevel.approaching) {
      return 'Front zbliża się za ${minutesAhead == 0 ? 15 : minutesAhead} min. Przygotuj peleryny w wozie technicznym.';
    }
    return 'Czyste okno pogodowe. Utrzymuj standardowe ciśnienie i tempo drużyny.';
  }
}

/// Kontroler stanu Riverpod dla radaru frontów burzowych na żywo.
class WeatherRadarLiveNotifier extends StateNotifier<WeatherRadarLiveState> {
  final WeatherRadarLiveForecastShiftEngine _engine;

  WeatherRadarLiveNotifier({
    WeatherRadarLiveForecastShiftEngine? engine,
    WeatherRadarLiveState? initialState,
  })  : _engine = engine ?? const WeatherRadarLiveForecastShiftEngine(),
        super(
          initialState ??
              (engine ?? const WeatherRadarLiveForecastShiftEngine())
                  .createDemoAlpineStormScenario(),
        );

  /// Przesuwa symulację radaru o [dtMinutes] (uwzględniając mnożnik prędkości).
  void tick(double dtMinutes) {
    if (state.isPaused || dtMinutes <= 0.0) return;
    final scaledDt = dtMinutes * state.playbackSpeedMultiplier;
    final nextCells = _engine.advanceStormCells(
      state.stormCells,
      scaledDt,
      raceTimeMinutes: state.raceTimeMinutes + scaledDt,
    );
    final nextPelotonKm = math.min(
      state.stageDistanceKm,
      state.pelotonKm + state.pelotonSpeedKmh * (scaledDt / 60.0),
    );
    final nextBreakawayKm = math.min(
      state.stageDistanceKm,
      state.breakawayKm + (state.pelotonSpeedKmh + 1.2) * (scaledDt / 60.0),
    );

    final nextTimeline = _engine.computeForecastTimeline(
      routePoints: state.routePoints,
      stormCells: nextCells,
      pelotonKm: nextPelotonKm,
      pelotonSpeedKmh: state.pelotonSpeedKmh,
      baseTemperatureC: state.baseTemperatureC,
      baseWindKmh: state.baseWindKmh,
      baseWindDirectionDeg: state.baseWindDirectionDeg,
    );

    final nextAlert = _engine._resolveOverallAlertLevel(nextTimeline);
    final candidateState = state.copyWith(
      raceTimeMinutes: state.raceTimeMinutes + scaledDt,
      pelotonKm: nextPelotonKm,
      breakawayKm: nextBreakawayKm,
      stormCells: nextCells,
      timelineForecast: nextTimeline,
      alertLevel: nextAlert,
    );

    final shiftEvent = _engine.detectForecastShiftEvent(state, candidateState);
    state = shiftEvent == null
        ? candidateState
        : candidateState.copyWith(
            lastShiftMessagePl:
                '${shiftEvent.headlinePl} — ${shiftEvent.tacticalAdvicePl}',
          );
  }

  /// Aktualizuje pozycję peletonu i ucieczki z głównej symulacji wyścigu.
  void syncRacePositions({
    required double pelotonKm,
    required double breakawayKm,
    required double pelotonSpeedKmh,
  }) {
    final clampedPeloton = pelotonKm.clamp(0.0, state.stageDistanceKm);
    final clampedBreak = breakawayKm.clamp(0.0, state.stageDistanceKm);
    final nextTimeline = _engine.computeForecastTimeline(
      routePoints: state.routePoints,
      stormCells: state.stormCells,
      pelotonKm: clampedPeloton,
      pelotonSpeedKmh: pelotonSpeedKmh,
      baseTemperatureC: state.baseTemperatureC,
      baseWindKmh: state.baseWindKmh,
      baseWindDirectionDeg: state.baseWindDirectionDeg,
    );
    state = state.copyWith(
      pelotonKm: clampedPeloton,
      breakawayKm: clampedBreak,
      pelotonSpeedKmh: pelotonSpeedKmh,
      timelineForecast: nextTimeline,
      alertLevel: _engine._resolveOverallAlertLevel(nextTimeline),
    );
  }

  void selectHorizon(RadarForecastHorizon horizon) {
    state = state.copyWith(selectedHorizon: horizon);
  }

  void selectStormCell(String? cellId) {
    if (cellId == null || state.selectedCellId == cellId) {
      state = state.copyWith(clearSelectedCell: true);
    } else {
      state = state.copyWith(selectedCellId: cellId);
    }
  }

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }

  void setPlaybackSpeed(double speed) {
    state = state.copyWith(playbackSpeedMultiplier: speed.clamp(0.5, 8.0));
  }

  void toggleAutoSweep() {
    state = state.copyWith(autoSweepEnabled: !state.autoSweepEnabled);
  }

  /// Wyzwala gwałtowne przesunięcie frontu burzowego prosto nad trasę peletonu.
  void triggerSuddenFrontShift() {
    if (state.stormCells.isEmpty) return;
    final pelotonPt = _engine.interpolateRoutePoint(
      state.routePoints,
      math.min(state.stageDistanceKm, state.pelotonKm + 7.5),
    );

    final primary = state.stormCells.first.copyWith(
      centerXKm: pelotonPt.xKm - 4.0,
      centerYKm: pelotonPt.yKm + 3.0,
      velocityXKmPerHour: 44.0,
      velocityYKmPerHour: -28.0,
      peakIntensityDbz: 57.5,
      precipitationMmPerHour: 29.0,
      windGustKmh: 62.0,
      lightningRisk: 0.85,
      hailProbability: 0.34,
      isDissipating: false,
    );

    final updatedCells = <StormFrontCell>[
      primary,
      ...state.stormCells.skip(1),
    ];

    final nextTimeline = _engine.computeForecastTimeline(
      routePoints: state.routePoints,
      stormCells: updatedCells,
      pelotonKm: state.pelotonKm,
      pelotonSpeedKmh: state.pelotonSpeedKmh,
      baseTemperatureC: state.baseTemperatureC,
      baseWindKmh: state.baseWindKmh,
      baseWindDirectionDeg: state.baseWindDirectionDeg,
    );

    state = state.copyWith(
      stormCells: updatedCells,
      timelineForecast: nextTimeline,
      alertLevel: _engine._resolveOverallAlertLevel(nextTimeline),
      selectedCellId: primary.id,
      lastShiftMessagePl:
          'PILNE PRZESUNIĘCIE FRONTU: Superkomórka skręciła nad km ${pelotonPt.routeKm.round()} (wiatr ${primary.windGustKmh.round()} km/h)!',
    );
  }

  void resetScenario() {
    state = _engine.createDemoAlpineStormScenario();
  }

  void loadStage(RaceStage stage) {
    state = _engine.createStateFromStage(stage);
  }
}

final weatherRadarLiveProvider = StateNotifierProvider.autoDispose<
    WeatherRadarLiveNotifier, WeatherRadarLiveState>(
  (ref) => WeatherRadarLiveNotifier(),
);

/// Interaktywny panel radaru meteorologicznego w czasie rzeczywistym.
class WeatherRadarLiveForecastPanel extends ConsumerStatefulWidget {
  final bool enableLiveSimulation;
  final ValueChanged<ForecastShiftAlertEvent>? onForecastShiftAlert;

  const WeatherRadarLiveForecastPanel({
    super.key,
    this.enableLiveSimulation = true,
    this.onForecastShiftAlert,
  });

  @override
  ConsumerState<WeatherRadarLiveForecastPanel> createState() =>
      _WeatherRadarLiveForecastPanelState();
}

class _WeatherRadarLiveForecastPanelState
    extends ConsumerState<WeatherRadarLiveForecastPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweepController;
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    if (widget.enableLiveSimulation) {
      _simulationTimer = Timer.periodic(
        const Duration(milliseconds: 500),
        (_) {
          if (!mounted) return;
          ref.read(weatherRadarLiveProvider.notifier).tick(0.45);
        },
      );
    }
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weatherRadarLiveProvider);
    final notifier = ref.read(weatherRadarLiveProvider.notifier);
    const engine = WeatherRadarLiveForecastShiftEngine();

    if (state.autoSweepEnabled && !state.isPaused) {
      if (!_sweepController.isAnimating) {
        _sweepController.repeat();
      }
    } else if (_sweepController.isAnimating) {
      _sweepController.stop(canceled: false);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 820;
          final isCompact = constraints.maxWidth < 460;
          final padding = isCompact ? 12.0 : 18.0;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(state, notifier, isCompact),
                const SizedBox(height: 12),
                _buildRadioAlertBanner(state),
                const SizedBox(height: 14),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildRadarCanvasCard(
                          state: state,
                          notifier: notifier,
                          engine: engine,
                          radarHeight: 380,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: _buildTelemetryAndTimelineColumn(
                          state: state,
                          notifier: notifier,
                          isCompact: false,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildRadarCanvasCard(
                    state: state,
                    notifier: notifier,
                    engine: engine,
                    radarHeight: isCompact ? 270 : 320,
                  ),
                  const SizedBox(height: 14),
                  _buildTelemetryAndTimelineColumn(
                    state: state,
                    notifier: notifier,
                    isCompact: isCompact,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    WeatherRadarLiveState state,
    WeatherRadarLiveNotifier notifier,
    bool isCompact,
  ) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: state.alertLevel.badgeColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: state.alertLevel.badgeColor.withValues(alpha: 0.65),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: state.alertLevel.badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            state.alertLevel.labelPl,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: state.alertLevel.badgeColor,
            ),
          ),
        ],
      ),
    );

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.radar_rounded,
                  size: 20,
                  color: AppColors.cyanAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  'RADAR BURZOWY LIVE',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${state.stageName}  •  km ${state.pelotonKm.toStringAsFixed(1)} / ${state.stageDistanceKm.toStringAsFixed(0)}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            badge,
            _RadarActionButton(
              icon: state.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              label: state.isPaused ? 'Wznów' : 'Pauza',
              isActive: !state.isPaused,
              onPressed: notifier.togglePause,
            ),
            _RadarActionButton(
              icon: Icons.bolt_rounded,
              label: 'Przesuń front',
              accentColor: AppColors.primaryAccent,
              onPressed: notifier.triggerSuddenFrontShift,
            ),
            _RadarActionButton(
              icon: Icons.refresh_rounded,
              label: 'Reset',
              onPressed: notifier.resetScenario,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRadioAlertBanner(WeatherRadarLiveState state) {
    final borderColor = state.alertLevel.badgeColor.withValues(alpha: 0.45);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.campaign_rounded,
            size: 18,
            color: state.alertLevel.badgeColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              state.lastShiftMessagePl,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarCanvasCard({
    required WeatherRadarLiveState state,
    required WeatherRadarLiveNotifier notifier,
    required WeatherRadarLiveForecastShiftEngine engine,
    required double radarHeight,
  }) {
    final horizonMinutes = state.selectedHorizon.minutesAhead;
    final displayCells = horizonMinutes == 0
        ? state.stormCells
        : engine.advanceStormCells(
            state.stormCells,
            horizonMinutes.toDouble(),
            raceTimeMinutes: state.raceTimeMinutes + horizonMinutes,
          );
    final projectedPelotonKm = math.min(
      state.stageDistanceKm,
      state.pelotonKm + state.pelotonSpeedKmh * (horizonMinutes / 60.0),
    );
    final projectedBreakawayKm = math.min(
      state.stageDistanceKm,
      state.breakawayKm + (state.pelotonSpeedKmh + 1.2) * (horizonMinutes / 60.0),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: RadarForecastHorizon.values.map((horizon) {
                  return _HorizonChip(
                    label: horizon.labelPl,
                    selected: state.selectedHorizon == horizon,
                    onTap: () => notifier.selectHorizon(horizon),
                  );
                }).toList(growable: false),
              ),
              _HorizonChip(
                label: state.autoSweepEnabled ? 'Skan: ON' : 'Skan: OFF',
                selected: state.autoSweepEnabled,
                onTap: notifier.toggleAutoSweep,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: radarHeight,
              child: LayoutBuilder(
                builder: (context, box) {
                  return GestureDetector(
                    onTapUp: (details) {
                      _handleRadarTap(
                        localPos: details.localPosition,
                        size: Size(box.maxWidth, radarHeight),
                        cells: displayCells,
                        notifier: notifier,
                      );
                    },
                    child: AnimatedBuilder(
                      animation: _sweepController,
                      builder: (context, _) {
                        return CustomPaint(
                          size: Size(box.maxWidth, radarHeight),
                          painter: _WeatherRadarScopePainter(
                            routePoints: state.routePoints,
                            stormCells: displayCells,
                            selectedCellId: state.selectedCellId,
                            pelotonPoint: engine.interpolateRoutePoint(
                              state.routePoints,
                              projectedPelotonKm,
                            ),
                            breakawayPoint: engine.interpolateRoutePoint(
                              state.routePoints,
                              projectedBreakawayKm,
                            ),
                            sweepAngleRad: state.autoSweepEnabled
                                ? _sweepController.value * math.pi * 2.0
                                : 0.6,
                            showSweep: state.autoSweepEnabled,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildLegendRow(),
        ],
      ),
    );
  }

  void _handleRadarTap({
    required Offset localPos,
    required Size size,
    required List<StormFrontCell> cells,
    required WeatherRadarLiveNotifier notifier,
  }) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radarRadiusPx = math.min(size.width, size.height) * 0.44;
    const radarRangeKm = 65.0;

    String? hitId;
    double bestDist = 28.0;
    for (final cell in cells) {
      final px = center.dx + (cell.centerXKm / radarRangeKm) * radarRadiusPx;
      final py = center.dy - (cell.centerYKm / radarRangeKm) * radarRadiusPx;
      final dist = (localPos - Offset(px, py)).distance;
      if (dist < bestDist) {
        bestDist = dist;
        hitId = cell.id;
      }
    }
    notifier.selectStormCell(hitId);
  }

  Widget _buildLegendRow() {
    return const Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _LegendDot(color: AppColors.goldAccent, label: 'Peleton'),
        _LegendDot(color: AppColors.cyanAccent, label: 'Ucieczka'),
        _LegendDot(color: AppColors.statusSuccess, label: 'Lekki deszcz'),
        _LegendDot(color: AppColors.accentBlue, label: 'Umiarkowany'),
        _LegendDot(color: AppColors.amberWarning, label: 'Ulewa'),
        _LegendDot(color: AppColors.crimsonAlert, label: 'Grad / Szkwał'),
      ],
    );
  }

  Widget _buildTelemetryAndTimelineColumn({
    required WeatherRadarLiveState state,
    required WeatherRadarLiveNotifier notifier,
    required bool isCompact,
  }) {
    final activeEntry = state.activeHorizonEntry;
    final impact = activeEntry?.impactAtPeloton;
    final selectedCell = state.selectedCell;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (impact != null) _buildPelotonImpactMetrics(impact, state.selectedHorizon),
        const SizedBox(height: 12),
        if (selectedCell != null) ...[
          _buildSelectedCellInspector(selectedCell, notifier),
          const SizedBox(height: 12),
        ],
        _buildTimelineForecastCard(state, notifier),
        const SizedBox(height: 12),
        _buildPlaybackSpeedBar(state, notifier, isCompact),
      ],
    );
  }

  Widget _buildPelotonImpactMetrics(
    RouteWeatherImpactSample impact,
    RadarForecastHorizon horizon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'WARUNKI NA POZYCJI PELETONU (${horizon.labelPl.toUpperCase()})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                impact.intensity.labelPl,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: impact.intensity.radarColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricTile(
                label: 'Opady',
                value: '${impact.precipitationMmPerHour.toStringAsFixed(1)} mm/h',
                valueColor: impact.intensity.radarColor,
              ),
              _MetricTile(
                label: 'Wiatr boczny',
                value: '${impact.crosswindComponentKmh.toStringAsFixed(0)} km/h',
                valueColor: impact.crosswindComponentKmh >= 32.0
                    ? AppColors.amberWarning
                    : AppColors.textPrimary,
              ),
              _MetricTile(
                label: 'Przyczepność',
                value: '${(impact.asphaltGripMultiplier * 100).round()}%',
                valueColor: impact.asphaltGripMultiplier < 0.70
                    ? AppColors.crimsonAlert
                    : AppColors.statusSuccess,
              ),
              _MetricTile(
                label: 'Temp.',
                value: '${impact.temperatureC.toStringAsFixed(1)}°C',
                valueColor: AppColors.accentBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCellInspector(
    StormFrontCell cell,
    WeatherRadarLiveNotifier notifier,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  cell.frontType.shortTag,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cell.name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => notifier.selectStormCell(null),
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.textSecondary,
                tooltip: 'Zamknij inspekcję komórki',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Prędkość frontu: ${cell.speedKmPerHour.toStringAsFixed(0)} km/h  •  '
            'Rdzeń: ${cell.peakIntensityDbz.toStringAsFixed(0)} dBZ  •  '
            'Porywy: ${cell.windGustKmh.toStringAsFixed(0)} km/h  •  '
            'Grad: ${(cell.hailProbability * 100).round()}%',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineForecastCard(
    WeatherRadarLiveState state,
    WeatherRadarLiveNotifier notifier,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROGNOZA PRZESUNIĘCIA FRONTÓW',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ...state.timelineForecast.map((entry) {
            final horizon = RadarForecastHorizon.values.firstWhere(
              (h) => h.minutesAhead == entry.minutesAhead,
              orElse: () => RadarForecastHorizon.now,
            );
            final isSelected = state.selectedHorizon == horizon;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => notifier.selectHorizon(horizon),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.surfaceLight
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.goldAccent
                          : AppColors.cardBorder,
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                horizon.labelPl,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'km ${entry.pelotonProjectedKm.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            entry.alertLevel.labelPl,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: entry.alertLevel.badgeColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.recommendedTacticPl,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPlaybackSpeedBar(
    WeatherRadarLiveState state,
    WeatherRadarLiveNotifier notifier,
    bool isCompact,
  ) {
    const speeds = <double>[1.0, 2.0, 5.0];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Czas wyścigu: ${state.raceTimeMinutes.toStringAsFixed(0)} min',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isCompact ? 11.5 : 12.5,
            color: AppColors.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Wrap(
          spacing: 6,
          children: speeds.map((s) {
            final active = (state.playbackSpeedMultiplier - s).abs() < 0.05;
            return _HorizonChip(
              label: '${s.toStringAsFixed(0)}x',
              selected: active,
              onTap: () => notifier.setPlaybackSpeed(s),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}

class _RadarActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isActive;
  final Color? accentColor;

  const _RadarActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
    this.accentColor,
  });

  @override
  State<_RadarActionButton> createState() => _RadarActionButtonState();
}

class _RadarActionButtonState extends State<_RadarActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final baseAccent = widget.accentColor ?? AppColors.goldAccent;
    final bgColor = disabled
        ? AppColors.surface
        : _pressed
            ? baseAccent.withValues(alpha: 0.28)
            : widget.isActive
                ? baseAccent.withValues(alpha: 0.16)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background;
    final borderColor = disabled
        ? AppColors.cardBorder.withValues(alpha: 0.45)
        : (_focused || widget.isActive || _hovered)
            ? baseAccent
            : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: disabled
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : AppColors.textPrimary,
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: disabled
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
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

class _HorizonChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _HorizonChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_HorizonChip> createState() => _HorizonChipState();
}

class _HorizonChipState extends State<_HorizonChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.primaryAccent.withValues(alpha: 0.28)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: widget.selected
                  ? AppColors.goldAccent
                  : (_focused || _hovered)
                      ? AppColors.textSecondary
                      : AppColors.cardBorder,
              width: 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: disabled
                  ? AppColors.textSecondary.withValues(alpha: 0.45)
                  : widget.selected
                      ? AppColors.goldAccent
                      : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// CustomPainter rysujący dopplerowski radar frontów burzowych, trasę oraz peleton.
class _WeatherRadarScopePainter extends CustomPainter {
  final List<RadarRoutePoint> routePoints;
  final List<StormFrontCell> stormCells;
  final String? selectedCellId;
  final RadarRoutePoint pelotonPoint;
  final RadarRoutePoint breakawayPoint;
  final double sweepAngleRad;
  final bool showSweep;

  static const double _rangeKm = 65.0;

  const _WeatherRadarScopePainter({
    required this.routePoints,
    required this.stormCells,
    required this.selectedCellId,
    required this.pelotonPoint,
    required this.breakawayPoint,
    required this.sweepAngleRad,
    required this.showSweep,
  });

  Offset _toCanvas(double xKm, double yKm, Offset center, double radiusPx) {
    return Offset(
      center.dx + (xKm / _rangeKm) * radiusPx,
      center.dy - (yKm / _rangeKm) * radiusPx,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radiusPx = math.min(size.width, size.height) * 0.44;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0B0E14),
    );

    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Pierścienie zasięgu 20 / 40 / 65 km.
    for (final ringKm in const [20.0, 40.0, 65.0]) {
      final r = (ringKm / _rangeKm) * radiusPx;
      canvas.drawCircle(center, r, gridPaint);
    }

    // Krzyż kompasu N-S / E-W.
    canvas.drawLine(
      Offset(center.dx - radiusPx, center.dy),
      Offset(center.dx + radiusPx, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radiusPx),
      Offset(center.dx, center.dy + radiusPx),
      gridPaint,
    );

    // Komórki burzowe jako wielowarstwowe elipsy refleksyjności Dopplera.
    for (final cell in stormCells) {
      final pos = _toCanvas(cell.centerXKm, cell.centerYKm, center, radiusPx);
      final rx = (cell.radiusKm * cell.elongationRatio / _rangeKm) * radiusPx;
      final ry = (cell.radiusKm / _rangeKm) * radiusPx;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(-cell.orientationDeg * math.pi / 180.0);

      final outerColor = cell.peakIntensityDbz >= 48.0
          ? AppColors.amberWarning.withValues(alpha: 0.24)
          : AppColors.statusSuccess.withValues(alpha: 0.22);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2.0, height: ry * 2.0),
        Paint()..color = outerColor,
      );

      final midColor = cell.peakIntensityDbz >= 45.0
          ? AppColors.amberWarning.withValues(alpha: 0.36)
          : AppColors.accentBlue.withValues(alpha: 0.30);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 1.35, height: ry * 1.35),
        Paint()..color = midColor,
      );

      if (cell.peakIntensityDbz >= 45.0) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: rx * 0.72, height: ry * 0.72),
          Paint()..color = AppColors.crimsonAlert.withValues(alpha: 0.55),
        );
      }

      if (cell.id == selectedCellId) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: rx * 2.1, height: ry * 2.1),
          Paint()
            ..color = AppColors.goldAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }
      canvas.restore();

      // Wektor kierunku przesuwania się frontu.
      final vecEnd = _toCanvas(
        cell.centerXKm + cell.velocityXKmPerHour * 0.28,
        cell.centerYKm + cell.velocityYKmPerHour * 0.28,
        center,
        radiusPx,
      );
      canvas.drawLine(
        pos,
        vecEnd,
        Paint()
          ..color = AppColors.textPrimary.withValues(alpha: 0.75)
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        vecEnd,
        2.5,
        Paint()..color = AppColors.textPrimary,
      );
    }

    // Trasa etapu.
    if (routePoints.length >= 2) {
      final path = Path();
      final first = _toCanvas(
        routePoints.first.xKm,
        routePoints.first.yKm,
        center,
        radiusPx,
      );
      path.moveTo(first.dx, first.dy);
      for (int i = 1; i < routePoints.length; i++) {
        final pt = _toCanvas(
          routePoints[i].xKm,
          routePoints[i].yKm,
          center,
          radiusPx,
        );
        path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.textPrimary.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Zamiatanie wiązki radaru.
    if (showSweep) {
      final sweepRect = Rect.fromCircle(center: center, radius: radiusPx);
      final sweepPaint = Paint()
        ..shader = SweepGradient(
          startAngle: 0.0,
          endAngle: 0.55,
          colors: [
            AppColors.cyanAccent.withValues(alpha: 0.0),
            AppColors.cyanAccent.withValues(alpha: 0.22),
          ],
          transform: GradientRotation(sweepAngleRad),
        ).createShader(sweepRect);
      canvas.drawCircle(center, radiusPx, sweepPaint);

      final beamEnd = Offset(
        center.dx + math.cos(sweepAngleRad + 0.55) * radiusPx,
        center.dy + math.sin(sweepAngleRad + 0.55) * radiusPx,
      );
      canvas.drawLine(
        center,
        beamEnd,
        Paint()
          ..color = AppColors.cyanAccent.withValues(alpha: 0.7)
          ..strokeWidth = 1.4,
      );
    }

    // Pozycja Ucieczki i Peletonu.
    final breakPos = _toCanvas(
      breakawayPoint.xKm,
      breakawayPoint.yKm,
      center,
      radiusPx,
    );
    canvas.drawCircle(
      breakPos,
      5.0,
      Paint()..color = AppColors.cyanAccent,
    );

    final pelotonPos = _toCanvas(
      pelotonPoint.xKm,
      pelotonPoint.yKm,
      center,
      radiusPx,
    );
    canvas.drawCircle(
      pelotonPos,
      8.5,
      Paint()..color = AppColors.goldAccent.withValues(alpha: 0.28),
    );
    canvas.drawCircle(
      pelotonPos,
      5.5,
      Paint()..color = AppColors.goldAccent,
    );
  }

  @override
  bool shouldRepaint(covariant _WeatherRadarScopePainter oldDelegate) {
    return oldDelegate.stormCells != stormCells ||
        oldDelegate.selectedCellId != selectedCellId ||
        oldDelegate.pelotonPoint.routeKm != pelotonPoint.routeKm ||
        oldDelegate.breakawayPoint.routeKm != breakawayPoint.routeKm ||
        oldDelegate.sweepAngleRad != sweepAngleRad ||
        oldDelegate.showSweep != showSweep;
  }
}
