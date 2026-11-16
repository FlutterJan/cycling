import 'dart:math' as math;

/// Miesiąc rozgrywania wyścigów zimowego kolarstwa przełajowego (CX).
enum CyclocrossMonth {
  november,
  december,
  january;

  String toJson() => name;

  static CyclocrossMonth fromJson(String value) {
    return CyclocrossMonth.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CyclocrossMonth.december,
    );
  }

  /// Nazwa miesiąca po polsku.
  String get displayNamePl {
    switch (this) {
      case CyclocrossMonth.november:
        return 'Listopad';
      case CyclocrossMonth.december:
        return 'Grudzień';
      case CyclocrossMonth.january:
        return 'Styczeń';
    }
  }

  /// Krótka etykieta sezonu zimowego.
  String get shortCode {
    switch (this) {
      case CyclocrossMonth.november:
        return 'NOV';
      case CyclocrossMonth.december:
        return 'DEC';
      case CyclocrossMonth.january:
        return 'JAN';
    }
  }
}

/// Typ nawierzchni lub przeszkody na rundzie przełajowej (CX).
enum CyclocrossTerrainType {
  pavedStartFinish,
  meadowGrass,
  deepMud,
  sandPit,
  offCamberSlope,
  planks,
  staircaseRunUp,
  doublePitLane,
  woodlandSingletrack;

  String toJson() => name;

  static CyclocrossTerrainType fromJson(String value) {
    return CyclocrossTerrainType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CyclocrossTerrainType.meadowGrass,
    );
  }
}

/// Stan podmokłości i lepkości błota na trasie CX.
enum CyclocrossMudCondition {
  frozenHard,
  tackyLoam,
  heavyMud,
  boggySwamp;

  String toJson() => name;

  static CyclocrossMudCondition fromJson(String value) {
    return CyclocrossMudCondition.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CyclocrossMudCondition.heavyMud,
    );
  }

  /// Mnożnik przyklejania się błota do ramy i napędu.
  double get adhesionMultiplier {
    switch (this) {
      case CyclocrossMudCondition.frozenHard:
        return 0.15;
      case CyclocrossMudCondition.tackyLoam:
        return 0.65;
      case CyclocrossMudCondition.heavyMud:
        return 1.00;
      case CyclocrossMudCondition.boggySwamp:
        return 1.35;
    }
  }
}

/// Położenie dwukierunkowego boksu technicznego względem pętli trasy.
enum CyclocrossPitLaneSide {
  left,
  right,
  centerIsland;

  String toJson() => name;

  static CyclocrossPitLaneSide fromJson(String value) {
    return CyclocrossPitLaneSide.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CyclocrossPitLaneSide.centerIsland,
    );
  }
}

/// Pojedynczy segment rundy kolarstwa przełajowego (2.5–3.2 km).
class CyclocrossCourseSegment {
  final int index;
  final double startMeter;
  final double lengthMeters;
  final CyclocrossTerrainType terrainType;
  final double gradientPercent;
  final double camberAngleDegrees;
  final double mudDepthCm;
  final double mudViscosityIndex;
  final double sandDepthCm;
  final int plankCount;
  final double plankHeightCm;
  final int stairStepCount;
  final bool isBunnyHoppable;
  final double runningSpeedPenaltyFactor;

  const CyclocrossCourseSegment({
    required this.index,
    required this.startMeter,
    required this.lengthMeters,
    required this.terrainType,
    this.gradientPercent = 0.0,
    this.camberAngleDegrees = 0.0,
    this.mudDepthCm = 0.0,
    this.mudViscosityIndex = 0.0,
    this.sandDepthCm = 0.0,
    this.plankCount = 0,
    this.plankHeightCm = 40.0,
    this.stairStepCount = 0,
    this.isBunnyHoppable = false,
    this.runningSpeedPenaltyFactor = 1.0,
  });

  /// Koniec segmentu na rundzie [m].
  double get endMeter => startMeter + lengthMeters;

  /// Czy segment wymaga zeskoku z roweru (bieg z rowerem na ramieniu).
  bool get requiresDismount {
    if (terrainType == CyclocrossTerrainType.staircaseRunUp) {
      return true;
    }
    if (terrainType == CyclocrossTerrainType.planks) {
      return !isBunnyHoppable || plankHeightCm > 40.0;
    }
    if (terrainType == CyclocrossTerrainType.deepMud && mudDepthCm >= 14.0) {
      return true;
    }
    if (terrainType == CyclocrossTerrainType.sandPit && sandDepthCm >= 18.0) {
      return true;
    }
    return false;
  }

  /// Bazowy współczynnik oporu toczenia Crr dla nawierzchni przełajowej.
  double get baseRollingResistanceCrr {
    switch (terrainType) {
      case CyclocrossTerrainType.pavedStartFinish:
        return 0.0045;
      case CyclocrossTerrainType.doublePitLane:
        return 0.0065;
      case CyclocrossTerrainType.meadowGrass:
        return 0.0155;
      case CyclocrossTerrainType.woodlandSingletrack:
        return 0.0190;
      case CyclocrossTerrainType.offCamberSlope:
        return 0.0240 + (camberAngleDegrees.clamp(0.0, 45.0) * 0.0005);
      case CyclocrossTerrainType.deepMud:
        final depthFactor = (mudDepthCm.clamp(0.0, 25.0) / 25.0) * 0.045;
        final viscosityFactor = mudViscosityIndex.clamp(0.0, 1.0) * 0.025;
        return 0.0320 + depthFactor + viscosityFactor;
      case CyclocrossTerrainType.sandPit:
        final sandFactor = (sandDepthCm.clamp(0.0, 30.0) / 30.0) * 0.055;
        return 0.0480 + sandFactor;
      case CyclocrossTerrainType.planks:
        return 0.0220;
      case CyclocrossTerrainType.staircaseRunUp:
        return 0.0350;
    }
  }

  /// Ocena trudności technicznej segmentu w skali 0–100.
  double get segmentTechnicalDifficulty {
    switch (terrainType) {
      case CyclocrossTerrainType.pavedStartFinish:
        return 5.0;
      case CyclocrossTerrainType.doublePitLane:
        return 18.0;
      case CyclocrossTerrainType.meadowGrass:
        return 25.0 + gradientPercent.abs() * 1.2;
      case CyclocrossTerrainType.woodlandSingletrack:
        return 48.0 + gradientPercent.abs() * 1.4;
      case CyclocrossTerrainType.offCamberSlope:
        return (45.0 + camberAngleDegrees * 1.35 + gradientPercent.abs() * 0.8)
            .clamp(0.0, 100.0);
      case CyclocrossTerrainType.deepMud:
        return (55.0 + mudDepthCm * 1.4 + mudViscosityIndex * 20.0)
            .clamp(0.0, 100.0);
      case CyclocrossTerrainType.sandPit:
        return (60.0 + sandDepthCm * 1.25).clamp(0.0, 100.0);
      case CyclocrossTerrainType.planks:
        return (50.0 + plankHeightCm * 0.65 + plankCount * 5.0)
            .clamp(0.0, 100.0);
      case CyclocrossTerrainType.staircaseRunUp:
        return (62.0 + stairStepCount * 0.8).clamp(0.0, 100.0);
    }
  }

  CyclocrossCourseSegment copyWith({
    int? index,
    double? startMeter,
    double? lengthMeters,
    CyclocrossTerrainType? terrainType,
    double? gradientPercent,
    double? camberAngleDegrees,
    double? mudDepthCm,
    double? mudViscosityIndex,
    double? sandDepthCm,
    int? plankCount,
    double? plankHeightCm,
    int? stairStepCount,
    bool? isBunnyHoppable,
    double? runningSpeedPenaltyFactor,
  }) {
    return CyclocrossCourseSegment(
      index: index ?? this.index,
      startMeter: startMeter ?? this.startMeter,
      lengthMeters: lengthMeters ?? this.lengthMeters,
      terrainType: terrainType ?? this.terrainType,
      gradientPercent: gradientPercent ?? this.gradientPercent,
      camberAngleDegrees: camberAngleDegrees ?? this.camberAngleDegrees,
      mudDepthCm: mudDepthCm ?? this.mudDepthCm,
      mudViscosityIndex: mudViscosityIndex ?? this.mudViscosityIndex,
      sandDepthCm: sandDepthCm ?? this.sandDepthCm,
      plankCount: plankCount ?? this.plankCount,
      plankHeightCm: plankHeightCm ?? this.plankHeightCm,
      stairStepCount: stairStepCount ?? this.stairStepCount,
      isBunnyHoppable: isBunnyHoppable ?? this.isBunnyHoppable,
      runningSpeedPenaltyFactor:
          runningSpeedPenaltyFactor ?? this.runningSpeedPenaltyFactor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'startMeter': startMeter,
      'lengthMeters': lengthMeters,
      'terrainType': terrainType.toJson(),
      'gradientPercent': gradientPercent,
      'camberAngleDegrees': camberAngleDegrees,
      'mudDepthCm': mudDepthCm,
      'mudViscosityIndex': mudViscosityIndex,
      'sandDepthCm': sandDepthCm,
      'plankCount': plankCount,
      'plankHeightCm': plankHeightCm,
      'stairStepCount': stairStepCount,
      'isBunnyHoppable': isBunnyHoppable,
      'runningSpeedPenaltyFactor': runningSpeedPenaltyFactor,
    };
  }

  factory CyclocrossCourseSegment.fromJson(Map<String, dynamic> json) {
    return CyclocrossCourseSegment(
      index: (json['index'] as num).toInt(),
      startMeter: (json['startMeter'] as num).toDouble(),
      lengthMeters: (json['lengthMeters'] as num).toDouble(),
      terrainType: CyclocrossTerrainType.fromJson(
        json['terrainType'] as String,
      ),
      gradientPercent: (json['gradientPercent'] as num?)?.toDouble() ?? 0.0,
      camberAngleDegrees:
          (json['camberAngleDegrees'] as num?)?.toDouble() ?? 0.0,
      mudDepthCm: (json['mudDepthCm'] as num?)?.toDouble() ?? 0.0,
      mudViscosityIndex: (json['mudViscosityIndex'] as num?)?.toDouble() ?? 0.0,
      sandDepthCm: (json['sandDepthCm'] as num?)?.toDouble() ?? 0.0,
      plankCount: (json['plankCount'] as num?)?.toInt() ?? 0,
      plankHeightCm: (json['plankHeightCm'] as num?)?.toDouble() ?? 40.0,
      stairStepCount: (json['stairStepCount'] as num?)?.toInt() ?? 0,
      isBunnyHoppable: (json['isBunnyHoppable'] as bool?) ?? false,
      runningSpeedPenaltyFactor:
          (json['runningSpeedPenaltyFactor'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CyclocrossCourseSegment &&
        other.index == index &&
        other.startMeter == startMeter &&
        other.lengthMeters == lengthMeters &&
        other.terrainType == terrainType &&
        other.gradientPercent == gradientPercent &&
        other.camberAngleDegrees == camberAngleDegrees &&
        other.mudDepthCm == mudDepthCm &&
        other.mudViscosityIndex == mudViscosityIndex &&
        other.sandDepthCm == sandDepthCm &&
        other.plankCount == plankCount &&
        other.plankHeightCm == plankHeightCm &&
        other.stairStepCount == stairStepCount &&
        other.isBunnyHoppable == isBunnyHoppable &&
        other.runningSpeedPenaltyFactor == runningSpeedPenaltyFactor;
  }

  @override
  int get hashCode => Object.hash(
        index,
        startMeter,
        lengthMeters,
        terrainType,
        gradientPercent,
        camberAngleDegrees,
        mudDepthCm,
        mudViscosityIndex,
        sandDepthCm,
        plankCount,
        plankHeightCm,
        stairStepCount,
        isBunnyHoppable,
        runningSpeedPenaltyFactor,
      );

  @override
  String toString() {
    return 'CyclocrossCourseSegment(#$index, ${startMeter.toStringAsFixed(0)}-${endMeter.toStringAsFixed(0)}m, ${terrainType.name})';
  }
}

/// Konfiguracja dwukierunkowego boksu technicznego (Double Pit Lane) w CX.
class DoublePitLaneConfig {
  final double firstAccessStartMeter;
  final double firstAccessLengthMeters;
  final double secondAccessStartMeter;
  final double secondAccessLengthMeters;
  final bool isBidirectional;
  final CyclocrossPitLaneSide pitSide;
  final int teamPitBoxesCount;
  final double bikeSwapBaseTimeSeconds;
  final double pressureWashEfficiency;

  const DoublePitLaneConfig({
    required this.firstAccessStartMeter,
    required this.firstAccessLengthMeters,
    required this.secondAccessStartMeter,
    required this.secondAccessLengthMeters,
    this.isBidirectional = true,
    this.pitSide = CyclocrossPitLaneSide.centerIsland,
    this.teamPitBoxesCount = 24,
    this.bikeSwapBaseTimeSeconds = 5.2,
    this.pressureWashEfficiency = 0.85,
  });

  /// Czy podany kilometraż na rundzie znajduje się w strefie pierwszego lub drugiego wjazdu do boksu.
  bool isWithinPitZone(double lapDistanceMeters) {
    final inFirst = lapDistanceMeters >= firstAccessStartMeter &&
        lapDistanceMeters <= firstAccessStartMeter + firstAccessLengthMeters;
    final inSecond = lapDistanceMeters >= secondAccessStartMeter &&
        lapDistanceMeters <= secondAccessStartMeter + secondAccessLengthMeters;
    return inFirst || inSecond;
  }

  /// Dystans [m] do najbliższego kolejnego wjazdu do boksu technicznego.
  double distanceToNextPitMeters(
    double lapDistanceMeters,
    double lapLengthMeters,
  ) {
    if (lapLengthMeters <= 0.0) return 0.0;
    if (isWithinPitZone(lapDistanceMeters)) return 0.0;

    final candidates = <double>[
      firstAccessStartMeter,
      secondAccessStartMeter,
    ];
    double best = lapLengthMeters;
    for (final start in candidates) {
      final delta = start >= lapDistanceMeters
          ? start - lapDistanceMeters
          : (lapLengthMeters - lapDistanceMeters) + start;
      if (delta < best) {
        best = delta;
      }
    }
    return best;
  }

  DoublePitLaneConfig copyWith({
    double? firstAccessStartMeter,
    double? firstAccessLengthMeters,
    double? secondAccessStartMeter,
    double? secondAccessLengthMeters,
    bool? isBidirectional,
    CyclocrossPitLaneSide? pitSide,
    int? teamPitBoxesCount,
    double? bikeSwapBaseTimeSeconds,
    double? pressureWashEfficiency,
  }) {
    return DoublePitLaneConfig(
      firstAccessStartMeter:
          firstAccessStartMeter ?? this.firstAccessStartMeter,
      firstAccessLengthMeters:
          firstAccessLengthMeters ?? this.firstAccessLengthMeters,
      secondAccessStartMeter:
          secondAccessStartMeter ?? this.secondAccessStartMeter,
      secondAccessLengthMeters:
          secondAccessLengthMeters ?? this.secondAccessLengthMeters,
      isBidirectional: isBidirectional ?? this.isBidirectional,
      pitSide: pitSide ?? this.pitSide,
      teamPitBoxesCount: teamPitBoxesCount ?? this.teamPitBoxesCount,
      bikeSwapBaseTimeSeconds:
          bikeSwapBaseTimeSeconds ?? this.bikeSwapBaseTimeSeconds,
      pressureWashEfficiency:
          pressureWashEfficiency ?? this.pressureWashEfficiency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstAccessStartMeter': firstAccessStartMeter,
      'firstAccessLengthMeters': firstAccessLengthMeters,
      'secondAccessStartMeter': secondAccessStartMeter,
      'secondAccessLengthMeters': secondAccessLengthMeters,
      'isBidirectional': isBidirectional,
      'pitSide': pitSide.toJson(),
      'teamPitBoxesCount': teamPitBoxesCount,
      'bikeSwapBaseTimeSeconds': bikeSwapBaseTimeSeconds,
      'pressureWashEfficiency': pressureWashEfficiency,
    };
  }

  factory DoublePitLaneConfig.fromJson(Map<String, dynamic> json) {
    return DoublePitLaneConfig(
      firstAccessStartMeter:
          (json['firstAccessStartMeter'] as num).toDouble(),
      firstAccessLengthMeters:
          (json['firstAccessLengthMeters'] as num).toDouble(),
      secondAccessStartMeter:
          (json['secondAccessStartMeter'] as num).toDouble(),
      secondAccessLengthMeters:
          (json['secondAccessLengthMeters'] as num).toDouble(),
      isBidirectional: (json['isBidirectional'] as bool?) ?? true,
      pitSide: CyclocrossPitLaneSide.fromJson(
        (json['pitSide'] as String?) ?? 'centerIsland',
      ),
      teamPitBoxesCount: (json['teamPitBoxesCount'] as num?)?.toInt() ?? 24,
      bikeSwapBaseTimeSeconds:
          (json['bikeSwapBaseTimeSeconds'] as num?)?.toDouble() ?? 5.2,
      pressureWashEfficiency:
          (json['pressureWashEfficiency'] as num?)?.toDouble() ?? 0.85,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DoublePitLaneConfig &&
        other.firstAccessStartMeter == firstAccessStartMeter &&
        other.firstAccessLengthMeters == firstAccessLengthMeters &&
        other.secondAccessStartMeter == secondAccessStartMeter &&
        other.secondAccessLengthMeters == secondAccessLengthMeters &&
        other.isBidirectional == isBidirectional &&
        other.pitSide == pitSide &&
        other.teamPitBoxesCount == teamPitBoxesCount &&
        other.bikeSwapBaseTimeSeconds == bikeSwapBaseTimeSeconds &&
        other.pressureWashEfficiency == pressureWashEfficiency;
  }

  @override
  int get hashCode => Object.hash(
        firstAccessStartMeter,
        firstAccessLengthMeters,
        secondAccessStartMeter,
        secondAccessLengthMeters,
        isBidirectional,
        pitSide,
        teamPitBoxesCount,
        bikeSwapBaseTimeSeconds,
        pressureWashEfficiency,
      );
}

/// Zimowe warunki atmosferyczne oraz dynamika odkładania błota w CX.
class CyclocrossWeatherAndMudState {
  final CyclocrossMonth month;
  final double airTemperatureCelsius;
  final double precipitationMmPerHour;
  final CyclocrossMudCondition mudCondition;
  final double mudAccumulationRateKgPerLap;
  final double frostGripModifier;

  const CyclocrossWeatherAndMudState({
    required this.month,
    required this.airTemperatureCelsius,
    required this.precipitationMmPerHour,
    required this.mudCondition,
    required this.mudAccumulationRateKgPerLap,
    this.frostGripModifier = 1.0,
  });

  /// Efektywny przyrost masy błota na rowerze na jedno okrążenie [kg].
  double get effectiveMudBuildupKgPerLap {
    final rainBoost = 1.0 + (precipitationMmPerHour.clamp(0.0, 12.0) * 0.04);
    return mudAccumulationRateKgPerLap *
        mudCondition.adhesionMultiplier *
        rainBoost;
  }

  CyclocrossWeatherAndMudState copyWith({
    CyclocrossMonth? month,
    double? airTemperatureCelsius,
    double? precipitationMmPerHour,
    CyclocrossMudCondition? mudCondition,
    double? mudAccumulationRateKgPerLap,
    double? frostGripModifier,
  }) {
    return CyclocrossWeatherAndMudState(
      month: month ?? this.month,
      airTemperatureCelsius:
          airTemperatureCelsius ?? this.airTemperatureCelsius,
      precipitationMmPerHour:
          precipitationMmPerHour ?? this.precipitationMmPerHour,
      mudCondition: mudCondition ?? this.mudCondition,
      mudAccumulationRateKgPerLap:
          mudAccumulationRateKgPerLap ?? this.mudAccumulationRateKgPerLap,
      frostGripModifier: frostGripModifier ?? this.frostGripModifier,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month.toJson(),
      'airTemperatureCelsius': airTemperatureCelsius,
      'precipitationMmPerHour': precipitationMmPerHour,
      'mudCondition': mudCondition.toJson(),
      'mudAccumulationRateKgPerLap': mudAccumulationRateKgPerLap,
      'frostGripModifier': frostGripModifier,
    };
  }

  factory CyclocrossWeatherAndMudState.fromJson(Map<String, dynamic> json) {
    return CyclocrossWeatherAndMudState(
      month: CyclocrossMonth.fromJson(json['month'] as String),
      airTemperatureCelsius:
          (json['airTemperatureCelsius'] as num).toDouble(),
      precipitationMmPerHour:
          (json['precipitationMmPerHour'] as num).toDouble(),
      mudCondition: CyclocrossMudCondition.fromJson(
        json['mudCondition'] as String,
      ),
      mudAccumulationRateKgPerLap:
          (json['mudAccumulationRateKgPerLap'] as num).toDouble(),
      frostGripModifier:
          (json['frostGripModifier'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CyclocrossWeatherAndMudState &&
        other.month == month &&
        other.airTemperatureCelsius == airTemperatureCelsius &&
        other.precipitationMmPerHour == precipitationMmPerHour &&
        other.mudCondition == mudCondition &&
        other.mudAccumulationRateKgPerLap == mudAccumulationRateKgPerLap &&
        other.frostGripModifier == frostGripModifier;
  }

  @override
  int get hashCode => Object.hash(
        month,
        airTemperatureCelsius,
        precipitationMmPerHour,
        mudCondition,
        mudAccumulationRateKgPerLap,
        frostGripModifier,
      );
}

/// Główny model danych zimowego Kolarstwa Przełajowego (Cyclo-Cross / CX)
/// rozgrywanego na rundach 2.5–3.2 km od listopada do stycznia.
class CyclocrossCourseAndMudModel {
  final String id;
  final String name;
  final String countryCode;
  final CyclocrossMonth raceMonth;
  final double lapLengthKm;
  final int targetLaps;
  final double startFinishStraightMeters;
  final List<CyclocrossCourseSegment> segments;
  final DoublePitLaneConfig doublePitLane;
  final CyclocrossWeatherAndMudState weatherAndMudState;

  const CyclocrossCourseAndMudModel({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.raceMonth,
    required this.lapLengthKm,
    required this.targetLaps,
    required this.startFinishStraightMeters,
    required this.segments,
    required this.doublePitLane,
    required this.weatherAndMudState,
  });

  /// Długość jednej rundy w metrach [m].
  double get lapLengthMeters => lapLengthKm * 1000.0;

  /// Całkowity dystans wyścigu w kilometrach [km].
  double get totalRaceDistanceKm => lapLengthKm * targetLaps;

  /// Czy runda mieści się w regulaminowym zakresie UCI CX (2.5–3.2 km).
  bool get isValidUciLapLength => lapLengthKm >= 2.5 && lapLengthKm <= 3.2;

  /// Czy wyścig odbywa się w zimowym oknie CX (listopad–styczeń).
  bool get isWinterWindowValid =>
      raceMonth == CyclocrossMonth.november ||
      raceMonth == CyclocrossMonth.december ||
      raceMonth == CyclocrossMonth.january;

  /// Łączna długość odcinków gęstego błota (`Deep Mud`) na jednej rundzie [m].
  double get deepMudDistanceMeters => _sumDistanceByType(
        CyclocrossTerrainType.deepMud,
      );

  /// Łączna długość odcinków głębokiego piasku (`Sand Pit`) na jednej rundzie [m].
  double get sandPitDistanceMeters => _sumDistanceByType(
        CyclocrossTerrainType.sandPit,
      );

  /// Łączna długość stromych skarp trawersowych (`Off-Camber Slope`) na rundzie [m].
  double get offCamberDistanceMeters => _sumDistanceByType(
        CyclocrossTerrainType.offCamberSlope,
      );

  /// Łączna liczba drewnianych przeszkód (`Planks / Barriers` 40 cm) na rundzie.
  int get totalPlankObstaclesCount {
    int count = 0;
    for (final segment in segments) {
      if (segment.terrainType == CyclocrossTerrainType.planks) {
        count += math.max(1, segment.plankCount);
      }
    }
    return count;
  }

  /// Łączna liczba stopni schodów (`Staircase Run-up`) na jednej rundzie.
  int get totalStairStepsCount {
    int steps = 0;
    for (final segment in segments) {
      if (segment.terrainType == CyclocrossTerrainType.staircaseRunUp) {
        steps += segment.stairStepCount;
      }
    }
    return steps;
  }

  /// Udział procentowy błota w długości całej rundy (0.0–1.0).
  double get mudRatio {
    if (lapLengthMeters <= 0.0) return 0.0;
    return (deepMudDistanceMeters / lapLengthMeters).clamp(0.0, 1.0);
  }

  /// Udział procentowy piasku w długości całej rundy (0.0–1.0).
  double get sandRatio {
    if (lapLengthMeters <= 0.0) return 0.0;
    return (sandPitDistanceMeters / lapLengthMeters).clamp(0.0, 1.0);
  }

  /// Średnia ważona trudność techniczna rundy CX w skali 0–100.
  double get technicalDifficultyScore {
    if (segments.isEmpty) return 0.0;
    double weightedSum = 0.0;
    double totalLength = 0.0;
    for (final segment in segments) {
      weightedSum += segment.segmentTechnicalDifficulty * segment.lengthMeters;
      totalLength += segment.lengthMeters;
    }
    if (totalLength <= 0.0) return 0.0;
    return (weightedSum / totalLength).clamp(0.0, 100.0);
  }

  /// Szacowana masa błota odłożonego na rowerze i oponach [kg] od ostatniej zmiany w boksie.
  double estimateMudWeightKgOnBike({required int lapsSinceLastPitSwap}) {
    if (lapsSinceLastPitSwap <= 0 || mudRatio <= 0.0) return 0.0;
    final perLap = weatherAndMudState.effectiveMudBuildupKgPerLap *
        (0.5 + mudRatio * 1.8);
    return (perLap * lapsSinceLastPitSwap).clamp(0.0, 3.8);
  }

  /// Rekomendacja zmiany roweru w dwukierunkowym boksie technicznym (`Double Pit Lane`).
  bool shouldRecommendPitBikeSwap({
    required int lapsSinceLastPitSwap,
    required double tireClogRatio,
  }) {
    final mudKg = estimateMudWeightKgOnBike(
      lapsSinceLastPitSwap: lapsSinceLastPitSwap,
    );
    return mudKg >= 1.25 || tireClogRatio >= 0.55;
  }

  /// Zwraca segment odpowiadający podanemu metrażowi na rundzie.
  CyclocrossCourseSegment? segmentAtLapDistance(double metersIntoLap) {
    if (segments.isEmpty) return null;
    final normalized = lapLengthMeters > 0.0
        ? (metersIntoLap % lapLengthMeters)
        : metersIntoLap;
    for (final segment in segments) {
      if (normalized >= segment.startMeter && normalized < segment.endMeter) {
        return segment;
      }
    }
    return segments.last;
  }

  /// Filtruje segmenty według wybranego typu przeszkody lub nawierzchni.
  List<CyclocrossCourseSegment> segmentsByType(CyclocrossTerrainType type) {
    return segments.where((s) => s.terrainType == type).toList(growable: false);
  }

  double _sumDistanceByType(CyclocrossTerrainType type) {
    double sum = 0.0;
    for (final segment in segments) {
      if (segment.terrainType == type) {
        sum += segment.lengthMeters;
      }
    }
    return sum;
  }

  /// Tworzy realistyczną, błotną rundę przełajową we Flandrii (2.85 km, grudzień).
  factory CyclocrossCourseAndMudModel.createFlandersMudClassic({
    String id = 'cx_flanders_mud_2850',
    String name = 'Gavere Muddy Castle CX',
  }) {
    return const CyclocrossCourseAndMudModel(
      id: 'cx_flanders_mud_2850',
      name: 'Gavere Muddy Castle CX',
      countryCode: 'BEL',
      raceMonth: CyclocrossMonth.december,
      lapLengthKm: 2.85,
      targetLaps: 8,
      startFinishStraightMeters: 260.0,
      doublePitLane: DoublePitLaneConfig(
        firstAccessStartMeter: 1120.0,
        firstAccessLengthMeters: 75.0,
        secondAccessStartMeter: 2340.0,
        secondAccessLengthMeters: 75.0,
        isBidirectional: true,
        pitSide: CyclocrossPitLaneSide.centerIsland,
        teamPitBoxesCount: 28,
        bikeSwapBaseTimeSeconds: 4.9,
        pressureWashEfficiency: 0.90,
      ),
      weatherAndMudState: CyclocrossWeatherAndMudState(
        month: CyclocrossMonth.december,
        airTemperatureCelsius: 3.5,
        precipitationMmPerHour: 2.8,
        mudCondition: CyclocrossMudCondition.heavyMud,
        mudAccumulationRateKgPerLap: 0.72,
        frostGripModifier: 0.92,
      ),
      segments: [
        CyclocrossCourseSegment(
          index: 0,
          startMeter: 0.0,
          lengthMeters: 260.0,
          terrainType: CyclocrossTerrainType.pavedStartFinish,
          gradientPercent: 1.5,
        ),
        CyclocrossCourseSegment(
          index: 1,
          startMeter: 260.0,
          lengthMeters: 380.0,
          terrainType: CyclocrossTerrainType.meadowGrass,
          gradientPercent: 4.2,
        ),
        CyclocrossCourseSegment(
          index: 2,
          startMeter: 640.0,
          lengthMeters: 290.0,
          terrainType: CyclocrossTerrainType.deepMud,
          gradientPercent: 2.5,
          mudDepthCm: 15.0,
          mudViscosityIndex: 0.85,
          runningSpeedPenaltyFactor: 0.62,
        ),
        CyclocrossCourseSegment(
          index: 3,
          startMeter: 930.0,
          lengthMeters: 190.0,
          terrainType: CyclocrossTerrainType.offCamberSlope,
          gradientPercent: -5.0,
          camberAngleDegrees: 24.0,
        ),
        CyclocrossCourseSegment(
          index: 4,
          startMeter: 1120.0,
          lengthMeters: 75.0,
          terrainType: CyclocrossTerrainType.doublePitLane,
        ),
        CyclocrossCourseSegment(
          index: 5,
          startMeter: 1195.0,
          lengthMeters: 165.0,
          terrainType: CyclocrossTerrainType.sandPit,
          sandDepthCm: 20.0,
          runningSpeedPenaltyFactor: 0.58,
        ),
        CyclocrossCourseSegment(
          index: 6,
          startMeter: 1360.0,
          lengthMeters: 45.0,
          terrainType: CyclocrossTerrainType.planks,
          plankCount: 2,
          plankHeightCm: 40.0,
          isBunnyHoppable: true,
          runningSpeedPenaltyFactor: 0.74,
        ),
        CyclocrossCourseSegment(
          index: 7,
          startMeter: 1405.0,
          lengthMeters: 55.0,
          terrainType: CyclocrossTerrainType.staircaseRunUp,
          gradientPercent: 22.0,
          stairStepCount: 28,
          runningSpeedPenaltyFactor: 0.45,
        ),
        CyclocrossCourseSegment(
          index: 8,
          startMeter: 1460.0,
          lengthMeters: 490.0,
          terrainType: CyclocrossTerrainType.woodlandSingletrack,
          gradientPercent: -3.0,
        ),
        CyclocrossCourseSegment(
          index: 9,
          startMeter: 1950.0,
          lengthMeters: 390.0,
          terrainType: CyclocrossTerrainType.deepMud,
          gradientPercent: 3.0,
          mudDepthCm: 12.0,
          mudViscosityIndex: 0.78,
          runningSpeedPenaltyFactor: 0.68,
        ),
        CyclocrossCourseSegment(
          index: 10,
          startMeter: 2340.0,
          lengthMeters: 75.0,
          terrainType: CyclocrossTerrainType.doublePitLane,
        ),
        CyclocrossCourseSegment(
          index: 11,
          startMeter: 2415.0,
          lengthMeters: 435.0,
          terrainType: CyclocrossTerrainType.meadowGrass,
          gradientPercent: -1.5,
        ),
      ],
    ).copyWith(id: id, name: name);
  }

  CyclocrossCourseAndMudModel copyWith({
    String? id,
    String? name,
    String? countryCode,
    CyclocrossMonth? raceMonth,
    double? lapLengthKm,
    int? targetLaps,
    double? startFinishStraightMeters,
    List<CyclocrossCourseSegment>? segments,
    DoublePitLaneConfig? doublePitLane,
    CyclocrossWeatherAndMudState? weatherAndMudState,
  }) {
    return CyclocrossCourseAndMudModel(
      id: id ?? this.id,
      name: name ?? this.name,
      countryCode: countryCode ?? this.countryCode,
      raceMonth: raceMonth ?? this.raceMonth,
      lapLengthKm: lapLengthKm ?? this.lapLengthKm,
      targetLaps: targetLaps ?? this.targetLaps,
      startFinishStraightMeters:
          startFinishStraightMeters ?? this.startFinishStraightMeters,
      segments: segments ?? this.segments,
      doublePitLane: doublePitLane ?? this.doublePitLane,
      weatherAndMudState: weatherAndMudState ?? this.weatherAndMudState,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'countryCode': countryCode,
      'raceMonth': raceMonth.toJson(),
      'lapLengthKm': lapLengthKm,
      'targetLaps': targetLaps,
      'startFinishStraightMeters': startFinishStraightMeters,
      'segments': segments.map((s) => s.toJson()).toList(),
      'doublePitLane': doublePitLane.toJson(),
      'weatherAndMudState': weatherAndMudState.toJson(),
    };
  }

  factory CyclocrossCourseAndMudModel.fromJson(Map<String, dynamic> json) {
    return CyclocrossCourseAndMudModel(
      id: json['id'] as String,
      name: json['name'] as String,
      countryCode: json['countryCode'] as String,
      raceMonth: CyclocrossMonth.fromJson(json['raceMonth'] as String),
      lapLengthKm: (json['lapLengthKm'] as num).toDouble(),
      targetLaps: (json['targetLaps'] as num).toInt(),
      startFinishStraightMeters:
          (json['startFinishStraightMeters'] as num).toDouble(),
      segments: (json['segments'] as List<dynamic>)
          .map(
            (e) => CyclocrossCourseSegment.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      doublePitLane: DoublePitLaneConfig.fromJson(
        json['doublePitLane'] as Map<String, dynamic>,
      ),
      weatherAndMudState: CyclocrossWeatherAndMudState.fromJson(
        json['weatherAndMudState'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CyclocrossCourseAndMudModel) return false;
    if (other.segments.length != segments.length) return false;
    for (int i = 0; i < segments.length; i++) {
      if (other.segments[i] != segments[i]) return false;
    }
    return other.id == id &&
        other.name == name &&
        other.countryCode == countryCode &&
        other.raceMonth == raceMonth &&
        other.lapLengthKm == lapLengthKm &&
        other.targetLaps == targetLaps &&
        other.startFinishStraightMeters == startFinishStraightMeters &&
        other.doublePitLane == doublePitLane &&
        other.weatherAndMudState == weatherAndMudState;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        countryCode,
        raceMonth,
        lapLengthKm,
        targetLaps,
        startFinishStraightMeters,
        Object.hashAll(segments),
        doublePitLane,
        weatherAndMudState,
      );

  @override
  String toString() {
    return 'CyclocrossCourseAndMudModel($name, ${lapLengthKm.toStringAsFixed(2)} km x $targetLaps laps, ${raceMonth.shortCode})';
  }
}
