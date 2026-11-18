import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Kierunek wiatru bocznego względem osi jazdy peletonu.
enum CrosswindSide {
  /// Wiatr wieje z lewej strony na prawą — krawężnik zawietrzny (rynsztok) po prawej.
  leftToRight,

  /// Wiatr wieje z prawej strony na lewą — krawężnik zawietrzny (rynsztok) po lewej.
  rightToLeft;

  String get labelPl {
    switch (this) {
      case CrosswindSide.leftToRight:
        return 'Z lewej → Prawy krawężnik';
      case CrosswindSide.rightToLeft:
        return 'Z prawej → Lewy krawężnik';
    }
  }

  String toJson() => name;

  static CrosswindSide fromJson(String value) {
    return CrosswindSide.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CrosswindSide.leftToRight,
    );
  }
}

/// Tryb ustawienia diagonalnego pociągu sprinterskiego na wietrze bocznym.
enum DiagonalTrainFormationMode {
  /// Klasyczny pociąg gęsiego (brak wykorzystania wiatru bocznego).
  standardInline(
    labelPl: 'Pociąg Liniowy',
    lateralStretchFactor: 0.25,
    paceBoostFactor: 1.00,
    gutterAggression: 0.15,
  ),

  /// Skośny wachlarz osłaniający lidera i sprintera w kieszeni zawietrznej.
  diagonalShield(
    labelPl: 'Tarcza Diagonalna',
    lateralStretchFactor: 0.78,
    paceBoostFactor: 1.03,
    gutterAggression: 0.60,
  ),

  /// Agresywne rozciągnięcie przekątnej aż pod krawężnik — spycha rywali w rynsztok.
  aggressiveGutterPress(
    labelPl: 'Docisk do Krawężnika',
    lateralStretchFactor: 1.00,
    paceBoostFactor: 1.06,
    gutterAggression: 1.00,
  ),

  /// Maksymalne tempo na rancie w celu rozerwania ogona i odcięcia rywali.
  splitAndSnap(
    labelPl: 'Rozrywający Wachlarz',
    lateralStretchFactor: 0.96,
    paceBoostFactor: 1.09,
    gutterAggression: 0.92,
  );

  final String labelPl;
  final double lateralStretchFactor;
  final double paceBoostFactor;
  final double gutterAggression;

  const DiagonalTrainFormationMode({
    required this.labelPl,
    required this.lateralStretchFactor,
    required this.paceBoostFactor,
    required this.gutterAggression,
  });

  String toJson() => name;

  static DiagonalTrainFormationMode fromJson(String value) {
    return DiagonalTrainFormationMode.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DiagonalTrainFormationMode.diagonalShield,
    );
  }
}

/// Status ekspozycji aerodynamicznej kolarza w pobliżu krawężnika.
enum GutterPressureStatus {
  /// Kolarz mieści się w osłoniętej kieszeni wachlarza.
  shelteredPocket,

  /// Walka o ostatnie bezpieczne koło na rancie.
  fightingForWheel,

  /// Zepchnięty pod krawężnik (*In the Gutter*) — brak osłony przed wiatrem.
  inTheGutter,

  /// Całkowicie odcięty z formacji z narastającą stratą czasową.
  droppedFromEchelon;

  String get labelPl {
    switch (this) {
      case GutterPressureStatus.shelteredPocket:
        return 'Osłona w Wachlarzu';
      case GutterPressureStatus.fightingForWheel:
        return 'Walka o Rant';
      case GutterPressureStatus.inTheGutter:
        return 'In the Gutter!';
      case GutterPressureStatus.droppedFromEchelon:
        return 'Odcięty z Rantu';
    }
  }

  String toJson() => name;

  static GutterPressureStatus fromJson(String value) {
    return GutterPressureStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GutterPressureStatus.shelteredPocket,
    );
  }
}

/// Faza realizacji manewru diagonalnego pociągu sprinterskiego.
enum DiagonalTrainPhase {
  /// Ustawianie pociągu przed strefą finałową (>3 km).
  positioning,

  /// Zamknięcie przekątnej i odcięcie szerokości jezdni.
  diagonalLock,

  /// Docisk rywali pod krawężnik na ostatnich 3 km.
  gutterSqueeze,

  /// Odpalenie sprintera z zawietrznej pozycji (<350 m).
  sprintLaunch;

  String get labelPl {
    switch (this) {
      case DiagonalTrainPhase.positioning:
        return 'Formowanie Przekątnej';
      case DiagonalTrainPhase.diagonalLock:
        return 'Blokada Szerokości';
      case DiagonalTrainPhase.gutterSqueeze:
        return 'Spychanie w Rynsztok';
      case DiagonalTrainPhase.sprintLaunch:
        return 'Odpalenie Sprintera';
    }
  }

  String toJson() => name;

  static DiagonalTrainPhase fromJson(String value) {
    return DiagonalTrainPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DiagonalTrainPhase.diagonalLock,
    );
  }
}

/// Parametry środowiskowe i drogowe dla diagonalnej formacji wachlarza.
class DiagonalTrainWindContext {
  final double windSpeedKmh;
  final double windAngleDegrees;
  final CrosswindSide crosswindSide;
  final double roadWidthMeters;
  final double distanceToFinishMeters;
  final double targetTrainSpeedKmh;

  const DiagonalTrainWindContext({
    required this.windSpeedKmh,
    required this.windAngleDegrees,
    required this.crosswindSide,
    required this.roadWidthMeters,
    required this.distanceToFinishMeters,
    required this.targetTrainSpeedKmh,
  });

  DiagonalTrainWindContext copyWith({
    double? windSpeedKmh,
    double? windAngleDegrees,
    CrosswindSide? crosswindSide,
    double? roadWidthMeters,
    double? distanceToFinishMeters,
    double? targetTrainSpeedKmh,
  }) {
    return DiagonalTrainWindContext(
      windSpeedKmh: windSpeedKmh ?? this.windSpeedKmh,
      windAngleDegrees: windAngleDegrees ?? this.windAngleDegrees,
      crosswindSide: crosswindSide ?? this.crosswindSide,
      roadWidthMeters: roadWidthMeters ?? this.roadWidthMeters,
      distanceToFinishMeters:
          distanceToFinishMeters ?? this.distanceToFinishMeters,
      targetTrainSpeedKmh: targetTrainSpeedKmh ?? this.targetTrainSpeedKmh,
    );
  }

  Map<String, dynamic> toJson() => {
        'windSpeedKmh': windSpeedKmh,
        'windAngleDegrees': windAngleDegrees,
        'crosswindSide': crosswindSide.toJson(),
        'roadWidthMeters': roadWidthMeters,
        'distanceToFinishMeters': distanceToFinishMeters,
        'targetTrainSpeedKmh': targetTrainSpeedKmh,
      };

  factory DiagonalTrainWindContext.fromJson(Map<String, dynamic> json) {
    return DiagonalTrainWindContext(
      windSpeedKmh: (json['windSpeedKmh'] as num?)?.toDouble() ?? 30.0,
      windAngleDegrees: (json['windAngleDegrees'] as num?)?.toDouble() ?? 75.0,
      crosswindSide: CrosswindSide.fromJson(
        (json['crosswindSide'] as String?) ?? 'leftToRight',
      ),
      roadWidthMeters: (json['roadWidthMeters'] as num?)?.toDouble() ?? 6.5,
      distanceToFinishMeters:
          (json['distanceToFinishMeters'] as num?)?.toDouble() ?? 1800.0,
      targetTrainSpeedKmh:
          (json['targetTrainSpeedKmh'] as num?)?.toDouble() ?? 56.0,
    );
  }
}

/// Dane wejściowe kolarza w pociągu lub rywala próbującego utrzymać koło.
class EchelonTrainRiderInput {
  final String riderId;
  final String name;
  final String teamId;
  final bool isPlayerTeam;
  final bool isSprinter;
  final int roleOrder;
  final double flatSkill;
  final double sprintSkill;
  final double bikeHandling;
  final double raceIq;
  final double draftingEfficiency;
  final double ftpWatts;
  final double wPrimeRemainingJoules;
  final double wPrimeMaxJoules;
  final double cda;

  const EchelonTrainRiderInput({
    required this.riderId,
    required this.name,
    required this.teamId,
    required this.isPlayerTeam,
    required this.isSprinter,
    required this.roleOrder,
    required this.flatSkill,
    required this.sprintSkill,
    required this.bikeHandling,
    required this.raceIq,
    required this.draftingEfficiency,
    required this.ftpWatts,
    required this.wPrimeRemainingJoules,
    required this.wPrimeMaxJoules,
    this.cda = 0.30,
  });

  double get wPrimeRatio => wPrimeMaxJoules <= 0.0
      ? 0.0
      : (wPrimeRemainingJoules / wPrimeMaxJoules).clamp(0.0, 1.0);

  EchelonTrainRiderInput copyWith({
    String? riderId,
    String? name,
    String? teamId,
    bool? isPlayerTeam,
    bool? isSprinter,
    int? roleOrder,
    double? flatSkill,
    double? sprintSkill,
    double? bikeHandling,
    double? raceIq,
    double? draftingEfficiency,
    double? ftpWatts,
    double? wPrimeRemainingJoules,
    double? wPrimeMaxJoules,
    double? cda,
  }) {
    return EchelonTrainRiderInput(
      riderId: riderId ?? this.riderId,
      name: name ?? this.name,
      teamId: teamId ?? this.teamId,
      isPlayerTeam: isPlayerTeam ?? this.isPlayerTeam,
      isSprinter: isSprinter ?? this.isSprinter,
      roleOrder: roleOrder ?? this.roleOrder,
      flatSkill: flatSkill ?? this.flatSkill,
      sprintSkill: sprintSkill ?? this.sprintSkill,
      bikeHandling: bikeHandling ?? this.bikeHandling,
      raceIq: raceIq ?? this.raceIq,
      draftingEfficiency: draftingEfficiency ?? this.draftingEfficiency,
      ftpWatts: ftpWatts ?? this.ftpWatts,
      wPrimeRemainingJoules:
          wPrimeRemainingJoules ?? this.wPrimeRemainingJoules,
      wPrimeMaxJoules: wPrimeMaxJoules ?? this.wPrimeMaxJoules,
      cda: cda ?? this.cda,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'name': name,
        'teamId': teamId,
        'isPlayerTeam': isPlayerTeam,
        'isSprinter': isSprinter,
        'roleOrder': roleOrder,
        'flatSkill': flatSkill,
        'sprintSkill': sprintSkill,
        'bikeHandling': bikeHandling,
        'raceIq': raceIq,
        'draftingEfficiency': draftingEfficiency,
        'ftpWatts': ftpWatts,
        'wPrimeRemainingJoules': wPrimeRemainingJoules,
        'wPrimeMaxJoules': wPrimeMaxJoules,
        'cda': cda,
      };

  factory EchelonTrainRiderInput.fromJson(Map<String, dynamic> json) {
    return EchelonTrainRiderInput(
      riderId: json['riderId'] as String,
      name: json['name'] as String,
      teamId: json['teamId'] as String,
      isPlayerTeam: json['isPlayerTeam'] as bool? ?? false,
      isSprinter: json['isSprinter'] as bool? ?? false,
      roleOrder: (json['roleOrder'] as num?)?.toInt() ?? 0,
      flatSkill: (json['flatSkill'] as num?)?.toDouble() ?? 75.0,
      sprintSkill: (json['sprintSkill'] as num?)?.toDouble() ?? 75.0,
      bikeHandling: (json['bikeHandling'] as num?)?.toDouble() ?? 75.0,
      raceIq: (json['raceIq'] as num?)?.toDouble() ?? 75.0,
      draftingEfficiency:
          (json['draftingEfficiency'] as num?)?.toDouble() ?? 75.0,
      ftpWatts: (json['ftpWatts'] as num?)?.toDouble() ?? 400.0,
      wPrimeRemainingJoules:
          (json['wPrimeRemainingJoules'] as num?)?.toDouble() ?? 18000.0,
      wPrimeMaxJoules:
          (json['wPrimeMaxJoules'] as num?)?.toDouble() ?? 20000.0,
      cda: (json['cda'] as num?)?.toDouble() ?? 0.30,
    );
  }
}

/// Pozycja i obciążenie aerodynamiczne pojedynczego kolarza na przekątnej wachlarza.
class DiagonalRiderSlot {
  final String riderId;
  final String name;
  final String teamId;
  final bool isPlayerTeam;
  final bool isSprinter;
  final int slotIndex;
  final double longitudinalOffsetMeters;
  final double lateralPositionMeters;
  final double lateralNormalized;
  final double draftingSavingsPercent;
  final double effectiveCrosswindExposure;
  final double requiredPowerWatts;
  final double wPrimeDrainPerSecond;
  final GutterPressureStatus gutterStatus;
  final double estimatedTimeLossPerKmSeconds;

  const DiagonalRiderSlot({
    required this.riderId,
    required this.name,
    required this.teamId,
    required this.isPlayerTeam,
    required this.isSprinter,
    required this.slotIndex,
    required this.longitudinalOffsetMeters,
    required this.lateralPositionMeters,
    required this.lateralNormalized,
    required this.draftingSavingsPercent,
    required this.effectiveCrosswindExposure,
    required this.requiredPowerWatts,
    required this.wPrimeDrainPerSecond,
    required this.gutterStatus,
    required this.estimatedTimeLossPerKmSeconds,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'name': name,
        'teamId': teamId,
        'isPlayerTeam': isPlayerTeam,
        'isSprinter': isSprinter,
        'slotIndex': slotIndex,
        'longitudinalOffsetMeters': longitudinalOffsetMeters,
        'lateralPositionMeters': lateralPositionMeters,
        'lateralNormalized': lateralNormalized,
        'draftingSavingsPercent': draftingSavingsPercent,
        'effectiveCrosswindExposure': effectiveCrosswindExposure,
        'requiredPowerWatts': requiredPowerWatts,
        'wPrimeDrainPerSecond': wPrimeDrainPerSecond,
        'gutterStatus': gutterStatus.toJson(),
        'estimatedTimeLossPerKmSeconds': estimatedTimeLossPerKmSeconds,
      };

  factory DiagonalRiderSlot.fromJson(Map<String, dynamic> json) {
    return DiagonalRiderSlot(
      riderId: json['riderId'] as String,
      name: json['name'] as String,
      teamId: json['teamId'] as String,
      isPlayerTeam: json['isPlayerTeam'] as bool? ?? false,
      isSprinter: json['isSprinter'] as bool? ?? false,
      slotIndex: (json['slotIndex'] as num).toInt(),
      longitudinalOffsetMeters:
          (json['longitudinalOffsetMeters'] as num).toDouble(),
      lateralPositionMeters: (json['lateralPositionMeters'] as num).toDouble(),
      lateralNormalized: (json['lateralNormalized'] as num).toDouble(),
      draftingSavingsPercent:
          (json['draftingSavingsPercent'] as num).toDouble(),
      effectiveCrosswindExposure:
          (json['effectiveCrosswindExposure'] as num).toDouble(),
      requiredPowerWatts: (json['requiredPowerWatts'] as num).toDouble(),
      wPrimeDrainPerSecond: (json['wPrimeDrainPerSecond'] as num).toDouble(),
      gutterStatus: GutterPressureStatus.fromJson(
        (json['gutterStatus'] as String?) ?? 'shelteredPocket',
      ),
      estimatedTimeLossPerKmSeconds:
          (json['estimatedTimeLossPerKmSeconds'] as num).toDouble(),
    );
  }
}

/// Raport zamykania krawężnika i spychanych rywali (*In the Gutter*).
class GutterTrapReport {
  final List<String> trappedRivalIds;
  final List<String> droppedRivalIds;
  final double roadCoverageRatio;
  final double gutterGapMeters;
  final bool isGutterClosed;
  final double averageTeamDraftSavingsPercent;
  final double averageRivalExposurePercent;

  const GutterTrapReport({
    required this.trappedRivalIds,
    required this.droppedRivalIds,
    required this.roadCoverageRatio,
    required this.gutterGapMeters,
    required this.isGutterClosed,
    required this.averageTeamDraftSavingsPercent,
    required this.averageRivalExposurePercent,
  });

  Map<String, dynamic> toJson() => {
        'trappedRivalIds': trappedRivalIds,
        'droppedRivalIds': droppedRivalIds,
        'roadCoverageRatio': roadCoverageRatio,
        'gutterGapMeters': gutterGapMeters,
        'isGutterClosed': isGutterClosed,
        'averageTeamDraftSavingsPercent': averageTeamDraftSavingsPercent,
        'averageRivalExposurePercent': averageRivalExposurePercent,
      };

  factory GutterTrapReport.fromJson(Map<String, dynamic> json) {
    return GutterTrapReport(
      trappedRivalIds: (json['trappedRivalIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      droppedRivalIds: (json['droppedRivalIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      roadCoverageRatio: (json['roadCoverageRatio'] as num).toDouble(),
      gutterGapMeters: (json['gutterGapMeters'] as num).toDouble(),
      isGutterClosed: json['isGutterClosed'] as bool,
      averageTeamDraftSavingsPercent:
          (json['averageTeamDraftSavingsPercent'] as num).toDouble(),
      averageRivalExposurePercent:
          (json['averageRivalExposurePercent'] as num).toDouble(),
    );
  }
}

/// Pełny wynik ewaluacji diagonalnej formacji wachlarza pociągu sprinterskiego.
class DiagonalEchelonEvaluation {
  final bool isCrosswindActive;
  final double effectiveCrosswindKmh;
  final double diagonalAngleDegrees;
  final int maxShelteredCapacity;
  final DiagonalTrainFormationMode formationMode;
  final DiagonalTrainPhase phase;
  final List<DiagonalRiderSlot> teamSlots;
  final List<DiagonalRiderSlot> rivalSlots;
  final GutterTrapReport gutterReport;
  final String tacticalSummaryPl;

  const DiagonalEchelonEvaluation({
    required this.isCrosswindActive,
    required this.effectiveCrosswindKmh,
    required this.diagonalAngleDegrees,
    required this.maxShelteredCapacity,
    required this.formationMode,
    required this.phase,
    required this.teamSlots,
    required this.rivalSlots,
    required this.gutterReport,
    required this.tacticalSummaryPl,
  });
}

/// Silnik taktyczny diagonalnej formacji wachlarza pociągu sprinterskiego na wietrze bocznym.
///
/// Gdy składowa poprzeczna wiatru przekracza próg krytyczny (18 km/h dla pociągów sprinterskich),
/// pociąg ustawia się skośnie od krawędzi nawietrznej ku zawietrznej. W trybach
/// [DiagonalTrainFormationMode.aggressiveGutterPress] oraz [DiagonalTrainFormationMode.splitAndSnap]
/// ostatni kolarze formacji zamykają lukę przy krawężniku (< 0.75 m), spychając rywali
/// w rynsztok (*In the Gutter*) bez osłony aerodynamicznej.
class TeamSprintTrainEchelonDiagonalFormation {
  TeamSprintTrainEchelonDiagonalFormation._();

  static const double crosswindActivationThresholdKmh = 18.0;
  static const double longitudinalWheelGapMeters = 2.15;
  static const double minimumCurbBufferMeters = 0.45;
  static const double gutterCloseThresholdMeters = 0.75;
  static const double minRiderLateralStepMeters = 0.65;
  static const double maxRiderLateralStepMeters = 1.35;

  /// Oblicza składową boczną wiatru [km/h] na podstawie kąta względem osi jazdy.
  static double calculateCrosswindComponentKmh({
    required double windSpeedKmh,
    required double windAngleDegrees,
  }) {
    final safeWind = math.max(0.0, windSpeedKmh);
    final normalizedAngle = (windAngleDegrees % 360.0).abs();
    final radians = normalizedAngle * (math.pi / 180.0);
    return safeWind * math.sin(radians).abs();
  }

  /// Wylicza kąt pochylenia przekątnej wachlarza [stopnie] względem osi drogi.
  static double calculateDiagonalAngleDegrees({
    required double crosswindKmh,
    required double trainSpeedKmh,
    required DiagonalTrainFormationMode mode,
  }) {
    final safeSpeed = math.max(25.0, trainSpeedKmh);
    final rawAngleRad = math.atan2(crosswindKmh, safeSpeed);
    final rawAngleDeg = rawAngleRad * (180.0 / math.pi);
    return (rawAngleDeg * (0.65 + 0.50 * mode.lateralStretchFactor))
        .clamp(4.0, 44.0);
  }

  /// Wyznacza maksymalną liczbę kolarzy mieszczących się w osłonie przed krawężnikiem.
  static int calculateMaxShelteredRiders({
    required double roadWidthMeters,
    required double lateralStepMeters,
  }) {
    final usableWidth =
        math.max(1.2, roadWidthMeters - minimumCurbBufferMeters * 1.5);
    final safeStep = math.max(minRiderLateralStepMeters, lateralStepMeters);
    return (usableWidth / safeStep).floor().clamp(2, 14);
  }

  /// Główna ewaluacja diagonalnej formacji pociągu oraz wpływu na rywali (*In the Gutter*).
  static DiagonalEchelonEvaluation evaluateDiagonalFormation({
    required DiagonalTrainWindContext context,
    required DiagonalTrainFormationMode mode,
    required List<EchelonTrainRiderInput> teamTrain,
    required List<EchelonTrainRiderInput> rivalContenders,
  }) {
    final crosswindKmh = calculateCrosswindComponentKmh(
      windSpeedKmh: context.windSpeedKmh,
      windAngleDegrees: context.windAngleDegrees,
    );
    final isCrosswindActive = crosswindKmh >= crosswindActivationThresholdKmh;
    final sortedTeam = List<EchelonTrainRiderInput>.from(teamTrain)
      ..sort((a, b) => a.roleOrder.compareTo(b.roleOrder));

    final phase = _resolvePhase(context.distanceToFinishMeters);
    final effectiveSpeedKmh =
        context.targetTrainSpeedKmh * mode.paceBoostFactor;
    final diagonalAngle = isCrosswindActive
        ? calculateDiagonalAngleDegrees(
            crosswindKmh: crosswindKmh,
            trainSpeedKmh: effectiveSpeedKmh,
            mode: mode,
          )
        : 3.5;

    final usableRoadWidth =
        math.max(2.0, context.roadWidthMeters - minimumCurbBufferMeters * 2);

    double lateralStep = minRiderLateralStepMeters;
    if (sortedTeam.length > 1) {
      final targetSpan = usableRoadWidth * mode.lateralStretchFactor;
      lateralStep = (targetSpan / (sortedTeam.length - 1)).clamp(
        minRiderLateralStepMeters,
        maxRiderLateralStepMeters,
      );
    }

    final maxSheltered = calculateMaxShelteredRiders(
      roadWidthMeters: context.roadWidthMeters,
      lateralStepMeters: lateralStep,
    );

    final teamSlots = <DiagonalRiderSlot>[];
    final speedMs = effectiveSpeedKmh / 3.6;

    for (var i = 0; i < sortedTeam.length; i++) {
      final rider = sortedTeam[i];
      final longitudinal = -i * longitudinalWheelGapMeters;
      final offsetFromWindward =
          minimumCurbBufferMeters + (isCrosswindActive ? i * lateralStep : 0.0);
      final clampedOffset = offsetFromWindward.clamp(
        minimumCurbBufferMeters,
        context.roadWidthMeters - minimumCurbBufferMeters,
      );

      final lateralPos = context.crosswindSide == CrosswindSide.leftToRight
          ? clampedOffset
          : context.roadWidthMeters - clampedOffset;

      final draftSavings = _computeTeamDraftSavings(
        slotIndex: i,
        isCrosswindActive: isCrosswindActive,
        draftingSkill: rider.draftingEfficiency,
        lateralStep: lateralStep,
        isSprinter: rider.isSprinter,
      );

      final crosswindExposure = i == 0
          ? 1.0
          : (1.0 - (draftSavings / 48.0)).clamp(0.08, 0.95);

      final requiredWatts = _computeRequiredPowerWatts(
        speedMs: speedMs,
        crosswindKmh: crosswindKmh,
        cda: rider.cda,
        draftSavingsPercent: draftSavings,
        crosswindExposure: crosswindExposure,
      );

      final wPrimeDrain = math.max(0.0, requiredWatts - rider.ftpWatts);
      final status = (i < maxSheltered)
          ? GutterPressureStatus.shelteredPocket
          : GutterPressureStatus.fightingForWheel;

      teamSlots.add(
        DiagonalRiderSlot(
          riderId: rider.riderId,
          name: rider.name,
          teamId: rider.teamId,
          isPlayerTeam: true,
          isSprinter: rider.isSprinter,
          slotIndex: i,
          longitudinalOffsetMeters: longitudinal,
          lateralPositionMeters: lateralPos,
          lateralNormalized:
              (lateralPos / context.roadWidthMeters).clamp(0.0, 1.0),
          draftingSavingsPercent: draftSavings,
          effectiveCrosswindExposure: crosswindExposure,
          requiredPowerWatts: requiredWatts,
          wPrimeDrainPerSecond: wPrimeDrain,
          gutterStatus: status,
          estimatedTimeLossPerKmSeconds: 0.0,
        ),
      );
    }

    // Wyliczamy pozostałą lukę przy krawężniku zawietrznym (gutter gap).
    final lastTeamLeewardDistance = teamSlots.isEmpty
        ? context.roadWidthMeters
        : (context.crosswindSide == CrosswindSide.leftToRight
            ? context.roadWidthMeters - teamSlots.last.lateralPositionMeters
            : teamSlots.last.lateralPositionMeters);

    final gutterGapMeters = math.max(0.0, lastTeamLeewardDistance);
    final isGutterClosed =
        isCrosswindActive && gutterGapMeters <= gutterCloseThresholdMeters;

    final rivalSlots = <DiagonalRiderSlot>[];
    final trappedIds = <String>[];
    final droppedIds = <String>[];

    final sortedRivals = List<EchelonTrainRiderInput>.from(rivalContenders)
      ..sort((a, b) {
        final scoreA =
            a.raceIq * 0.4 + a.bikeHandling * 0.35 + a.draftingEfficiency * 0.25;
        final scoreB =
            b.raceIq * 0.4 + b.bikeHandling * 0.35 + b.draftingEfficiency * 0.25;
        return scoreB.compareTo(scoreA);
      });

    final remainingProtectedSlots = math.max(
      0,
      maxSheltered - sortedTeam.length,
    );

    for (var j = 0; j < sortedRivals.length; j++) {
      final rival = sortedRivals[j];
      final globalIndex = sortedTeam.length + j;
      final positioningScore =
          rival.raceIq * 0.4 + rival.bikeHandling * 0.35 + rival.wPrimeRatio * 25.0;

      final canSqueezeInPocket = !isGutterClosed &&
          j < remainingProtectedSlots &&
          positioningScore >= 62.0;

      final GutterPressureStatus status;
      final double draftSavings;
      final double crosswindExposure;
      final double lateralPos;
      final double longitudinal;

      if (canSqueezeInPocket) {
        status = GutterPressureStatus.fightingForWheel;
        draftSavings = (26.0 * (rival.draftingEfficiency / 100.0))
            .clamp(12.0, 28.0);
        crosswindExposure = 0.45;
        final offset = (minimumCurbBufferMeters + globalIndex * lateralStep)
            .clamp(minimumCurbBufferMeters,
                context.roadWidthMeters - minimumCurbBufferMeters);
        lateralPos = context.crosswindSide == CrosswindSide.leftToRight
            ? offset
            : context.roadWidthMeters - offset;
        longitudinal = -globalIndex * longitudinalWheelGapMeters;
      } else {
        final isDropped =
            rival.wPrimeRatio < 0.22 ||
            (mode == DiagonalTrainFormationMode.splitAndSnap &&
                positioningScore < 72.0) ||
            j >= remainingProtectedSlots + 2;

        status = isDropped
            ? GutterPressureStatus.droppedFromEchelon
            : GutterPressureStatus.inTheGutter;

        if (status == GutterPressureStatus.droppedFromEchelon) {
          droppedIds.add(rival.riderId);
        } else {
          trappedIds.add(rival.riderId);
        }

        draftSavings = status == GutterPressureStatus.droppedFromEchelon
            ? 0.0
            : (5.0 * (1.0 - mode.gutterAggression * 0.65)).clamp(0.0, 6.0);
        crosswindExposure =
            status == GutterPressureStatus.droppedFromEchelon ? 1.0 : 0.92;

        // Zepchnięci pod sam krawężnik zawietrzny i wycofani na tył.
        final curbOffset = context.roadWidthMeters -
            (0.24 + (j % 2) * 0.14) -
            (status == GutterPressureStatus.droppedFromEchelon ? 0.35 : 0.0);
        lateralPos = context.crosswindSide == CrosswindSide.leftToRight
            ? curbOffset.clamp(0.2, context.roadWidthMeters - 0.15)
            : (context.roadWidthMeters - curbOffset)
                .clamp(0.15, context.roadWidthMeters - 0.2);

        final extraDropMeters =
            status == GutterPressureStatus.droppedFromEchelon
                ? 4.0 + j * 1.4
                : 1.6 + j * 0.5;
        longitudinal =
            -(sortedTeam.length * longitudinalWheelGapMeters + extraDropMeters);
      }

      final requiredWatts = _computeRequiredPowerWatts(
        speedMs: speedMs,
        crosswindKmh: crosswindKmh,
        cda: rival.cda,
        draftSavingsPercent: draftSavings,
        crosswindExposure: crosswindExposure,
      );
      final wPrimeDrain = math.max(0.0, requiredWatts - rival.ftpWatts);
      final timeLossPerKm = status == GutterPressureStatus.droppedFromEchelon
          ? 6.5 + (wPrimeDrain / 45.0)
          : (status == GutterPressureStatus.inTheGutter
              ? 1.8 + (wPrimeDrain / 80.0)
              : 0.0);

      rivalSlots.add(
        DiagonalRiderSlot(
          riderId: rival.riderId,
          name: rival.name,
          teamId: rival.teamId,
          isPlayerTeam: false,
          isSprinter: rival.isSprinter,
          slotIndex: globalIndex,
          longitudinalOffsetMeters: longitudinal,
          lateralPositionMeters: lateralPos,
          lateralNormalized:
              (lateralPos / context.roadWidthMeters).clamp(0.0, 1.0),
          draftingSavingsPercent: draftSavings,
          effectiveCrosswindExposure: crosswindExposure,
          requiredPowerWatts: requiredWatts,
          wPrimeDrainPerSecond: wPrimeDrain,
          gutterStatus: status,
          estimatedTimeLossPerKmSeconds: timeLossPerKm,
        ),
      );
    }

    final avgTeamDraft = teamSlots.isEmpty
        ? 0.0
        : teamSlots
                .map((s) => s.draftingSavingsPercent)
                .reduce((a, b) => a + b) /
            teamSlots.length;

    final avgRivalExposure = rivalSlots.isEmpty
        ? 0.0
        : rivalSlots
                .map((s) => s.effectiveCrosswindExposure * 100.0)
                .reduce((a, b) => a + b) /
            rivalSlots.length;

    final roadCoverage = teamSlots.length <= 1
        ? 0.15
        : ((teamSlots.last.lateralPositionMeters -
                        teamSlots.first.lateralPositionMeters)
                    .abs() /
                context.roadWidthMeters)
            .clamp(0.0, 1.0);

    final gutterReport = GutterTrapReport(
      trappedRivalIds: trappedIds,
      droppedRivalIds: droppedIds,
      roadCoverageRatio: roadCoverage,
      gutterGapMeters: gutterGapMeters,
      isGutterClosed: isGutterClosed,
      averageTeamDraftSavingsPercent: avgTeamDraft,
      averageRivalExposurePercent: avgRivalExposure,
    );

    final summary = _buildSummaryPl(
      isCrosswindActive: isCrosswindActive,
      crosswindKmh: crosswindKmh,
      gutterReport: gutterReport,
      mode: mode,
    );

    return DiagonalEchelonEvaluation(
      isCrosswindActive: isCrosswindActive,
      effectiveCrosswindKmh: crosswindKmh,
      diagonalAngleDegrees: diagonalAngle,
      maxShelteredCapacity: maxSheltered,
      formationMode: mode,
      phase: phase,
      teamSlots: teamSlots,
      rivalSlots: rivalSlots,
      gutterReport: gutterReport,
      tacticalSummaryPl: summary,
    );
  }

  /// Wykonuje krok symulacji [dtSeconds] aktualizując W' kolarzy w pociągu i rywali.
  static ({
    List<EchelonTrainRiderInput> updatedTeam,
    List<EchelonTrainRiderInput> updatedRivals,
    DiagonalEchelonEvaluation evaluation,
  }) stepSimulationTick({
    required DiagonalTrainWindContext context,
    required DiagonalTrainFormationMode mode,
    required List<EchelonTrainRiderInput> teamTrain,
    required List<EchelonTrainRiderInput> rivalContenders,
    double dtSeconds = 5.0,
  }) {
    final evaluation = evaluateDiagonalFormation(
      context: context,
      mode: mode,
      teamTrain: teamTrain,
      rivalContenders: rivalContenders,
    );

    final teamSlotMap = {
      for (final slot in evaluation.teamSlots) slot.riderId: slot,
    };
    final rivalSlotMap = {
      for (final slot in evaluation.rivalSlots) slot.riderId: slot,
    };

    final updatedTeam = teamTrain.map((rider) {
      final slot = teamSlotMap[rider.riderId];
      if (slot == null) return rider;
      final nextWPrime = _updateWPrime(
        rider: rider,
        requiredWatts: slot.requiredPowerWatts,
        dtSeconds: dtSeconds,
      );
      return rider.copyWith(wPrimeRemainingJoules: nextWPrime);
    }).toList();

    final updatedRivals = rivalContenders.map((rider) {
      final slot = rivalSlotMap[rider.riderId];
      if (slot == null) return rider;
      final nextWPrime = _updateWPrime(
        rider: rider,
        requiredWatts: slot.requiredPowerWatts,
        dtSeconds: dtSeconds,
      );
      return rider.copyWith(wPrimeRemainingJoules: nextWPrime);
    }).toList();

    final nextEval = evaluateDiagonalFormation(
      context: context,
      mode: mode,
      teamTrain: updatedTeam,
      rivalContenders: updatedRivals,
    );

    return (
      updatedTeam: updatedTeam,
      updatedRivals: updatedRivals,
      evaluation: nextEval,
    );
  }

  static double _updateWPrime({
    required EchelonTrainRiderInput rider,
    required double requiredWatts,
    required double dtSeconds,
  }) {
    final delta = requiredWatts - rider.ftpWatts;
    if (delta > 0) {
      return math.max(0.0, rider.wPrimeRemainingJoules - delta * dtSeconds);
    } else {
      final recoveryRate = (-delta) * 0.35;
      return math.min(
        rider.wPrimeMaxJoules,
        rider.wPrimeRemainingJoules + recoveryRate * dtSeconds,
      );
    }
  }

  static DiagonalTrainPhase _resolvePhase(double distanceToFinishMeters) {
    if (distanceToFinishMeters > 3000.0) {
      return DiagonalTrainPhase.positioning;
    } else if (distanceToFinishMeters > 1500.0) {
      return DiagonalTrainPhase.diagonalLock;
    } else if (distanceToFinishMeters > 350.0) {
      return DiagonalTrainPhase.gutterSqueeze;
    }
    return DiagonalTrainPhase.sprintLaunch;
  }

  static double _computeTeamDraftSavings({
    required int slotIndex,
    required bool isCrosswindActive,
    required double draftingSkill,
    required double lateralStep,
    required bool isSprinter,
  }) {
    if (slotIndex == 0) return 0.0;
    final skillFactor = (0.75 + 0.25 * (draftingSkill / 100.0)).clamp(0.7, 1.05);
    final baseDraft = isCrosswindActive ? 38.0 : 32.0;
    final stepEfficiency =
        (1.0 - ((lateralStep - 0.85).abs() * 0.14)).clamp(0.80, 1.02);
    final sprinterBonus = isSprinter ? 4.5 : 0.0;
    return ((baseDraft * skillFactor * stepEfficiency) + sprinterBonus)
        .clamp(12.0, 48.0);
  }

  static double _computeRequiredPowerWatts({
    required double speedMs,
    required double crosswindKmh,
    required double cda,
    required double draftSavingsPercent,
    required double crosswindExposure,
  }) {
    const airDensity = 1.225;
    const rollingWatts = 38.0;
    final crosswindMs = crosswindKmh / 3.6;
    final effectiveAirSpeed =
        math.sqrt(speedMs * speedMs + math.pow(crosswindMs * crosswindExposure, 2));
    final aeroFactor = (1.0 - draftSavingsPercent / 100.0).clamp(0.45, 1.0);
    final aeroWatts =
        0.5 * airDensity * cda * aeroFactor * math.pow(effectiveAirSpeed, 2) * speedMs;
    return (aeroWatts + rollingWatts).clamp(180.0, 1350.0);
  }

  static String _buildSummaryPl({
    required bool isCrosswindActive,
    required double crosswindKmh,
    required GutterTrapReport gutterReport,
    required DiagonalTrainFormationMode mode,
  }) {
    if (!isCrosswindActive) {
      return 'Wiatr boczny (${crosswindKmh.toStringAsFixed(1)} km/h) poniżej progu wachlarza — klasyczny pociąg.';
    }
    if (gutterReport.isGutterClosed) {
      final totalAffected =
          gutterReport.trappedRivalIds.length + gutterReport.droppedRivalIds.length;
      return 'Krawężnik zamknięty (${gutterReport.gutterGapMeters.toStringAsFixed(2)} m)! '
          '$totalAffected rywali zepchniętych *In the Gutter* (${mode.labelPl}).';
    }
    return 'Wachlarz ${mode.labelPl} aktywny (${crosswindKmh.toStringAsFixed(1)} km/h) — '
        'luka przy krawężniku: ${gutterReport.gutterGapMeters.toStringAsFixed(2)} m.';
  }
}

/// Produkcyjny panel taktyczny wizualizujący diagonalną formację wachlarza
/// oraz spychanych rywali pod krawężnik (*In the Gutter*).
class TeamSprintTrainEchelonDiagonalPanel extends StatefulWidget {
  final DiagonalTrainWindContext? initialContext;
  final DiagonalTrainFormationMode initialMode;
  final List<EchelonTrainRiderInput>? initialTeamTrain;
  final List<EchelonTrainRiderInput>? initialRivals;

  const TeamSprintTrainEchelonDiagonalPanel({
    super.key,
    this.initialContext,
    this.initialMode = DiagonalTrainFormationMode.aggressiveGutterPress,
    this.initialTeamTrain,
    this.initialRivals,
  });

  @override
  State<TeamSprintTrainEchelonDiagonalPanel> createState() =>
      _TeamSprintTrainEchelonDiagonalPanelState();
}

class _TeamSprintTrainEchelonDiagonalPanelState
    extends State<TeamSprintTrainEchelonDiagonalPanel>
    with SingleTickerProviderStateMixin {
  late DiagonalTrainWindContext _context;
  late DiagonalTrainFormationMode _mode;
  late List<EchelonTrainRiderInput> _teamTrain;
  late List<EchelonTrainRiderInput> _rivals;
  late DiagonalEchelonEvaluation _evaluation;
  late AnimationController _pulseController;
  String? _hoveredRiderId;
  String? _selectedRiderId;

  @override
  void initState() {
    super.initState();
    _context = widget.initialContext ?? _defaultContext();
    _mode = widget.initialMode;
    _teamTrain = widget.initialTeamTrain ?? _defaultTeamTrain();
    _rivals = widget.initialRivals ?? _defaultRivals();
    _evaluation = TeamSprintTrainEchelonDiagonalFormation.evaluateDiagonalFormation(
      context: _context,
      mode: _mode,
      teamTrain: _teamTrain,
      rivalContenders: _rivals,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  DiagonalTrainWindContext _defaultContext() => const DiagonalTrainWindContext(
        windSpeedKmh: 34.0,
        windAngleDegrees: 78.0,
        crosswindSide: CrosswindSide.leftToRight,
        roadWidthMeters: 6.4,
        distanceToFinishMeters: 1650.0,
        targetTrainSpeedKmh: 58.0,
      );

  List<EchelonTrainRiderInput> _defaultTeamTrain() => const [
        EchelonTrainRiderInput(
          riderId: 'team_1',
          name: 'M. Kowalski',
          teamId: 'player',
          isPlayerTeam: true,
          isSprinter: false,
          roleOrder: 0,
          flatSkill: 88,
          sprintSkill: 70,
          bikeHandling: 86,
          raceIq: 84,
          draftingEfficiency: 85,
          ftpWatts: 435,
          wPrimeRemainingJoules: 19500,
          wPrimeMaxJoules: 21000,
        ),
        EchelonTrainRiderInput(
          riderId: 'team_2',
          name: 'L. Van Dijk',
          teamId: 'player',
          isPlayerTeam: true,
          isSprinter: false,
          roleOrder: 1,
          flatSkill: 86,
          sprintSkill: 76,
          bikeHandling: 88,
          raceIq: 85,
          draftingEfficiency: 88,
          ftpWatts: 420,
          wPrimeRemainingJoules: 18500,
          wPrimeMaxJoules: 20000,
        ),
        EchelonTrainRiderInput(
          riderId: 'team_3',
          name: 'T. Mercier',
          teamId: 'player',
          isPlayerTeam: true,
          isSprinter: false,
          roleOrder: 2,
          flatSkill: 84,
          sprintSkill: 82,
          bikeHandling: 89,
          raceIq: 87,
          draftingEfficiency: 90,
          ftpWatts: 410,
          wPrimeRemainingJoules: 19000,
          wPrimeMaxJoules: 20000,
        ),
        EchelonTrainRiderInput(
          riderId: 'team_4',
          name: 'J. Zieliński',
          teamId: 'player',
          isPlayerTeam: true,
          isSprinter: false,
          roleOrder: 3,
          flatSkill: 82,
          sprintSkill: 88,
          bikeHandling: 90,
          raceIq: 91,
          draftingEfficiency: 92,
          ftpWatts: 405,
          wPrimeRemainingJoules: 21000,
          wPrimeMaxJoules: 22000,
        ),
        EchelonTrainRiderInput(
          riderId: 'team_5',
          name: 'F. Bellini (Sprinter)',
          teamId: 'player',
          isPlayerTeam: true,
          isSprinter: true,
          roleOrder: 4,
          flatSkill: 79,
          sprintSkill: 96,
          bikeHandling: 91,
          raceIq: 89,
          draftingEfficiency: 94,
          ftpWatts: 390,
          wPrimeRemainingJoules: 24500,
          wPrimeMaxJoules: 25000,
        ),
      ];

  List<EchelonTrainRiderInput> _defaultRivals() => const [
        EchelonTrainRiderInput(
          riderId: 'rival_1',
          name: 'D. Groenewegen',
          teamId: 'rival_a',
          isPlayerTeam: false,
          isSprinter: true,
          roleOrder: 0,
          flatSkill: 78,
          sprintSkill: 94,
          bikeHandling: 81,
          raceIq: 80,
          draftingEfficiency: 82,
          ftpWatts: 388,
          wPrimeRemainingJoules: 16200,
          wPrimeMaxJoules: 23000,
        ),
        EchelonTrainRiderInput(
          riderId: 'rival_2',
          name: 'S. Bennett',
          teamId: 'rival_b',
          isPlayerTeam: false,
          isSprinter: true,
          roleOrder: 1,
          flatSkill: 76,
          sprintSkill: 91,
          bikeHandling: 74,
          raceIq: 75,
          draftingEfficiency: 76,
          ftpWatts: 380,
          wPrimeRemainingJoules: 11800,
          wPrimeMaxJoules: 21000,
        ),
        EchelonTrainRiderInput(
          riderId: 'rival_3',
          name: 'C. Ewan',
          teamId: 'rival_c',
          isPlayerTeam: false,
          isSprinter: true,
          roleOrder: 2,
          flatSkill: 73,
          sprintSkill: 92,
          bikeHandling: 72,
          raceIq: 71,
          draftingEfficiency: 74,
          ftpWatts: 365,
          wPrimeRemainingJoules: 4200,
          wPrimeMaxJoules: 21000,
        ),
      ];

  void _recalculate() {
    setState(() {
      _evaluation =
          TeamSprintTrainEchelonDiagonalFormation.evaluateDiagonalFormation(
        context: _context,
        mode: _mode,
        teamTrain: _teamTrain,
        rivalContenders: _rivals,
      );
      _pulseController
        ..reset()
        ..forward();
    });
  }

  void _advanceTick() {
    if (_teamTrain.isEmpty) return;
    final result = TeamSprintTrainEchelonDiagonalFormation.stepSimulationTick(
      context: _context.copyWith(
        distanceToFinishMeters:
            math.max(200.0, _context.distanceToFinishMeters - 80.0),
      ),
      mode: _mode,
      teamTrain: _teamTrain,
      rivalContenders: _rivals,
      dtSeconds: 5.0,
    );
    setState(() {
      _context = _context.copyWith(
        distanceToFinishMeters:
            math.max(200.0, _context.distanceToFinishMeters - 80.0),
      );
      _teamTrain = result.updatedTeam;
      _rivals = result.updatedRivals;
      _evaluation = result.evaluation;
      _pulseController
        ..reset()
        ..forward();
    });
  }

  void _resetSimulation() {
    setState(() {
      _context = widget.initialContext ?? _defaultContext();
      _mode = widget.initialMode;
      _teamTrain = widget.initialTeamTrain ?? _defaultTeamTrain();
      _rivals = widget.initialRivals ?? _defaultRivals();
      _selectedRiderId = null;
      _evaluation =
          TeamSprintTrainEchelonDiagonalFormation.evaluateDiagonalFormation(
        context: _context,
        mode: _mode,
        teamTrain: _teamTrain,
        rivalContenders: _rivals,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 960;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: _buildRoadCanvasCard()),
                      const SizedBox(width: 16),
                      Expanded(flex: 5, child: _buildControlsAndTelemetry()),
                    ],
                  )
                else ...[
                  _buildRoadCanvasCard(),
                  const SizedBox(height: 14),
                  _buildControlsAndTelemetry(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final gutterClosed = _evaluation.gutterReport.isGutterClosed;
    final badgeColor =
        gutterClosed ? AppColors.crimsonAlert : AppColors.accentBlue;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wachlarz Diagonalny Pociągu Sprinterskiego',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _evaluation.tacticalSummaryPl,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: badgeColor.withValues(alpha: 0.6)),
            ),
            child: Text(
              gutterClosed
                  ? 'IN THE GUTTER (${_evaluation.gutterReport.trappedRivalIds.length + _evaluation.gutterReport.droppedRivalIds.length})'
                  : _evaluation.phase.labelPl,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: badgeColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadCanvasCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Kąt Przekątnej: ${_evaluation.diagonalAngleDegrees.toStringAsFixed(1)}°',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'Luka przy Krawężniku: ${_evaluation.gutterReport.gutterGapMeters.toStringAsFixed(2)} m',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _evaluation.gutterReport.isGutterClosed
                      ? AppColors.crimsonAlert
                      : AppColors.statusSuccess,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 290,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _DiagonalEchelonRoadPainter(
                    evaluation: _evaluation,
                    contextData: _context,
                    hoveredRiderId: _hoveredRiderId,
                    selectedRiderId: _selectedRiderId,
                    animProgress: Curves.easeOutCubic
                        .transform(_pulseController.value),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          _buildRiderChipsRow(),
        ],
      ),
    );
  }

  Widget _buildRiderChipsRow() {
    final allSlots = [..._evaluation.teamSlots, ..._evaluation.rivalSlots];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: allSlots.map((slot) {
        final isSelected = _selectedRiderId == slot.riderId;
        final isHovered = _hoveredRiderId == slot.riderId;
        final color = slot.isPlayerTeam
            ? (slot.isSprinter ? AppColors.goldAccent : AppColors.accentBlue)
            : (slot.gutterStatus == GutterPressureStatus.droppedFromEchelon ||
                    slot.gutterStatus == GutterPressureStatus.inTheGutter
                ? AppColors.crimsonAlert
                : AppColors.amberWarning);
        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredRiderId = slot.riderId),
          onExit: (_) => setState(() => _hoveredRiderId = null),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() {
              _selectedRiderId = isSelected ? null : slot.riderId;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.24)
                    : (isHovered
                        ? AppColors.surfaceLight
                        : AppColors.background),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : AppColors.cardBorder,
                ),
              ),
              child: Text(
                '${slot.name.split(' ').last}: ${slot.requiredPowerWatts.round()}W',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildControlsAndTelemetry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tryb Formacji Wachlarza',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DiagonalTrainFormationMode.values.map((m) {
                  return _TacticalModeButton(
                    label: m.labelPl,
                    isSelected: _mode == m,
                    onTap: () {
                      _mode = m;
                      _recalculate();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TacticalModeButton(
                      label: CrosswindSide.leftToRight.labelPl,
                      isSelected:
                          _context.crosswindSide == CrosswindSide.leftToRight,
                      onTap: () {
                        _context = _context.copyWith(
                          crosswindSide: CrosswindSide.leftToRight,
                        );
                        _recalculate();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TacticalModeButton(
                      label: CrosswindSide.rightToLeft.labelPl,
                      isSelected:
                          _context.crosswindSide == CrosswindSide.rightToLeft,
                      onTap: () {
                        _context = _context.copyWith(
                          crosswindSide: CrosswindSide.rightToLeft,
                        );
                        _recalculate();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSliderRow(
                label: 'Wiatr Boczny',
                valueLabel: '${_context.windSpeedKmh.round()} km/h',
                value: _context.windSpeedKmh,
                min: 10.0,
                max: 55.0,
                onChanged: (v) {
                  _context = _context.copyWith(windSpeedKmh: v);
                  _recalculate();
                },
              ),
              _buildSliderRow(
                label: 'Szerokość Szosy',
                valueLabel: '${_context.roadWidthMeters.toStringAsFixed(1)} m',
                value: _context.roadWidthMeters,
                min: 4.5,
                max: 9.0,
                onChanged: (v) {
                  _context = _context.copyWith(roadWidthMeters: v);
                  _recalculate();
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Symuluj 5s',
                      isPrimary: true,
                      enabled: _teamTrain.isNotEmpty,
                      onPressed: _advanceTick,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: 'Reset',
                      isPrimary: false,
                      enabled: true,
                      onPressed: _resetSimulation,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildTelemetrySummaryCard(),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              valueLabel,
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
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryAccent,
            inactiveTrackColor: AppColors.surfaceLight,
            thumbColor: AppColors.goldAccent,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetrySummaryCard() {
    final report = _evaluation.gutterReport;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MetricTile(
              title: 'Draft Zespołu',
              value:
                  '${report.averageTeamDraftSavingsPercent.toStringAsFixed(1)}%',
              valueColor: AppColors.statusSuccess,
            ),
          ),
          Expanded(
            child: _MetricTile(
              title: 'Ekspozycja Rywali',
              value: '${report.averageRivalExposurePercent.toStringAsFixed(0)}%',
              valueColor: AppColors.crimsonAlert,
            ),
          ),
          Expanded(
            child: _MetricTile(
              title: 'Pokrycie Szosy',
              value: '${(report.roadCoverageRatio * 100).toStringAsFixed(0)}%',
              valueColor: AppColors.accentBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _TacticalModeButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TacticalModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TacticalModeButton> createState() => _TacticalModeButtonState();
}

class _TacticalModeButtonState extends State<_TacticalModeButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? AppColors.primaryAccent.withValues(alpha: 0.25)
        : (_hovered ? AppColors.surfaceLight : AppColors.background);
    final borderColor = widget.isSelected
        ? AppColors.primaryAccent
        : (_focused ? AppColors.goldAccent : AppColors.cardBorder);

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              color: widget.isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.isPrimary,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceLight;
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : (_hovered ? baseColor.withValues(alpha: 0.85) : baseColor);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused ? AppColors.goldAccent : AppColors.cardBorder,
            ),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: widget.enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _DiagonalEchelonRoadPainter extends CustomPainter {
  final DiagonalEchelonEvaluation evaluation;
  final DiagonalTrainWindContext contextData;
  final String? hoveredRiderId;
  final String? selectedRiderId;
  final double animProgress;

  const _DiagonalEchelonRoadPainter({
    required this.evaluation,
    required this.contextData,
    required this.hoveredRiderId,
    required this.selectedRiderId,
    required this.animProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final roadRect = Rect.fromLTWH(16, 12, size.width - 32, size.height - 24);
    final roadRRect =
        RRect.fromRectAndRadius(roadRect, const Radius.circular(12));

    // Asfalt
    canvas.drawRRect(
      roadRRect,
      Paint()..color = AppColors.background,
    );

    // Strefa rynsztoka (Gutter Danger Zone) po stronie zawietrznej
    final leewardOnRight =
        contextData.crosswindSide == CrosswindSide.leftToRight;
    const gutterWidth = 18.0;
    final gutterRect = leewardOnRight
        ? Rect.fromLTWH(
            roadRect.right - gutterWidth,
            roadRect.top,
            gutterWidth,
            roadRect.height,
          )
        : Rect.fromLTWH(
            roadRect.left,
            roadRect.top,
            gutterWidth,
            roadRect.height,
          );
    canvas.drawRect(
      gutterRect,
      Paint()
        ..color = evaluation.gutterReport.isGutterClosed
            ? AppColors.crimsonAlert.withValues(alpha: 0.25)
            : AppColors.amberWarning.withValues(alpha: 0.10),
    );

    // Krawężniki
    final curbPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 2.0;
    canvas.drawLine(
      roadRect.topLeft,
      roadRect.bottomLeft,
      curbPaint,
    );
    canvas.drawLine(
      roadRect.topRight,
      roadRect.bottomRight,
      curbPaint,
    );

    // Linia przerywana osi jezdni
    final centerPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.25)
      ..strokeWidth = 1.5;
    for (var y = roadRect.top + 8; y < roadRect.bottom - 8; y += 22) {
      canvas.drawLine(
        Offset(roadRect.center.dx, y),
        Offset(roadRect.center.dx, math.min(y + 11, roadRect.bottom - 8)),
        centerPaint,
      );
    }

    // Wektory wiatru bocznego
    final windPaint = Paint()
      ..color = AppColors.cyanAccent.withValues(alpha: 0.35)
      ..strokeWidth = 1.6;
    for (var i = 0; i < 3; i++) {
      final y = roadRect.top + 48 + i * 75;
      final startX = leewardOnRight ? roadRect.left + 8 : roadRect.right - 8;
      final endX = leewardOnRight ? roadRect.left + 38 : roadRect.right - 38;
      canvas.drawLine(Offset(startX, y), Offset(endX, y + 10), windPaint);
    }

    Offset slotToCanvas(DiagonalRiderSlot slot) {
      final x = roadRect.left +
          14 +
          slot.lateralNormalized * (roadRect.width - 28);
      final normalizedY =
          ((-slot.longitudinalOffsetMeters) / 20.0).clamp(0.0, 1.0);
      final y = roadRect.top + 26 + normalizedY * (roadRect.height - 52);
      return Offset(x, y * (0.94 + 0.06 * animProgress));
    }

    // Linia przekątnej zespołu
    if (evaluation.teamSlots.length > 1) {
      final linePaint = Paint()
        ..color = AppColors.accentBlue.withValues(alpha: 0.45)
        ..strokeWidth = 2.0;
      for (var i = 0; i < evaluation.teamSlots.length - 1; i++) {
        canvas.drawLine(
          slotToCanvas(evaluation.teamSlots[i]),
          slotToCanvas(evaluation.teamSlots[i + 1]),
          linePaint,
        );
      }
    }

    // Rysowanie kolarzy
    for (final slot in [...evaluation.teamSlots, ...evaluation.rivalSlots]) {
      final pos = slotToCanvas(slot);
      final isFocused =
          slot.riderId == hoveredRiderId || slot.riderId == selectedRiderId;
      final color = slot.isPlayerTeam
          ? (slot.isSprinter ? AppColors.goldAccent : AppColors.accentBlue)
          : (slot.gutterStatus == GutterPressureStatus.droppedFromEchelon ||
                  slot.gutterStatus == GutterPressureStatus.inTheGutter
              ? AppColors.crimsonAlert
              : AppColors.amberWarning);

      if (isFocused) {
        canvas.drawCircle(
          pos,
          12,
          Paint()..color = color.withValues(alpha: 0.28),
        );
      }
      canvas.drawCircle(pos, slot.isSprinter ? 7.5 : 6.0, Paint()..color = color);
      canvas.drawCircle(
        pos,
        slot.isSprinter ? 7.5 : 6.0,
        Paint()
          ..color = AppColors.textPrimary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalEchelonRoadPainter oldDelegate) {
    return oldDelegate.evaluation != evaluation ||
        oldDelegate.hoveredRiderId != hoveredRiderId ||
        oldDelegate.selectedRiderId != selectedRiderId ||
        oldDelegate.animProgress != animProgress;
  }
}
