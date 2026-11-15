import 'dart:math' as math;
import 'stage_segment.dart';

enum StageType {
  flat,
  hilly,
  highMountain,
  summitFinish,
  individualTimeTrial,
  teamTimeTrial,
  cobbleClassic;

  String toJson() => name;

  static StageType fromJson(String value) {
    return StageType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => StageType.flat,
    );
  }
}

enum WeatherCondition {
  sunny,
  overcast,
  lightRain,
  heavyStorm,
  crosswindGale,
  extremeHeat;

  String toJson() => name;

  static WeatherCondition fromJson(String value) {
    return WeatherCondition.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WeatherCondition.sunny,
    );
  }
}

class RaceStage {
  final String id;
  final int stageNumber;
  final String name;
  final StageType stageType;
  final List<StageSegment> segments;
  final double baseTemperatureCelsius;
  final WeatherCondition weatherCondition;
  final double windSpeedKmh;

  const RaceStage({
    required this.id,
    required this.stageNumber,
    required this.name,
    required this.stageType,
    required this.segments,
    required this.baseTemperatureCelsius,
    required this.weatherCondition,
    required this.windSpeedKmh,
  });

  /// Całkowity dystans etapu w kilometrach [km]
  double get totalDistanceKm {
    if (segments.isEmpty) return 0.0;
    double sum = 0.0;
    for (final seg in segments) {
      sum += seg.lengthKm;
    }
    return sum;
  }

  /// Aliasy dla zgodności
  double get distanceKm => totalDistanceKm;
  int get elevationGainMeters => totalElevationGainM.round();
  StageType get profile => stageType;

  /// Całkowite łączne przewyższenie na etapie w metrach (Vertical Ascent) [m]
  double get totalElevationGainM {
    double gain = 0.0;
    for (final seg in segments) {
      gain += seg.elevationGainM;
    }
    return gain;
  }

  /// Maksymalna wysokość n.p.m. osiągana na trasie etapu [m]
  double get maxElevationM {
    if (segments.isEmpty) return 0.0;
    double maxAlt = segments.first.startElevationM;
    for (final seg in segments) {
      maxAlt = math.max(maxAlt, math.max(seg.startElevationM, seg.endElevationM));
    }
    return maxAlt;
  }

  /// Minimalna wysokość n.p.m. na trasie etapu [m]
  double get minElevationM {
    if (segments.isEmpty) return 0.0;
    double minAlt = segments.first.startElevationM;
    for (final seg in segments) {
      minAlt = math.min(minAlt, math.min(seg.startElevationM, seg.endElevationM));
    }
    return minAlt;
  }

  /// Czy etap jest próbą czasową (ITT lub TTT)
  bool get isTimeTrial =>
      stageType == StageType.individualTimeTrial ||
      stageType == StageType.teamTimeTrial;

  /// Czy etap kończy się podjazdem pod górę (finałowa wspinaczka)
  bool get isSummitFinish =>
      stageType == StageType.summitFinish ||
      (segments.isNotEmpty && segments.last.gradientPercent > 4.0);

  RaceStage copyWith({
    String? id,
    int? stageNumber,
    String? name,
    StageType? stageType,
    List<StageSegment>? segments,
    double? baseTemperatureCelsius,
    WeatherCondition? weatherCondition,
    double? windSpeedKmh,
  }) {
    return RaceStage(
      id: id ?? this.id,
      stageNumber: stageNumber ?? this.stageNumber,
      name: name ?? this.name,
      stageType: stageType ?? this.stageType,
      segments: segments != null
          ? List<StageSegment>.unmodifiable(segments)
          : this.segments,
      baseTemperatureCelsius: baseTemperatureCelsius ?? this.baseTemperatureCelsius,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      windSpeedKmh: windSpeedKmh ?? this.windSpeedKmh,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stageNumber': stageNumber,
      'name': name,
      'stageType': stageType.toJson(),
      'segments': segments.map((s) => s.toJson()).toList(),
      'baseTemperatureCelsius': baseTemperatureCelsius,
      'weatherCondition': weatherCondition.toJson(),
      'windSpeedKmh': windSpeedKmh,
    };
  }

  factory RaceStage.fromJson(Map<String, dynamic> json) {
    return RaceStage(
      id: json['id'] as String,
      stageNumber: (json['stageNumber'] as num).toInt(),
      name: json['name'] as String,
      stageType: StageType.fromJson(json['stageType'] as String),
      segments: (json['segments'] as List<dynamic>?)
              ?.map((e) => StageSegment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      baseTemperatureCelsius: (json['baseTemperatureCelsius'] as num).toDouble(),
      weatherCondition: WeatherCondition.fromJson(json['weatherCondition'] as String),
      windSpeedKmh: (json['windSpeedKmh'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RaceStage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RaceStage(#$stageNumber: $name, ${stageType.name}, ${totalDistanceKm.toStringAsFixed(1)}km, +${totalElevationGainM.round()}m)';
  }
}

