import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Typ przeszkody lub zakrętu na ostatnich 3 km sprintu.
enum SprintFinalCornerSeverity {
  sweeping('Łagodny łuk', 0.15, AppColors.accentBlue),
  technical90('Zakręt 90°', 0.55, AppColors.amberWarning),
  hairpin180('Nawrót 180°', 0.90, AppColors.crimsonAlert),
  roundabout('Rondo', 0.70, AppColors.amberWarning),
  chicane('Szykana', 0.65, AppColors.amberWarning);

  final String label;
  final double riskWeight;
  final Color badgeColor;
  const SprintFinalCornerSeverity(this.label, this.riskWeight, this.badgeColor);
}

/// Rola kolarza w końcówce sprinterskiej.
enum SprintRiderRoleTag {
  sprinter('Sprinter', 'SPR'),
  leadout('Rozprowadzający', 'L/O'),
  protector('Pomocnik', 'DOM'),
  rivalSprinter('Rywal', 'RYW'),
  breakawaySurvivor('Uciekinier', 'UCI');

  final String label;
  final String shortTag;
  const SprintRiderRoleTag(this.label, this.shortTag);
}

/// Zakres widoku mapy taktycznej ostatnich 3 km.
enum SprintMapViewMode {
  fullFinal3km('3.0 km', 3000.0),
  finalKilometer('1.0 km', 1000.0),
  final250mSlingshot('250 m', 250.0);

  final String label;
  final double windowMeters;
  const SprintMapViewMode(this.label, this.windowMeters);
}

/// Rozkaz taktyczny wydawany na ostatnich 3 km sprintu.
enum SprintLineOrder {
  followTrain('Trzymaj Pociąg', Icons.linear_scale_rounded, AppColors.accentBlue),
  surfRivalWheel('Skocz na Koło', Icons.swap_calls_rounded, AppColors.cyanAccent),
  launchLeadout('Odpal Pociąg', Icons.bolt_rounded, AppColors.amberWarning),
  openSprintNow('Atakuj Finisz!', Icons.flag_rounded, AppColors.goldAccent);

  final String label;
  final IconData icon;
  final Color accentColor;
  const SprintLineOrder(this.label, this.icon, this.accentColor);
}

/// Opis zakrętu lub zwężenia na trasie ostatnich 3 km.
class SprintRoadCornerMarker {
  final double distanceToFinishMeters;
  final double angleDegrees;
  final SprintFinalCornerSeverity severity;
  final String label;
  final double recommendedEntryLine; // -1.0 (lewa) .. +1.0 (prawa)
  final double pinchWidthMeters;

  const SprintRoadCornerMarker({
    required this.distanceToFinishMeters,
    required this.angleDegrees,
    required this.severity,
    required this.label,
    this.recommendedEntryLine = 0.0,
    this.pinchWidthMeters = 7.0,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'distanceToFinishMeters': distanceToFinishMeters,
        'angleDegrees': angleDegrees,
        'severity': severity.name,
        'label': label,
        'recommendedEntryLine': recommendedEntryLine,
        'pinchWidthMeters': pinchWidthMeters,
      };

  factory SprintRoadCornerMarker.fromJson(Map<String, dynamic> json) {
    final severityName = json['severity'] as String? ?? 'sweeping';
    final severity = SprintFinalCornerSeverity.values.firstWhere(
      (e) => e.name == severityName,
      orElse: () => SprintFinalCornerSeverity.sweeping,
    );
    return SprintRoadCornerMarker(
      distanceToFinishMeters: (json['distanceToFinishMeters'] as num?)?.toDouble() ?? 1000.0,
      angleDegrees: (json['angleDegrees'] as num?)?.toDouble() ?? 30.0,
      severity: severity,
      label: json['label'] as String? ?? 'Zakręt',
      recommendedEntryLine: (json['recommendedEntryLine'] as num?)?.toDouble() ?? 0.0,
      pinchWidthMeters: (json['pinchWidthMeters'] as num?)?.toDouble() ?? 7.0,
    );
  }
}

/// Reprezentacja pojedynczego kolarza na mapie taktycznej ostatnich 3 km.
class SprintTacticalRiderDot {
  final String riderId;
  final String name;
  final String shortCode;
  final String teamName;
  final Color teamColor;
  final bool isPlayerTeam;
  final SprintRiderRoleTag role;
  final double distanceToFinishMeters;
  final double lateralOffsetNormalized; // -1.0 (lewa barierka) .. +1.0 (prawa barierka)
  final double speedKmh;
  final int powerWatts;
  final double wPrimePercent; // 0.0 .. 100.0
  final int cadenceRpm;
  final bool isDrafting;
  final double draftSavingsPercent;
  final bool isBoxedIn;
  final String? targetWheelRiderId;

  const SprintTacticalRiderDot({
    required this.riderId,
    required this.name,
    required this.shortCode,
    required this.teamName,
    required this.teamColor,
    required this.isPlayerTeam,
    required this.role,
    required this.distanceToFinishMeters,
    required this.lateralOffsetNormalized,
    required this.speedKmh,
    required this.powerWatts,
    required this.wPrimePercent,
    required this.cadenceRpm,
    this.isDrafting = true,
    this.draftSavingsPercent = 0.0,
    this.isBoxedIn = false,
    this.targetWheelRiderId,
  });

  SprintTacticalRiderDot copyWith({
    double? distanceToFinishMeters,
    double? lateralOffsetNormalized,
    double? speedKmh,
    int? powerWatts,
    double? wPrimePercent,
    int? cadenceRpm,
    bool? isDrafting,
    double? draftSavingsPercent,
    bool? isBoxedIn,
    String? targetWheelRiderId,
  }) {
    return SprintTacticalRiderDot(
      riderId: riderId,
      name: name,
      shortCode: shortCode,
      teamName: teamName,
      teamColor: teamColor,
      isPlayerTeam: isPlayerTeam,
      role: role,
      distanceToFinishMeters: distanceToFinishMeters ?? this.distanceToFinishMeters,
      lateralOffsetNormalized: lateralOffsetNormalized ?? this.lateralOffsetNormalized,
      speedKmh: speedKmh ?? this.speedKmh,
      powerWatts: powerWatts ?? this.powerWatts,
      wPrimePercent: wPrimePercent ?? this.wPrimePercent,
      cadenceRpm: cadenceRpm ?? this.cadenceRpm,
      isDrafting: isDrafting ?? this.isDrafting,
      draftSavingsPercent: draftSavingsPercent ?? this.draftSavingsPercent,
      isBoxedIn: isBoxedIn ?? this.isBoxedIn,
      targetWheelRiderId: targetWheelRiderId ?? this.targetWheelRiderId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'riderId': riderId,
        'name': name,
        'shortCode': shortCode,
        'teamName': teamName,
        'teamColor': teamColor.toARGB32(),
        'isPlayerTeam': isPlayerTeam,
        'role': role.name,
        'distanceToFinishMeters': distanceToFinishMeters,
        'lateralOffsetNormalized': lateralOffsetNormalized,
        'speedKmh': speedKmh,
        'powerWatts': powerWatts,
        'wPrimePercent': wPrimePercent,
        'cadenceRpm': cadenceRpm,
        'isDrafting': isDrafting,
        'draftSavingsPercent': draftSavingsPercent,
        'isBoxedIn': isBoxedIn,
        'targetWheelRiderId': targetWheelRiderId,
      };

  factory SprintTacticalRiderDot.fromJson(Map<String, dynamic> json) {
    final roleName = json['role'] as String? ?? 'sprinter';
    final role = SprintRiderRoleTag.values.firstWhere(
      (e) => e.name == roleName,
      orElse: () => SprintRiderRoleTag.sprinter,
    );
    return SprintTacticalRiderDot(
      riderId: json['riderId'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Kolarz',
      shortCode: json['shortCode'] as String? ?? 'RID',
      teamName: json['teamName'] as String? ?? 'Team',
      teamColor: Color(json['teamColor'] as int? ?? 0xFF38BDF8),
      isPlayerTeam: json['isPlayerTeam'] as bool? ?? false,
      role: role,
      distanceToFinishMeters: (json['distanceToFinishMeters'] as num?)?.toDouble() ?? 1000.0,
      lateralOffsetNormalized: (json['lateralOffsetNormalized'] as num?)?.toDouble() ?? 0.0,
      speedKmh: (json['speedKmh'] as num?)?.toDouble() ?? 58.0,
      powerWatts: (json['powerWatts'] as num?)?.toInt() ?? 420,
      wPrimePercent: (json['wPrimePercent'] as num?)?.toDouble() ?? 80.0,
      cadenceRpm: (json['cadenceRpm'] as num?)?.toInt() ?? 98,
      isDrafting: json['isDrafting'] as bool? ?? true,
      draftSavingsPercent: (json['draftSavingsPercent'] as num?)?.toDouble() ?? 0.0,
      isBoxedIn: json['isBoxedIn'] as bool? ?? false,
      targetWheelRiderId: json['targetWheelRiderId'] as String?,
    );
  }
}

/// Pełny pakiet danych telemetrycznych dla mapy taktycznej ostatnich 3 km.
class SprintFinal3kmTelemetryData {
  final String stageName;
  final double windSpeedKmh;
  final double windDirectionDegrees; // 0 = w twarz, 180 = w plecy, 90/-90 = boczny
  final double roadWidthMeters;
  final double surfaceWetness; // 0.0 = sucho, 1.0 = ulewa
  final double distanceToFinishMeters;
  final List<SprintTacticalRiderDot> riders;
  final List<SprintRoadCornerMarker> corners;
  final String? selectedRiderId;
  final SprintLineOrder activeOrder;
  final bool isSprintActive;

  const SprintFinal3kmTelemetryData({
    required this.stageName,
    required this.windSpeedKmh,
    required this.windDirectionDegrees,
    required this.roadWidthMeters,
    required this.surfaceWetness,
    required this.distanceToFinishMeters,
    required this.riders,
    required this.corners,
    this.selectedRiderId,
    this.activeOrder = SprintLineOrder.followTrain,
    this.isSprintActive = true,
  });

  SprintFinal3kmTelemetryData copyWith({
    String? stageName,
    double? windSpeedKmh,
    double? windDirectionDegrees,
    double? roadWidthMeters,
    double? surfaceWetness,
    double? distanceToFinishMeters,
    List<SprintTacticalRiderDot>? riders,
    List<SprintRoadCornerMarker>? corners,
    String? selectedRiderId,
    SprintLineOrder? activeOrder,
    bool? isSprintActive,
  }) {
    return SprintFinal3kmTelemetryData(
      stageName: stageName ?? this.stageName,
      windSpeedKmh: windSpeedKmh ?? this.windSpeedKmh,
      windDirectionDegrees: windDirectionDegrees ?? this.windDirectionDegrees,
      roadWidthMeters: roadWidthMeters ?? this.roadWidthMeters,
      surfaceWetness: surfaceWetness ?? this.surfaceWetness,
      distanceToFinishMeters: distanceToFinishMeters ?? this.distanceToFinishMeters,
      riders: riders ?? this.riders,
      corners: corners ?? this.corners,
      selectedRiderId: selectedRiderId ?? this.selectedRiderId,
      activeOrder: activeOrder ?? this.activeOrder,
      isSprintActive: isSprintActive ?? this.isSprintActive,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'stageName': stageName,
        'windSpeedKmh': windSpeedKmh,
        'windDirectionDegrees': windDirectionDegrees,
        'roadWidthMeters': roadWidthMeters,
        'surfaceWetness': surfaceWetness,
        'distanceToFinishMeters': distanceToFinishMeters,
        'riders': riders.map((r) => r.toJson()).toList(),
        'corners': corners.map((c) => c.toJson()).toList(),
        'selectedRiderId': selectedRiderId,
        'activeOrder': activeOrder.name,
        'isSprintActive': isSprintActive,
      };

  factory SprintFinal3kmTelemetryData.fromJson(Map<String, dynamic> json) {
    final orderName = json['activeOrder'] as String? ?? 'followTrain';
    final order = SprintLineOrder.values.firstWhere(
      (e) => e.name == orderName,
      orElse: () => SprintLineOrder.followTrain,
    );
    return SprintFinal3kmTelemetryData(
      stageName: json['stageName'] as String? ?? 'Finisz Sprinterski',
      windSpeedKmh: (json['windSpeedKmh'] as num?)?.toDouble() ?? 14.0,
      windDirectionDegrees: (json['windDirectionDegrees'] as num?)?.toDouble() ?? 45.0,
      roadWidthMeters: (json['roadWidthMeters'] as num?)?.toDouble() ?? 7.5,
      surfaceWetness: (json['surfaceWetness'] as num?)?.toDouble() ?? 0.0,
      distanceToFinishMeters: (json['distanceToFinishMeters'] as num?)?.toDouble() ?? 1500.0,
      riders: (json['riders'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(SprintTacticalRiderDot.fromJson)
          .toList(),
      corners: (json['corners'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(SprintRoadCornerMarker.fromJson)
          .toList(),
      selectedRiderId: json['selectedRiderId'] as String?,
      activeOrder: order,
      isSprintActive: json['isSprintActive'] as bool? ?? true,
    );
  }
}

/// Wynik analizy bezpieczeństwa korytarza bocznego kolarza.
class SprintCorridorSafetyResult {
  final bool leftBlocked;
  final bool rightBlocked;
  final bool frontBlocked;
  final double gapScore; // 0..100

  const SprintCorridorSafetyResult({
    required this.leftBlocked,
    required this.rightBlocked,
    required this.frontBlocked,
    required this.gapScore,
  });

  bool get isBoxedIn => frontBlocked && (leftBlocked || rightBlocked);
}

/// Raport spójności pociągu sprinterskiego i rekomendacja taktyczna.
class SprintTrainIntegrityReport {
  final int playerTrainCount;
  final bool isTrainConnected;
  final int boxedInPlayerRiders;
  final double optimalLaunchDistanceMeters;
  final double leadRiderSpeedKmh;
  final bool slingshotWindowActive;
  final SprintLineOrder recommendedOrder;
  final String tacticalAdvice;

  const SprintTrainIntegrityReport({
    required this.playerTrainCount,
    required this.isTrainConnected,
    required this.boxedInPlayerRiders,
    required this.optimalLaunchDistanceMeters,
    required this.leadRiderSpeedKmh,
    required this.slingshotWindowActive,
    required this.recommendedOrder,
    required this.tacticalAdvice,
  });
}

/// Kalkulator taktyczny i generator scenariuszy dla mapy ostatnich 3 km sprintu.
class SprintFinal3kmTacticalCalculator {
  const SprintFinal3kmTacticalCalculator._();

  static SprintCorridorSafetyResult computeLateralCorridorSafety(
    SprintTacticalRiderDot rider,
    List<SprintTacticalRiderDot> allRiders,
    double roadWidthMeters,
  ) {
    bool leftBlocked = rider.lateralOffsetNormalized <= -0.82;
    bool rightBlocked = rider.lateralOffsetNormalized >= 0.82;
    bool frontBlocked = false;

    for (final other in allRiders) {
      if (other.riderId == rider.riderId) continue;
      final dLong = rider.distanceToFinishMeters - other.distanceToFinishMeters;
      final dLat = other.lateralOffsetNormalized - rider.lateralOffsetNormalized;

      // Inny kolarz tuż przed nami (0..4.5 m) i w tym samym pasie (poza własnym rozprowadzającym)
      final isOwnLeadout =
          rider.isPlayerTeam && other.isPlayerTeam && rider.targetWheelRiderId == other.riderId;
      if (!isOwnLeadout && dLong > 0.2 && dLong < 4.5 && dLat.abs() < 0.28) {
        frontBlocked = true;
      }
      // Inny kolarz z lewej lub prawej strony (równolegle +/- 2.5 m)
      if (dLong.abs() < 2.6) {
        if (dLat < -0.05 && dLat > -0.45) {
          leftBlocked = true;
        } else if (dLat > 0.05 && dLat < 0.45) {
          rightBlocked = true;
        }
      }
    }

    double score = 100.0;
    if (frontBlocked) score -= 40.0;
    if (leftBlocked) score -= 25.0;
    if (rightBlocked) score -= 25.0;
    if (roadWidthMeters < 6.0) score -= 10.0;

    return SprintCorridorSafetyResult(
      leftBlocked: leftBlocked,
      rightBlocked: rightBlocked,
      frontBlocked: frontBlocked,
      gapScore: score.clamp(0.0, 100.0),
    );
  }

  static SprintTrainIntegrityReport evaluateTrainIntegrity(
    SprintFinal3kmTelemetryData data,
  ) {
    final playerRiders = data.riders.where((r) => r.isPlayerTeam).toList()
      ..sort((a, b) => a.distanceToFinishMeters.compareTo(b.distanceToFinishMeters));

    if (playerRiders.isEmpty) {
      return const SprintTrainIntegrityReport(
        playerTrainCount: 0,
        isTrainConnected: false,
        boxedInPlayerRiders: 0,
        optimalLaunchDistanceMeters: 220.0,
        leadRiderSpeedKmh: 0.0,
        slingshotWindowActive: false,
        recommendedOrder: SprintLineOrder.surfRivalWheel,
        tacticalAdvice: 'Brak aktywnych kolarzy drużyny w strefie 3 km.',
      );
    }

    int boxedIn = 0;
    bool connected = playerRiders.length >= 2;
    for (int i = 0; i < playerRiders.length; i++) {
      final safety = computeLateralCorridorSafety(
        playerRiders[i],
        data.riders,
        data.roadWidthMeters,
      );
      if (safety.isBoxedIn || playerRiders[i].isBoxedIn) {
        boxedIn++;
      }
      if (i > 0) {
        final longGap = (playerRiders[i].distanceToFinishMeters -
                playerRiders[i - 1].distanceToFinishMeters)
            .abs();
        final latGap = (playerRiders[i].lateralOffsetNormalized -
                playerRiders[i - 1].lateralOffsetNormalized)
            .abs();
        if (longGap > 14.0 || latGap > 0.55) {
          connected = false;
        }
      }
    }

    // Wpływ wiatru w twarz skraca optymalny dystans odpalenia sprintu.
    final headwindCos = math.cos(data.windDirectionDegrees * math.pi / 180.0);
    final windFactor = (data.windSpeedKmh * headwindCos).clamp(-35.0, 35.0);
    final optimalLaunch = (220.0 - windFactor * 1.4).clamp(160.0, 275.0);

    final sprinter = playerRiders.firstWhere(
      (r) => r.role == SprintRiderRoleTag.sprinter,
      orElse: () => playerRiders.last,
    );

    final dist = sprinter.distanceToFinishMeters;
    final slingshotActive = dist <= 320.0 && dist >= 140.0 && sprinter.wPrimePercent >= 25.0;

    final SprintLineOrder recommended;
    final String advice;

    if (dist <= optimalLaunch + 25.0) {
      recommended = SprintLineOrder.openSprintNow;
      advice = 'Strefa procy (${dist.toStringAsFixed(0)} m)! Odpal pełny sprint teraz.';
    } else if (boxedIn > 0) {
      recommended = SprintLineOrder.surfRivalWheel;
      advice = 'Uwaga: kolarz zamknięty przy barierkach — szukaj luki na kole rywala!';
    } else if (dist <= 950.0 && connected) {
      recommended = SprintLineOrder.launchLeadout;
      advice = 'Flamme Rouge za nami — podkręć tempo pociągu rozprowadzającego.';
    } else if (!connected && playerRiders.length >= 2) {
      recommended = SprintLineOrder.followTrain;
      advice = 'Pociąg rozciągnięty — zewrzyj szyki przed kolejnym zakrętem.';
    } else {
      recommended = SprintLineOrder.followTrain;
      advice = 'Utrzymaj osłoniętą pozycję w tunelu aero do strefy 1 km.';
    }

    return SprintTrainIntegrityReport(
      playerTrainCount: playerRiders.length,
      isTrainConnected: connected,
      boxedInPlayerRiders: boxedIn,
      optimalLaunchDistanceMeters: optimalLaunch,
      leadRiderSpeedKmh: playerRiders.first.speedKmh,
      slingshotWindowActive: slingshotActive,
      recommendedOrder: recommended,
      tacticalAdvice: advice,
    );
  }

  static SprintFinal3kmTelemetryData generateDefaultSample() {
    const riders = <SprintTacticalRiderDot>[
      SprintTacticalRiderDot(
        riderId: 'p_lo1',
        name: 'K. Kowalski',
        shortCode: 'KOW',
        teamName: 'Polonia Pro',
        teamColor: AppColors.goldAccent,
        isPlayerTeam: true,
        role: SprintRiderRoleTag.protector,
        distanceToFinishMeters: 842.0,
        lateralOffsetNormalized: -0.22,
        speedKmh: 63.8,
        powerWatts: 760,
        wPrimePercent: 54.0,
        cadenceRpm: 106,
        isDrafting: false,
        draftSavingsPercent: 4.0,
      ),
      SprintTacticalRiderDot(
        riderId: 'p_lo2',
        name: 'M. Zieliński',
        shortCode: 'ZIE',
        teamName: 'Polonia Pro',
        teamColor: AppColors.goldAccent,
        isPlayerTeam: true,
        role: SprintRiderRoleTag.leadout,
        distanceToFinishMeters: 845.5,
        lateralOffsetNormalized: -0.20,
        speedKmh: 63.8,
        powerWatts: 540,
        wPrimePercent: 78.0,
        cadenceRpm: 104,
        isDrafting: true,
        draftSavingsPercent: 34.0,
        targetWheelRiderId: 'p_lo1',
      ),
      SprintTacticalRiderDot(
        riderId: 'p_spr',
        name: 'T. Nowak',
        shortCode: 'NOW',
        teamName: 'Polonia Pro',
        teamColor: AppColors.goldAccent,
        isPlayerTeam: true,
        role: SprintRiderRoleTag.sprinter,
        distanceToFinishMeters: 849.0,
        lateralOffsetNormalized: -0.18,
        speedKmh: 63.7,
        powerWatts: 430,
        wPrimePercent: 93.0,
        cadenceRpm: 101,
        isDrafting: true,
        draftSavingsPercent: 42.0,
        targetWheelRiderId: 'p_lo2',
      ),
      SprintTacticalRiderDot(
        riderId: 'r_lo1',
        name: 'L. Van Dijk',
        shortCode: 'VDI',
        teamName: 'Veloce Alpecin',
        teamColor: AppColors.accentBlue,
        isPlayerTeam: false,
        role: SprintRiderRoleTag.leadout,
        distanceToFinishMeters: 839.0,
        lateralOffsetNormalized: 0.34,
        speedKmh: 64.2,
        powerWatts: 790,
        wPrimePercent: 61.0,
        cadenceRpm: 107,
        isDrafting: false,
        draftSavingsPercent: 0.0,
      ),
      SprintTacticalRiderDot(
        riderId: 'r_spr1',
        name: 'J. Philipsen',
        shortCode: 'PHI',
        teamName: 'Veloce Alpecin',
        teamColor: AppColors.accentBlue,
        isPlayerTeam: false,
        role: SprintRiderRoleTag.rivalSprinter,
        distanceToFinishMeters: 842.8,
        lateralOffsetNormalized: 0.36,
        speedKmh: 64.1,
        powerWatts: 460,
        wPrimePercent: 91.0,
        cadenceRpm: 103,
        isDrafting: true,
        draftSavingsPercent: 39.0,
        targetWheelRiderId: 'r_lo1',
      ),
      SprintTacticalRiderDot(
        riderId: 'r_spr2',
        name: 'M. Merlier',
        shortCode: 'MER',
        teamName: 'Soudal Force',
        teamColor: AppColors.crimsonAlert,
        isPlayerTeam: false,
        role: SprintRiderRoleTag.rivalSprinter,
        distanceToFinishMeters: 851.0,
        lateralOffsetNormalized: 0.05,
        speedKmh: 63.4,
        powerWatts: 455,
        wPrimePercent: 89.0,
        cadenceRpm: 100,
        isDrafting: true,
        draftSavingsPercent: 36.0,
      ),
      SprintTacticalRiderDot(
        riderId: 'brk_1',
        name: 'A. De Gendt',
        shortCode: 'DGE',
        teamName: 'Lotto Break',
        teamColor: AppColors.statusSuccess,
        isPlayerTeam: false,
        role: SprintRiderRoleTag.breakawaySurvivor,
        distanceToFinishMeters: 780.0,
        lateralOffsetNormalized: 0.0,
        speedKmh: 57.5,
        powerWatts: 490,
        wPrimePercent: 18.0,
        cadenceRpm: 94,
        isDrafting: false,
        draftSavingsPercent: 0.0,
      ),
    ];

    const corners = <SprintRoadCornerMarker>[
      SprintRoadCornerMarker(
        distanceToFinishMeters: 2100.0,
        angleDegrees: 45.0,
        severity: SprintFinalCornerSeverity.roundabout,
        label: 'Rondo Miejskie',
        recommendedEntryLine: -0.35,
        pinchWidthMeters: 5.5,
      ),
      SprintRoadCornerMarker(
        distanceToFinishMeters: 920.0,
        angleDegrees: 88.0,
        severity: SprintFinalCornerSeverity.technical90,
        label: 'Zakręt Flamme Rouge',
        recommendedEntryLine: -0.55,
        pinchWidthMeters: 6.2,
      ),
      SprintRoadCornerMarker(
        distanceToFinishMeters: 420.0,
        angleDegrees: 52.0,
        severity: SprintFinalCornerSeverity.chicane,
        label: 'Szykana Finałowa',
        recommendedEntryLine: 0.25,
        pinchWidthMeters: 5.8,
      ),
    ];

    return const SprintFinal3kmTelemetryData(
      stageName: 'Etap 6 — Finisz w Pau (Ostatnie 3 km)',
      windSpeedKmh: 16.0,
      windDirectionDegrees: 35.0,
      roadWidthMeters: 7.5,
      surfaceWetness: 0.1,
      distanceToFinishMeters: 842.0,
      riders: riders,
      corners: corners,
      selectedRiderId: 'p_spr',
      activeOrder: SprintLineOrder.launchLeadout,
      isSprintActive: true,
    );
  }
}

/// Malarz taktycznej mapy z lotu ptaka dla ostatnich 3 km sprintu.
class SprintFinal3kmBirdEyeMapPainter extends CustomPainter {
  final SprintFinal3kmTelemetryData data;
  final SprintMapViewMode viewMode;
  final bool showWindOverlay;
  final bool showAeroDraftCones;
  final bool showTrainLinks;
  final String? hoveredRiderId;
  final double pulsePhase; // 0.0 .. 1.0

  const SprintFinal3kmBirdEyeMapPainter({
    required this.data,
    required this.viewMode,
    required this.showWindOverlay,
    required this.showAeroDraftCones,
    required this.showTrainLinks,
    required this.hoveredRiderId,
    required this.pulsePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Tło taktyczne
    final bgPaint = Paint()..color = AppColors.background;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Siatka metryczna w tle
    _drawTacticalGrid(canvas, size);

    // Wyznacz okno dystansu (oś X: od prawej/lewej — w lewo odległość od mety, w prawo meta 0 m)
    final windowMeters = viewMode.windowMeters;
    final double minDistM;
    final double maxDistM;

    if (viewMode == SprintMapViewMode.fullFinal3km) {
      minDistM = 0.0;
      maxDistM = 3000.0;
    } else {
      final anchor = data.distanceToFinishMeters.clamp(0.0, 3000.0);
      final halfAfter = windowMeters * 0.35;
      final start = (anchor - halfAfter)
          .clamp(0.0, math.max(0.0, 3000.0 - windowMeters))
          .toDouble();
      minDistM = start;
      maxDistM = (start + windowMeters).clamp(windowMeters, 3000.0);
    }

    const leftPad = 36.0;
    const rightPad = 36.0;
    final usableWidth = math.max(40.0, size.width - leftPad - rightPad);

    // Funkcja rzutująca dystans do mety (maxDistM -> left, minDistM -> right)
    double xForDist(double distM) {
      final span = math.max(1.0, maxDistM - minDistM);
      final t = ((maxDistM - distM) / span).clamp(0.0, 1.0);
      return leftPad + t * usableWidth;
    }

    // Geometria szosy z lotu ptaka (delikatna fala dla zakrętów)
    final roadHalfHeight = (size.height * 0.24).clamp(32.0, 74.0);
    double centerYForDist(double distM) {
      final base = size.height * 0.52;
      double offset = 0.0;
      for (final corner in data.corners) {
        final delta = (distM - corner.distanceToFinishMeters).abs();
        if (delta < 260.0) {
          final influence = math.cos((delta / 260.0) * (math.pi / 2));
          offset += influence *
              (corner.angleDegrees / 90.0) *
              (roadHalfHeight * 0.42) *
              (corner.recommendedEntryLine >= 0 ? -1.0 : 1.0);
        }
      }
      return base + offset;
    }

    double yForRider(double distM, double lateralNorm) {
      final cy = centerYForDist(distM);
      return cy + lateralNorm.clamp(-0.92, 0.92) * (roadHalfHeight - 8.0);
    }

    // Rysuj korytarz asfaltu
    _drawRoadCorridor(
      canvas,
      size,
      minDistM,
      maxDistM,
      xForDist,
      centerYForDist,
      roadHalfHeight,
    );

    // Rysuj znaczniki kilometrów (3km, 2km, Flamme Rouge 1km, 500m, 250m, Meta 0m)
    _drawDistanceBanners(
      canvas,
      size,
      minDistM,
      maxDistM,
      xForDist,
      centerYForDist,
      roadHalfHeight,
    );

    // Rysuj zakręty i optymalną linię
    _drawCornersAndApexes(
      canvas,
      minDistM,
      maxDistM,
      xForDist,
      centerYForDist,
      roadHalfHeight,
    );

    // Rysuj wektory wiatru bocznego/czołowego
    if (showWindOverlay) {
      _drawWindVectors(canvas, size);
    }

    // Rysuj stożki aerodynamiczne (drafting)
    if (showAeroDraftCones) {
      _drawAeroDraftCones(canvas, minDistM, maxDistM, xForDist, yForRider);
    }

    // Rysuj połączenia pociągów sprinterskich
    if (showTrainLinks) {
      _drawTrainLinks(canvas, minDistM, maxDistM, xForDist, yForRider);
    }

    // Rysuj kolarzy
    _drawRiders(canvas, minDistM, maxDistM, xForDist, yForRider);
  }

  void _drawTacticalGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.35)
      ..strokeWidth = 0.7;
    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawRoadCorridor(
    Canvas canvas,
    Size size,
    double minDistM,
    double maxDistM,
    double Function(double) xForDist,
    double Function(double) centerYForDist,
    double roadHalfHeight,
  ) {
    const samples = 64;
    final topPoints = <Offset>[];
    final bottomPoints = <Offset>[];
    final centerPoints = <Offset>[];

    for (int i = 0; i <= samples; i++) {
      final t = i / samples;
      final distM = maxDistM - t * (maxDistM - minDistM);
      final x = xForDist(distM);
      final cy = centerYForDist(distM);
      topPoints.add(Offset(x, cy - roadHalfHeight));
      bottomPoints.add(Offset(x, cy + roadHalfHeight));
      centerPoints.add(Offset(x, cy));
    }

    final roadPath = Path()..moveTo(topPoints.first.dx, topPoints.first.dy);
    for (final p in topPoints.skip(1)) {
      roadPath.lineTo(p.dx, p.dy);
    }
    for (final p in bottomPoints.reversed) {
      roadPath.lineTo(p.dx, p.dy);
    }
    roadPath.close();

    // Asfalt (lekko chłodniejszy przy mokrej nawierzchni)
    final asphaltColor = Color.lerp(
      const Color(0xFF1E222B),
      const Color(0xFF17202D),
      data.surfaceWetness.clamp(0.0, 1.0),
    )!;
    canvas.drawPath(roadPath, Paint()..color = asphaltColor);

    // Barierki boczne
    final barrierPaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final topBarrier = Path()..moveTo(topPoints.first.dx, topPoints.first.dy);
    for (final p in topPoints.skip(1)) {
      topBarrier.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(topBarrier, barrierPaint);

    final bottomBarrier = Path()..moveTo(bottomPoints.first.dx, bottomPoints.first.dy);
    for (final p in bottomPoints.skip(1)) {
      bottomBarrier.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(bottomBarrier, barrierPaint);

    // Przerywana oś jezdni
    final dashPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.35)
      ..strokeWidth = 1.2;
    for (int i = 0; i < centerPoints.length - 1; i += 2) {
      canvas.drawLine(centerPoints[i], centerPoints[i + 1], dashPaint);
    }
  }

  void _drawDistanceBanners(
    Canvas canvas,
    Size size,
    double minDistM,
    double maxDistM,
    double Function(double) xForDist,
    double Function(double) centerYForDist,
    double roadHalfHeight,
  ) {
    final markers = <({double dist, String label, Color color, bool isFinish})>[
      (dist: 3000.0, label: '3 KM', color: AppColors.textSecondary, isFinish: false),
      (dist: 2000.0, label: '2 KM', color: AppColors.textSecondary, isFinish: false),
      (dist: 1000.0, label: '1 KM', color: AppColors.crimsonAlert, isFinish: false),
      (dist: 500.0, label: '500M', color: AppColors.amberWarning, isFinish: false),
      (dist: 250.0, label: '250M', color: AppColors.cyanAccent, isFinish: false),
      (dist: 0.0, label: 'META', color: AppColors.goldAccent, isFinish: true),
    ];

    for (final m in markers) {
      if (m.dist < minDistM - 20 || m.dist > maxDistM + 20) continue;
      final x = xForDist(m.dist);
      final cy = centerYForDist(m.dist);
      final topY = cy - roadHalfHeight;
      final botY = cy + roadHalfHeight;

      if (m.isFinish) {
        // Szachownica linii mety
        const squares = 8;
        final sqH = (botY - topY) / squares;
        for (int i = 0; i < squares; i++) {
          canvas.drawRect(
            Rect.fromLTWH(x - 3, topY + i * sqH, 3, sqH),
            Paint()..color = i.isEven ? AppColors.textPrimary : AppColors.background,
          );
          canvas.drawRect(
            Rect.fromLTWH(x, topY + i * sqH, 3, sqH),
            Paint()..color = i.isOdd ? AppColors.textPrimary : AppColors.background,
          );
        }
      } else {
        final linePaint = Paint()
          ..color = m.color.withValues(alpha: m.dist == 1000.0 ? 0.85 : 0.45)
          ..strokeWidth = m.dist == 1000.0 ? 2.2 : 1.2;
        canvas.drawLine(Offset(x, topY - 4), Offset(x, botY + 4), linePaint);
      }

      // Etykieta nad szosą
      final tp = TextPainter(
        text: TextSpan(
          text: m.label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: m.color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, topY - tp.height - 6));
    }
  }

  void _drawCornersAndApexes(
    Canvas canvas,
    double minDistM,
    double maxDistM,
    double Function(double) xForDist,
    double Function(double) centerYForDist,
    double roadHalfHeight,
  ) {
    for (final corner in data.corners) {
      if (corner.distanceToFinishMeters < minDistM ||
          corner.distanceToFinishMeters > maxDistM) {
        continue;
      }
      final x = xForDist(corner.distanceToFinishMeters);
      final cy = centerYForDist(corner.distanceToFinishMeters);
      final apexY = cy + corner.recommendedEntryLine * (roadHalfHeight - 10);

      // Strefa hamowania / ostrzeżenia
      final zonePaint = Paint()
        ..color = corner.severity.badgeColor.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, cy), roadHalfHeight * 0.55, zonePaint);

      // Wierzchołek optymalnej linii (Apex)
      canvas.drawCircle(
        Offset(x, apexY),
        4.5,
        Paint()..color = AppColors.cyanAccent,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: corner.label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: corner.severity.badgeColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, cy + roadHalfHeight + 6));
    }
  }

  void _drawWindVectors(Canvas canvas, Size size) {
    final rad = data.windDirectionDegrees * math.pi / 180.0;
    // 0° = w twarz (w lewo), 180° = w plecy (w prawo)
    final dx = -math.cos(rad) * 18.0;
    final dy = math.sin(rad) * 18.0;

    final windPaint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.45)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final pos in <Offset>[
      Offset(size.width * 0.22, 24),
      Offset(size.width * 0.52, 24),
      Offset(size.width * 0.80, 24),
    ]) {
      final end = Offset(pos.dx + dx, pos.dy + dy);
      canvas.drawLine(pos, end, windPaint);
      canvas.drawCircle(end, 2.2, Paint()..color = AppColors.accentBlue);
    }
  }

  void _drawAeroDraftCones(
    Canvas canvas,
    double minDistM,
    double maxDistM,
    double Function(double) xForDist,
    double Function(double, double) yForRider,
  ) {
    for (final r in data.riders) {
      if (r.distanceToFinishMeters < minDistM || r.distanceToFinishMeters > maxDistM) {
        continue;
      }
      final rx = xForDist(r.distanceToFinishMeters);
      final ry = yForRider(r.distanceToFinishMeters, r.lateralOffsetNormalized);

      final conePath = Path()
        ..moveTo(rx, ry)
        ..lineTo(rx - 22, ry - 9)
        ..lineTo(rx - 22, ry + 9)
        ..close();

      final conePaint = Paint()
        ..color = (r.isPlayerTeam ? AppColors.goldAccent : AppColors.cyanAccent)
            .withValues(alpha: 0.14)
        ..style = PaintingStyle.fill;
      canvas.drawPath(conePath, conePaint);
    }
  }

  void _drawTrainLinks(
    Canvas canvas,
    double minDistM,
    double maxDistM,
    double Function(double) xForDist,
    double Function(double, double) yForRider,
  ) {
    final byId = <String, SprintTacticalRiderDot>{
      for (final r in data.riders) r.riderId: r,
    };

    for (final r in data.riders) {
      final targetId = r.targetWheelRiderId;
      if (targetId == null) continue;
      final target = byId[targetId];
      if (target == null) continue;

      final p1 = Offset(
        xForDist(r.distanceToFinishMeters),
        yForRider(r.distanceToFinishMeters, r.lateralOffsetNormalized),
      );
      final p2 = Offset(
        xForDist(target.distanceToFinishMeters),
        yForRider(target.distanceToFinishMeters, target.lateralOffsetNormalized),
      );

      final linkPaint = Paint()
        ..color = (r.isPlayerTeam ? AppColors.goldAccent : r.teamColor)
            .withValues(alpha: 0.65)
        ..strokeWidth = r.isPlayerTeam ? 2.2 : 1.5;
      canvas.drawLine(p1, p2, linkPaint);
    }
  }

  void _drawRiders(
    Canvas canvas,
    double minDistM,
    double maxDistM,
    double Function(double) xForDist,
    double Function(double, double) yForRider,
  ) {
    for (final r in data.riders) {
      if (r.distanceToFinishMeters < minDistM - 15 ||
          r.distanceToFinishMeters > maxDistM + 15) {
        continue;
      }
      final x = xForDist(r.distanceToFinishMeters);
      final y = yForRider(r.distanceToFinishMeters, r.lateralOffsetNormalized);
      final isSelected = r.riderId == data.selectedRiderId;
      final isHovered = r.riderId == hoveredRiderId;

      if (isSelected) {
        final haloRadius = 12.0 + pulsePhase * 4.0;
        canvas.drawCircle(
          Offset(x, y),
          haloRadius,
          Paint()
            ..color = AppColors.goldAccent.withValues(alpha: 0.25 * (1.0 - pulsePhase * 0.4))
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          Offset(x, y),
          11.0,
          Paint()
            ..color = AppColors.goldAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      } else if (isHovered) {
        canvas.drawCircle(
          Offset(x, y),
          10.5,
          Paint()
            ..color = AppColors.textPrimary.withValues(alpha: 0.65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }

      if (r.isBoxedIn) {
        canvas.drawCircle(
          Offset(x, y),
          9.5,
          Paint()
            ..color = AppColors.crimsonAlert
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }

      // Punkt kolarza
      final radius = r.role == SprintRiderRoleTag.sprinter || r.role == SprintRiderRoleTag.rivalSprinter
          ? 6.5
          : 5.2;
      canvas.drawCircle(Offset(x, y), radius, Paint()..color = r.teamColor);
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = AppColors.background
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      // Kod kolarza dla drużyny gracza lub wybranego/najechanego
      if (r.isPlayerTeam || isSelected || isHovered) {
        final tp = TextPainter(
          text: TextSpan(
            text: r.shortCode,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: r.isPlayerTeam ? AppColors.goldAccent : AppColors.textPrimary,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, y - radius - tp.height - 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant SprintFinal3kmBirdEyeMapPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.viewMode != viewMode ||
        oldDelegate.showWindOverlay != showWindOverlay ||
        oldDelegate.showAeroDraftCones != showAeroDraftCones ||
        oldDelegate.showTrainLinks != showTrainLinks ||
        oldDelegate.hoveredRiderId != hoveredRiderId ||
        oldDelegate.pulsePhase != pulsePhase;
  }
}

/// Nakładka mapy taktycznej z lotu ptaka na ostatnich 3 km sprintu.
class SprintFinal3kmTacticalMapOverlay extends StatefulWidget {
  final SprintFinal3kmTelemetryData data;
  final ValueChanged<String>? onRiderSelected;
  final ValueChanged<SprintLineOrder>? onOrderDispatched;
  final VoidCallback? onClose;
  final bool isEnabled;

  const SprintFinal3kmTacticalMapOverlay({
    super.key,
    required this.data,
    this.onRiderSelected,
    this.onOrderDispatched,
    this.onClose,
    this.isEnabled = true,
  });

  @override
  State<SprintFinal3kmTacticalMapOverlay> createState() =>
      _SprintFinal3kmTacticalMapOverlayState();
}

class _SprintFinal3kmTacticalMapOverlayState
    extends State<SprintFinal3kmTacticalMapOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  SprintMapViewMode _viewMode = SprintMapViewMode.finalKilometer;
  bool _showWindOverlay = true;
  bool _showAeroDraftCones = true;
  bool _showTrainLinks = true;
  String? _hoveredRiderId;
  String? _localSelectedRiderId;
  SprintLineOrder? _localActiveOrder;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _localSelectedRiderId = widget.data.selectedRiderId;
    _localActiveOrder = widget.data.activeOrder;
  }

  @override
  void didUpdateWidget(covariant SprintFinal3kmTacticalMapOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.selectedRiderId != oldWidget.data.selectedRiderId) {
      _localSelectedRiderId = widget.data.selectedRiderId;
    }
    if (widget.data.activeOrder != oldWidget.data.activeOrder) {
      _localActiveOrder = widget.data.activeOrder;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  SprintTacticalRiderDot? get _selectedRider {
    if (widget.data.riders.isEmpty) return null;
    final targetId = _localSelectedRiderId ?? widget.data.selectedRiderId;
    for (final r in widget.data.riders) {
      if (r.riderId == targetId) return r;
    }
    return widget.data.riders.first;
  }

  void _selectRider(String riderId) {
    if (!widget.isEnabled) return;
    setState(() => _localSelectedRiderId = riderId);
    widget.onRiderSelected?.call(riderId);
  }

  void _dispatchOrder(SprintLineOrder order) {
    if (!widget.isEnabled) return;
    setState(() => _localActiveOrder = order);
    widget.onOrderDispatched?.call(order);
  }

  void _cycleSelectedRider(int delta) {
    if (!widget.isEnabled || widget.data.riders.isEmpty) return;
    final riders = widget.data.riders;
    final currentIdx = riders.indexWhere((r) => r.riderId == _selectedRider?.riderId);
    final nextIdx = ((currentIdx < 0 ? 0 : currentIdx) + delta) % riders.length;
    _selectRider(riders[nextIdx < 0 ? nextIdx + riders.length : nextIdx].riderId);
  }

  String? _hitTestRider(Offset localPos, Size canvasSize) {
    if (widget.data.riders.isEmpty || canvasSize.width <= 0 || canvasSize.height <= 0) {
      return null;
    }
    final windowMeters = _viewMode.windowMeters;
    final double minDistM;
    final double maxDistM;
    if (_viewMode == SprintMapViewMode.fullFinal3km) {
      minDistM = 0.0;
      maxDistM = 3000.0;
    } else {
      final anchor = widget.data.distanceToFinishMeters.clamp(0.0, 3000.0);
      final halfAfter = windowMeters * 0.35;
      final start = (anchor - halfAfter)
          .clamp(0.0, math.max(0.0, 3000.0 - windowMeters))
          .toDouble();
      minDistM = start;
      maxDistM = (start + windowMeters).clamp(windowMeters, 3000.0);
    }

    const leftPad = 36.0;
    const rightPad = 36.0;
    final usableWidth = math.max(40.0, canvasSize.width - leftPad - rightPad);
    final roadHalfHeight = (canvasSize.height * 0.24).clamp(32.0, 74.0);

    String? bestId;
    double bestDistSq = 22.0 * 22.0;

    for (final r in widget.data.riders) {
      final span = math.max(1.0, maxDistM - minDistM);
      final t = ((maxDistM - r.distanceToFinishMeters) / span).clamp(0.0, 1.0);
      final rx = leftPad + t * usableWidth;

      double offset = 0.0;
      for (final corner in widget.data.corners) {
        final delta = (r.distanceToFinishMeters - corner.distanceToFinishMeters).abs();
        if (delta < 260.0) {
          final influence = math.cos((delta / 260.0) * (math.pi / 2));
          offset += influence *
              (corner.angleDegrees / 90.0) *
              (roadHalfHeight * 0.42) *
              (corner.recommendedEntryLine >= 0 ? -1.0 : 1.0);
        }
      }
      final ry = (canvasSize.height * 0.52 + offset) +
          r.lateralOffsetNormalized.clamp(-0.92, 0.92) * (roadHalfHeight - 8.0);

      final dx = localPos.dx - rx;
      final dy = localPos.dy - ry;
      final dSq = dx * dx + dy * dy;
      if (dSq <= bestDistSq) {
        bestDistSq = dSq;
        bestId = r.riderId;
      }
    }
    return bestId;
  }

  @override
  Widget build(BuildContext context) {
    final report = SprintFinal3kmTacticalCalculator.evaluateTrainIntegrity(widget.data);
    final selected = _selectedRider;

    return Focus(
      onKeyEvent: (node, event) {
        if (!widget.isEnabled || event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.digit1) {
          setState(() => _viewMode = SprintMapViewMode.fullFinal3km);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.digit2) {
          setState(() => _viewMode = SprintMapViewMode.finalKilometer);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.digit3) {
          setState(() => _viewMode = SprintMapViewMode.final250mSlingshot);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _cycleSelectedRider(-1);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _cycleSelectedRider(1);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.space) {
          _dispatchOrder(report.recommendedOrder);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Opacity(
        opacity: widget.isEnabled ? 1.0 : 0.55,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 540;
              final isWide = constraints.maxWidth >= 900;

              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(isCompact ? 12 : 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(isCompact),
                      const SizedBox(height: 10),
                      _buildToolbar(isCompact),
                      const SizedBox(height: 12),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildMapCanvas(height: 260),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildAdvisorBanner(report),
                                  const SizedBox(height: 10),
                                  if (selected != null) _buildSelectedRiderCard(selected),
                                  const SizedBox(height: 10),
                                  _buildOrdersGrid(isCompact: false),
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _buildMapCanvas(height: isCompact ? 190 : 230),
                        const SizedBox(height: 10),
                        _buildAdvisorBanner(report),
                        if (selected != null) ...[
                          const SizedBox(height: 10),
                          _buildSelectedRiderCard(selected),
                        ],
                        const SizedBox(height: 10),
                        _buildOrdersGrid(isCompact: isCompact),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    final distKm = (widget.data.distanceToFinishMeters / 1000.0).toStringAsFixed(2);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.5)),
              ),
              child: const Icon(
                Icons.alt_route_rounded,
                size: 18,
                color: AppColors.goldAccent,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mapa Taktyczna: Ostatnie 3 km',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    widget.data.stageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.5)),
              ),
              child: Text(
                '$distKm km do mety',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (widget.onClose != null) ...[
              const SizedBox(width: 8),
              _InteractiveChipButton(
                label: 'Zamknij',
                icon: Icons.close_rounded,
                isSelected: false,
                isEnabled: widget.isEnabled,
                onTap: widget.onClose!,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildToolbar(bool isCompact) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final mode in SprintMapViewMode.values)
          _InteractiveChipButton(
            label: mode.label,
            isSelected: _viewMode == mode,
            isEnabled: widget.isEnabled,
            onTap: () => setState(() => _viewMode = mode),
          ),
        const SizedBox(width: 4),
        _InteractiveChipButton(
          label: isCompact ? 'Wiatr' : 'Wiatr ${widget.data.windSpeedKmh.round()} km/h',
          icon: Icons.air_rounded,
          isSelected: _showWindOverlay,
          isEnabled: widget.isEnabled,
          onTap: () => setState(() => _showWindOverlay = !_showWindOverlay),
        ),
        _InteractiveChipButton(
          label: 'Aero',
          icon: Icons.waves_rounded,
          isSelected: _showAeroDraftCones,
          isEnabled: widget.isEnabled,
          onTap: () => setState(() => _showAeroDraftCones = !_showAeroDraftCones),
        ),
        _InteractiveChipButton(
          label: 'Pociągi',
          icon: Icons.timeline_rounded,
          isSelected: _showTrainLinks,
          isEnabled: widget.isEnabled,
          onTap: () => setState(() => _showTrainLinks = !_showTrainLinks),
        ),
      ],
    );
  }

  Widget _buildMapCanvas({required double height}) {
    if (widget.data.riders.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Brak danych kolarzy w strefie sprintu.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, mapConstraints) {
          final mapSize = Size(mapConstraints.maxWidth, mapConstraints.maxHeight);
          return MouseRegion(
            cursor: widget.isEnabled && _hoveredRiderId != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onHover: (event) {
              if (!widget.isEnabled) return;
              final hit = _hitTestRider(event.localPosition, mapSize);
              if (hit != _hoveredRiderId) {
                setState(() => _hoveredRiderId = hit);
              }
            },
            onExit: (_) {
              if (_hoveredRiderId != null) {
                setState(() => _hoveredRiderId = null);
              }
            },
            child: GestureDetector(
              onTapDown: (details) {
                if (!widget.isEnabled) return;
                final hit = _hitTestRider(details.localPosition, mapSize);
                if (hit != null) {
                  _selectRider(hit);
                }
              },
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return CustomPaint(
                    size: mapSize,
                    painter: SprintFinal3kmBirdEyeMapPainter(
                      data: widget.data.copyWith(
                        selectedRiderId: _localSelectedRiderId ?? widget.data.selectedRiderId,
                      ),
                      viewMode: _viewMode,
                      showWindOverlay: _showWindOverlay,
                      showAeroDraftCones: _showAeroDraftCones,
                      showTrainLinks: _showTrainLinks,
                      hoveredRiderId: _hoveredRiderId,
                      pulsePhase: _pulseController.value,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdvisorBanner(SprintTrainIntegrityReport report) {
    final badgeColor = report.boxedInPlayerRiders > 0
        ? AppColors.crimsonAlert
        : (report.slingshotWindowActive ? AppColors.goldAccent : AppColors.statusSuccess);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(
            report.boxedInPlayerRiders > 0
                ? Icons.warning_amber_rounded
                : Icons.tips_and_updates_rounded,
            size: 18,
            color: badgeColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              report.tacticalAdvice,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedRiderCard(SprintTacticalRiderDot rider) {
    final safety = SprintFinal3kmTacticalCalculator.computeLateralCorridorSafety(
      rider,
      widget.data.riders,
      widget.data.roadWidthMeters,
    );
    final statusText = safety.isBoxedIn || rider.isBoxedIn
        ? 'Zamknięty przy barierkach'
        : 'Wolny tor (${safety.gapScore.round()}%)';
    final statusColor =
        safety.isBoxedIn || rider.isBoxedIn ? AppColors.crimsonAlert : AppColors.statusSuccess;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
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
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: rider.teamColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${rider.name} (${rider.role.shortTag})',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                statusText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _MetricCell(label: 'Prędkość', value: '${rider.speedKmh.toStringAsFixed(1)} km/h'),
              _MetricCell(label: 'Moc', value: '${rider.powerWatts} W'),
              _MetricCell(label: 'W\'', value: '${rider.wPrimePercent.round()}%'),
              _MetricCell(label: 'Draft', value: '-${rider.draftSavingsPercent.round()}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersGrid({required bool isCompact}) {
    final active = _localActiveOrder ?? widget.data.activeOrder;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = isCompact || constraints.maxWidth < 420 ? 2 : 4;
        const spacing = 8.0;
        final itemWidth = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final order in SprintLineOrder.values)
              SizedBox(
                width: itemWidth,
                child: _OrderButton(
                  order: order,
                  isSelected: active == order,
                  isEnabled: widget.isEnabled,
                  onTap: () => _dispatchOrder(order),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MetricCell extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            color: AppColors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _InteractiveChipButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _InteractiveChipButton({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_InteractiveChipButton> createState() => _InteractiveChipButtonState();
}

class _InteractiveChipButtonState extends State<_InteractiveChipButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? AppColors.primaryAccent.withValues(alpha: 0.30)
        : (_pressed
            ? AppColors.surfaceLight
            : (_hovered ? AppColors.surfaceLight : AppColors.background));
    final borderColor = _focused
        ? AppColors.cyanAccent
        : (widget.isSelected ? AppColors.goldAccent : AppColors.cardBorder);

    return FocusableActionDetector(
      enabled: widget.isEnabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.isEnabled) widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isEnabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 14,
                  color: widget.isSelected ? AppColors.goldAccent : AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderButton extends StatefulWidget {
  final SprintLineOrder order;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _OrderButton({
    required this.order,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_OrderButton> createState() => _OrderButtonState();
}

class _OrderButtonState extends State<_OrderButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.order.accentColor;
    final bg = widget.isSelected
        ? accent.withValues(alpha: 0.22)
        : (_pressed || _hovered ? AppColors.surfaceLight : AppColors.background);
    final border = _focused
        ? AppColors.cyanAccent
        : (widget.isSelected ? accent : AppColors.cardBorder);

    return FocusableActionDetector(
      enabled: widget.isEnabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.isEnabled) widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isEnabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: _focused ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.order.icon,
                size: 15,
                color: widget.isSelected ? accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.order.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: widget.isSelected ? AppColors.textPrimary : AppColors.textSecondary,
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
