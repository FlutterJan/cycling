import 'dart:math' as math;

enum SegmentSurfaceType {
  smoothAsphalt,
  roughAsphalt,
  cobblestonesSector1, // 1 gwiazdka – łatwy bruk
  cobblestonesSector2, // 2 gwiazdki
  cobblestonesSector3, // 3 gwiazdki – standardowy sektor Roubaix
  cobblestonesSector4, // 4 gwiazdki – trudny bruk (np. Carrefour de l'Arbre)
  cobblestonesSector5, // 5 gwiazdek – piekielny sektor (np. Trouée d'Arenberg)
  gravelStrade, // Szuter toskański (Strade Bianche)
  concrete;

  String toJson() => name;

  static SegmentSurfaceType fromJson(String value) {
    final lower = value.toLowerCase();
    for (final e in SegmentSurfaceType.values) {
      if (e.name.toLowerCase() == lower) {
        return e;
      }
    }
    if (lower.contains('cobble')) {
      return SegmentSurfaceType.cobblestonesSector3;
    }
    return SegmentSurfaceType.smoothAsphalt;
  }
}

enum SegmentClassification {
  none,
  intermediateSprint,
  cat4,
  cat3,
  cat2,
  cat1,
  horsCategorie, // HC (Górski szczyt poza kategorią, np. Alpe d'Huez, Galibier)
  finishLine;

  String toJson() => name;

  static SegmentClassification fromJson(String value) {
    return SegmentClassification.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SegmentClassification.none,
    );
  }
}

class StageSegment {
  final int index;
  final double startKm;
  final double lengthKm;
  final double startElevationM;
  final double endElevationM;
  final SegmentSurfaceType surfaceType;
  final double technicalDifficulty; // 1.0 - 100.0 (zakręty, wysepki, zwężenia)
  final double windDirectionDegrees; // Kierunek skąd wieje wiatr (0-360°, 0° = północ)
  final double roadBearingDegrees; // Kierunek jazdy kolarzy / azymut odcinka drogi (0-360°)
  final SegmentClassification sprintOrKomClassification;

  const StageSegment({
    required this.index,
    required this.startKm,
    required this.lengthKm,
    required this.startElevationM,
    required this.endElevationM,
    required this.surfaceType,
    required this.technicalDifficulty,
    required this.windDirectionDegrees,
    required this.roadBearingDegrees,
    required this.sprintOrKomClassification,
  });

  /// Kilometraż końcowy odcinka [km]
  double get endKm => startKm + lengthKm;

  /// Średnie nachylenie odcinka w procentach [%]
  /// Wartość dodatnia oznacza podjazd, ujemna zjazd.
  double get gradientPercent {
    final lengthMeters = lengthKm * 1000.0;
    if (lengthMeters <= 0.0) return 0.0;
    return ((endElevationM - startElevationM) / lengthMeters) * 100.0;
  }

  /// Przewyższenie dodatnie na segmencie [m]
  double get elevationGainM => math.max(0.0, endElevationM - startElevationM);

  /// Czy odcinek jest wspinaczką (> 2.0% średniego nachylenia)
  bool get isClimb => gradientPercent > 2.0;

  /// Czy odcinek jest zjazdem (< -2.0% średniego nachylenia)
  bool get isDescent => gradientPercent < -2.0;

  /// Czy odcinek zawiera bruki (Cobblestones)
  bool get isCobblestone =>
      surfaceType == SegmentSurfaceType.cobblestonesSector1 ||
      surfaceType == SegmentSurfaceType.cobblestonesSector2 ||
      surfaceType == SegmentSurfaceType.cobblestonesSector3 ||
      surfaceType == SegmentSurfaceType.cobblestonesSector4 ||
      surfaceType == SegmentSurfaceType.cobblestonesSector5;

  /// Czy odcinek jest lotną premią sprinterską
  bool get isIntermediateSprint =>
      sprintOrKomClassification == SegmentClassification.intermediateSprint;

  /// Kategoria podjazdu jeśli na segmencie znajduje się premia górska (KOM)
  String? get climbCategory {
    switch (sprintOrKomClassification) {
      case SegmentClassification.cat4:
        return '4';
      case SegmentClassification.cat3:
        return '3';
      case SegmentClassification.cat2:
        return '2';
      case SegmentClassification.cat1:
        return '1';
      case SegmentClassification.horsCategorie:
        return 'HC';
      default:
        return null;
    }
  }

  /// Czy odcinek jest premią górską
  bool get isKom => climbCategory != null;

  /// Czy odcinek jest metą etapu
  bool get isFinishLine => sprintOrKomClassification == SegmentClassification.finishLine;

  /// Kąt natarcia wiatru względem osi jazdy kolarza [0° - 180°]
  /// 0° = czołowy wiatr (headwind), 90° = czysty boczny (crosswind), 180° = w plecy (tailwind)
  double get relativeWindAngleDegrees {
    double diff = (windDirectionDegrees - roadBearingDegrees).abs() % 360.0;
    if (diff > 180.0) diff = 360.0 - diff;
    return 180.0 - diff;
  }

  /// Współczynnik oporu toczenia Crr przypisany do nawierzchni tego odcinka
  double get baseCrrForSurface {
    switch (surfaceType) {
      case SegmentSurfaceType.smoothAsphalt:
        return 0.0033;
      case SegmentSurfaceType.roughAsphalt:
        return 0.0055;
      case SegmentSurfaceType.cobblestonesSector1:
        return 0.0080;
      case SegmentSurfaceType.cobblestonesSector2:
        return 0.0100;
      case SegmentSurfaceType.cobblestonesSector3:
        return 0.0125;
      case SegmentSurfaceType.cobblestonesSector4:
        return 0.0150;
      case SegmentSurfaceType.cobblestonesSector5:
        return 0.0185;
      case SegmentSurfaceType.gravelStrade:
        return 0.0090;
      case SegmentSurfaceType.concrete:
        return 0.0048;
    }
  }

  StageSegment copyWith({
    int? index,
    double? startKm,
    double? lengthKm,
    double? startElevationM,
    double? endElevationM,
    SegmentSurfaceType? surfaceType,
    double? technicalDifficulty,
    double? windDirectionDegrees,
    double? roadBearingDegrees,
    SegmentClassification? sprintOrKomClassification,
  }) {
    return StageSegment(
      index: index ?? this.index,
      startKm: startKm ?? this.startKm,
      lengthKm: lengthKm ?? this.lengthKm,
      startElevationM: startElevationM ?? this.startElevationM,
      endElevationM: endElevationM ?? this.endElevationM,
      surfaceType: surfaceType ?? this.surfaceType,
      technicalDifficulty: technicalDifficulty ?? this.technicalDifficulty,
      windDirectionDegrees: windDirectionDegrees ?? this.windDirectionDegrees,
      roadBearingDegrees: roadBearingDegrees ?? this.roadBearingDegrees,
      sprintOrKomClassification: sprintOrKomClassification ?? this.sprintOrKomClassification,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'startKm': startKm,
      'lengthKm': lengthKm,
      'startElevationM': startElevationM,
      'endElevationM': endElevationM,
      'surfaceType': surfaceType.toJson(),
      'technicalDifficulty': technicalDifficulty,
      'windDirectionDegrees': windDirectionDegrees,
      'roadBearingDegrees': roadBearingDegrees,
      'sprintOrKomClassification': sprintOrKomClassification.toJson(),
    };
  }

  factory StageSegment.fromJson(Map<String, dynamic> json) {
    return StageSegment(
      index: (json['index'] as num).toInt(),
      startKm: (json['startKm'] as num).toDouble(),
      lengthKm: (json['lengthKm'] as num).toDouble(),
      startElevationM: (json['startElevationM'] as num).toDouble(),
      endElevationM: (json['endElevationM'] as num).toDouble(),
      surfaceType: SegmentSurfaceType.fromJson(json['surfaceType'] as String),
      technicalDifficulty: (json['technicalDifficulty'] as num).toDouble(),
      windDirectionDegrees: (json['windDirectionDegrees'] as num).toDouble(),
      roadBearingDegrees: (json['roadBearingDegrees'] as num).toDouble(),
      sprintOrKomClassification: SegmentClassification.fromJson(
        json['sprintOrKomClassification'] as String,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StageSegment &&
        other.index == index &&
        other.startKm == startKm &&
        other.lengthKm == lengthKm &&
        other.startElevationM == startElevationM &&
        other.endElevationM == endElevationM &&
        other.surfaceType == surfaceType &&
        other.technicalDifficulty == technicalDifficulty &&
        other.windDirectionDegrees == windDirectionDegrees &&
        other.roadBearingDegrees == roadBearingDegrees &&
        other.sprintOrKomClassification == sprintOrKomClassification;
  }

  @override
  int get hashCode {
    return Object.hash(
      index,
      startKm,
      lengthKm,
      startElevationM,
      endElevationM,
      surfaceType,
      technicalDifficulty,
      windDirectionDegrees,
      roadBearingDegrees,
      sprintOrKomClassification,
    );
  }

  @override
  String toString() {
    return 'StageSegment(#$index, ${startKm.toStringAsFixed(1)}-${endKm.toStringAsFixed(1)}km, ${gradientPercent.toStringAsFixed(1)}%, ${surfaceType.name}, class: ${sprintOrKomClassification.name})';
  }
}

