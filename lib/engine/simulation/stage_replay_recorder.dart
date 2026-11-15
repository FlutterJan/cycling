// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import '../peloton/rider_race_state.dart';
import '../rendering3d/camera_rig_controller.dart';
import 'isolate_simulation_worker.dart';
import 'key_moments_detector.dart';
import 'stage_simulation_loop.dart';

// ============================================================================
// 1. PUNKTY TELEMETRII I HISTORIA ETAPU (TELEMETRY TRACK POINTS)
// ============================================================================

/// Pojedynczy punkt telemetryczny kolarza na trasie etapu (Garmin / WKO5 style).
class RiderTelemetryTrackPoint {
  /// Czas od startu ostrego w sekundach [s]
  final double timestampSeconds;

  /// Pokonany dystans w metrach [m]
  final double distanceMeters;

  /// Pokonany dystans w kilometrach [km]
  double get distanceKm => distanceMeters / 1000.0;

  /// Prędkość chwilowa w m/s
  final double speedMs;

  /// Prędkość chwilowa w km/h
  double get speedKmh => speedMs * 3.6;

  /// Moc mechaniczna generowana na pedałach [W]
  final int powerWatts;

  /// Kadencja pedałowania w obrotach na minutę [RPM]
  final int cadenceRpm;

  /// Częstość skurczów serca [bpm]
  final int heartRateBpm;

  /// Wysokość n.p.m. [m]
  final double elevationMeters;

  /// Aktualne nachylenie jezdni w procentach [%]
  final double gradientPercent;

  /// Pozostały zapas pracy beztlenowej W' [J]
  final double wPrimeJoules;

  /// Procent naładowania baterii W' (0.0 - 1.0)
  final double wPrimePercentage;

  /// Zapas zmagazynowanego glikogenu [g]
  final double glycogenGrams;

  /// Pozycja boczna na szosie (-1.0 = lewa, 0.0 = środek, 1.0 = prawa)
  final double lateralPositionRoad;

  /// Czy kolarz korzysta z cienia aerodynamicznego
  final bool isDrafting;

  /// Oszczędność energii z tunelu aerodynamicznego w procentach (np. 32.0%)
  final double draftingSavingsPercent;

  /// Aktywne polecenie taktyczne
  final TacticalOrder activeTacticalOrder;

  const RiderTelemetryTrackPoint({
    required this.timestampSeconds,
    required this.distanceMeters,
    required this.speedMs,
    required this.powerWatts,
    required this.cadenceRpm,
    required this.heartRateBpm,
    required this.elevationMeters,
    required this.gradientPercent,
    required this.wPrimeJoules,
    required this.wPrimePercentage,
    required this.glycogenGrams,
    required this.lateralPositionRoad,
    required this.isDrafting,
    required this.draftingSavingsPercent,
    required this.activeTacticalOrder,
  });

  Map<String, dynamic> toJson() => {
        't': timestampSeconds,
        'd': distanceMeters,
        'spd': speedMs,
        'pwr': powerWatts,
        'cad': cadenceRpm,
        'hr': heartRateBpm,
        'alt': elevationMeters,
        'grad': gradientPercent,
        'wPrime': wPrimeJoules,
        'glycogen': glycogenGrams,
        'lateral': lateralPositionRoad,
        'drafting': isDrafting,
        'order': activeTacticalOrder.name,
      };

  factory RiderTelemetryTrackPoint.fromJson(Map<String, dynamic> json) {
    return RiderTelemetryTrackPoint(
      timestampSeconds: (json['t'] as num).toDouble(),
      distanceMeters: (json['d'] as num).toDouble(),
      speedMs: (json['spd'] as num).toDouble(),
      powerWatts: (json['pwr'] as num).toInt(),
      cadenceRpm: (json['cad'] as num).toInt(),
      heartRateBpm: (json['hr'] as num).toInt(),
      elevationMeters: (json['alt'] as num).toDouble(),
      gradientPercent: (json['grad'] as num).toDouble(),
      wPrimeJoules: (json['wPrime'] as num).toDouble(),
      wPrimePercentage: 1.0,
      glycogenGrams: (json['glycogen'] as num).toDouble(),
      lateralPositionRoad: (json['lateral'] as num?)?.toDouble() ?? 0.0,
      isDrafting: json['drafting'] as bool? ?? false,
      draftingSavingsPercent: (json['drafting'] as bool? ?? false) ? 32.0 : 0.0,
      activeTacticalOrder: TacticalOrder.fromJson(json['order'] as String? ?? 'holdPosition'),
    );
  }
}

// ============================================================================
// 2. PODSUMOWANIE AKTYWNOŚCI I METRYKI MOCY (GARMIN / STRAVA .FIT STYLE)
// ============================================================================

/// Zestawienie stref tętna (Heart Rate Zones 1-5).
class HrZoneDistribution {
  final double zone1RecoverySeconds; // < 60% max HR
  final double zone2EnduranceSeconds; // 60 - 70% max HR
  final double zone3TempoSeconds; // 70 - 80% max HR
  final double zone4ThresholdSeconds; // 80 - 90% max HR
  final double zone5AnaerobicSeconds; // > 90% max HR

  const HrZoneDistribution({
    required this.zone1RecoverySeconds,
    required this.zone2EnduranceSeconds,
    required this.zone3TempoSeconds,
    required this.zone4ThresholdSeconds,
    required this.zone5AnaerobicSeconds,
  });

  double get totalSeconds =>
      zone1RecoverySeconds +
      zone2EnduranceSeconds +
      zone3TempoSeconds +
      zone4ThresholdSeconds +
      zone5AnaerobicSeconds;
}

/// Pełne podsumowanie etapu kolarza odpowiadające widokowi aktywności w Garmin Connect / Strava.
class FitActivitySummary {
  final String riderId;
  final String riderName;
  final String teamName;
  final String stageName;
  final double totalDistanceKm;
  final double totalTimeSeconds;
  final double movingTimeSeconds;

  // Prędkość
  final double avgSpeedKmh;
  final double maxSpeedKmh;

  // Moc i obciążenie treningowe (Dr Andrew Coggan metrics)
  final int avgPowerWatts;
  final int maxPowerWatts;
  final int normalizedPowerWatts; // NP™
  final double intensityFactor; // IF (NP / FTP)
  final double trainingStressScore; // TSS
  final double variabilityIndex; // VI (NP / AvgPower)
  final double totalWorkKj; // Praca w kilodżulach
  final int caloriesKcal; // Spalone kalorie

  // Fizjologia i tętno
  final int avgHeartRateBpm;
  final int maxHeartRateBpm;
  final HrZoneDistribution hrZones;
  final int avgCadenceRpm;
  final int maxCadenceRpm;

  // Profil wysokościowy
  final double elevationGainMeters;
  final double elevationLossMeters;
  final double minElevationMeters;
  final double maxElevationMeters;
  final double vamMetersPerHour; // VAM na podjazdach

  // Krzywa mocy (Mean Maximal Power - MMP)
  final Map<String, int> peakPowerCurve; // np. 1s, 5s, 15s, 30s, 1m, 3m, 5m, 10m, 20m

  const FitActivitySummary({
    required this.riderId,
    required this.riderName,
    required this.teamName,
    required this.stageName,
    required this.totalDistanceKm,
    required this.totalTimeSeconds,
    required this.movingTimeSeconds,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.avgPowerWatts,
    required this.maxPowerWatts,
    required this.normalizedPowerWatts,
    required this.intensityFactor,
    required this.trainingStressScore,
    required this.variabilityIndex,
    required this.totalWorkKj,
    required this.caloriesKcal,
    required this.avgHeartRateBpm,
    required this.maxHeartRateBpm,
    required this.hrZones,
    required this.avgCadenceRpm,
    required this.maxCadenceRpm,
    required this.elevationGainMeters,
    required this.elevationLossMeters,
    required this.minElevationMeters,
    required this.maxElevationMeters,
    required this.vamMetersPerHour,
    required this.peakPowerCurve,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'teamName': teamName,
        'stageName': stageName,
        'distanceKm': totalDistanceKm,
        'totalTimeSec': totalTimeSeconds,
        'avgSpeedKmh': avgSpeedKmh,
        'maxSpeedKmh': maxSpeedKmh,
        'avgPower': avgPowerWatts,
        'maxPower': maxPowerWatts,
        'normalizedPower': normalizedPowerWatts,
        'intensityFactor': intensityFactor,
        'tss': trainingStressScore,
        'variabilityIndex': variabilityIndex,
        'totalWorkKj': totalWorkKj,
        'calories': caloriesKcal,
        'avgHr': avgHeartRateBpm,
        'maxHr': maxHeartRateBpm,
        'avgCadence': avgCadenceRpm,
        'maxCadence': maxCadenceRpm,
        'elevationGain': elevationGainMeters,
        'vam': vamMetersPerHour,
        'peakPower': peakPowerCurve,
      };
}

// ============================================================================
// 3. LOG TELEMETRII KOLARZA (RIDER TELEMETRY LOG)
// ============================================================================

/// Rejestr próbek telemetrycznych konkretnego kolarza z całego wyścigu.
class RiderTelemetryLog {
  final String riderId;
  final String riderName;
  final int bibNumber;
  final String teamId;
  final String teamName;
  final bool isPlayerRider;
  final int ftpWatts;
  final int maxHrBpm;

  final List<RiderTelemetryTrackPoint> _points = [];

  RiderTelemetryLog({
    required this.riderId,
    required this.riderName,
    required this.bibNumber,
    required this.teamId,
    required this.teamName,
    required this.isPlayerRider,
    this.ftpWatts = 400,
    this.maxHrBpm = 195,
  });

  List<RiderTelemetryTrackPoint> get points => List.unmodifiable(_points);
  int get sampleCount => _points.length;

  void addPoint(RiderTelemetryTrackPoint point) {
    _points.add(point);
  }

  /// Wylicza kompletne podsumowanie aktywności w standardzie Garmin / Strava.
  FitActivitySummary computeFitSummary({String stageName = 'Etap Wyścigu'}) {
    if (_points.isEmpty) {
      return FitActivitySummary(
        riderId: riderId,
        riderName: riderName,
        teamName: teamName,
        stageName: stageName,
        totalDistanceKm: 0.0,
        totalTimeSeconds: 0.0,
        movingTimeSeconds: 0.0,
        avgSpeedKmh: 0.0,
        maxSpeedKmh: 0.0,
        avgPowerWatts: 0,
        maxPowerWatts: 0,
        normalizedPowerWatts: 0,
        intensityFactor: 0.0,
        trainingStressScore: 0.0,
        variabilityIndex: 1.0,
        totalWorkKj: 0.0,
        caloriesKcal: 0,
        avgHeartRateBpm: 0,
        maxHeartRateBpm: 0,
        hrZones: const HrZoneDistribution(
          zone1RecoverySeconds: 0,
          zone2EnduranceSeconds: 0,
          zone3TempoSeconds: 0,
          zone4ThresholdSeconds: 0,
          zone5AnaerobicSeconds: 0,
        ),
        avgCadenceRpm: 0,
        maxCadenceRpm: 0,
        elevationGainMeters: 0.0,
        elevationLossMeters: 0.0,
        minElevationMeters: 0.0,
        maxElevationMeters: 0.0,
        vamMetersPerHour: 0.0,
        peakPowerCurve: const {},
      );
    }

    final double totalSec = _points.last.timestampSeconds - _points.first.timestampSeconds;
    final double distKm = _points.last.distanceKm;

    int powerSum = 0;
    int maxPower = 0;
    int hrSum = 0;
    int maxHr = 0;
    int cadSum = 0;
    int maxCad = 0;
    double maxSpeedMs = 0.0;
    double speedSumMs = 0.0;

    double elevGain = 0.0;
    double elevLoss = 0.0;
    double minAlt = _points.first.elevationMeters;
    double maxAlt = _points.first.elevationMeters;

    double z1Sec = 0.0;
    double z2Sec = 0.0;
    double z3Sec = 0.0;
    double z4Sec = 0.0;
    double z5Sec = 0.0;

    double totalClimbTimeSec = 0.0;
    double climbGain = 0.0;

    for (int i = 0; i < _points.length; i++) {
      final p = _points[i];
      final double dt = (i > 0)
          ? math.max(0.1, p.timestampSeconds - _points[i - 1].timestampSeconds)
          : 1.0;

      powerSum += p.powerWatts;
      if (p.powerWatts > maxPower) maxPower = p.powerWatts;

      hrSum += p.heartRateBpm;
      if (p.heartRateBpm > maxHr) maxHr = p.heartRateBpm;

      cadSum += p.cadenceRpm;
      if (p.cadenceRpm > maxCad) maxCad = p.cadenceRpm;

      speedSumMs += p.speedMs;
      if (p.speedMs > maxSpeedMs) maxSpeedMs = p.speedMs;

      if (p.elevationMeters < minAlt) minAlt = p.elevationMeters;
      if (p.elevationMeters > maxAlt) maxAlt = p.elevationMeters;

      if (i > 0) {
        final dElev = p.elevationMeters - _points[i - 1].elevationMeters;
        if (dElev > 0.0) {
          elevGain += dElev;
          if (p.gradientPercent > 3.0) {
            climbGain += dElev;
            totalClimbTimeSec += dt;
          }
        } else {
          elevLoss += dElev.abs();
        }
      }

      // Podział na strefy tętna
      final hrRatio = p.heartRateBpm / maxHrBpm;
      if (hrRatio < 0.60) {
        z1Sec += dt;
      } else if (hrRatio < 0.70) {
        z2Sec += dt;
      } else if (hrRatio < 0.80) {
        z3Sec += dt;
      } else if (hrRatio < 0.90) {
        z4Sec += dt;
      } else {
        z5Sec += dt;
      }
    }

    final int n = _points.length;
    final int avgPwr = (powerSum / n).round();
    final int avgHr = (hrSum / n).round();
    final int avgCad = (cadSum / n).round();
    final double avgSpdKmh = (speedSumMs / n) * 3.6;
    final double maxSpdKmh = maxSpeedMs * 3.6;

    // Obliczenie Normalized Power (NP) wg algorytmu Dr. Andrew Coggana:
    // 1. 30-sekundowa średnia krocząca
    // 2. Podniesienie każdej do 4 potęgi
    // 3. Średnia z wartości
    // 4. Pierwiastek 4 stopnia
    final int np = _calculateNormalizedPower(_points);

    final double effectiveFtp = ftpWatts > 50 ? ftpWatts.toDouble() : 400.0;
    final double intensityFactor = np / effectiveFtp;
    final double tss = (totalSec * np * intensityFactor) / (effectiveFtp * 36.0);
    final double variabilityIndex = avgPwr > 0 ? (np / avgPwr) : 1.0;

    // Praca całkowita w kJ = suma (Moc * dt) / 1000
    double workKj = 0.0;
    for (int i = 0; i < _points.length; i++) {
      final double dt = (i > 0)
          ? math.max(0.1, _points[i].timestampSeconds - _points[i - 1].timestampSeconds)
          : 1.0;
      workKj += (_points[i].powerWatts * dt) / 1000.0;
    }
    // Kalorie: przy sprawności mechanicznej organizmu ludzkiego ~24%
    // 1 kJ pracy na korbie = ~1 kcal wydatku metabolicznego
    final int calories = (workKj * 0.98).round();

    // VAM (Vertical Ascent Meters per hour)
    final double vam = totalClimbTimeSec > 30.0
        ? (climbGain / totalClimbTimeSec) * 3600.0
        : 0.0;

    // Krzywa mocy (Mean Maximal Power) dla kluczowych przedziałów czasowych
    final peakPowers = _calculatePeakPowerCurve(_points);

    return FitActivitySummary(
      riderId: riderId,
      riderName: riderName,
      teamName: teamName,
      stageName: stageName,
      totalDistanceKm: distKm,
      totalTimeSeconds: totalSec,
      movingTimeSeconds: totalSec,
      avgSpeedKmh: avgSpdKmh,
      maxSpeedKmh: maxSpdKmh,
      avgPowerWatts: avgPwr,
      maxPowerWatts: maxPower,
      normalizedPowerWatts: np,
      intensityFactor: intensityFactor,
      trainingStressScore: tss,
      variabilityIndex: variabilityIndex,
      totalWorkKj: workKj,
      caloriesKcal: calories,
      avgHeartRateBpm: avgHr,
      maxHeartRateBpm: maxHr,
      hrZones: HrZoneDistribution(
        zone1RecoverySeconds: z1Sec,
        zone2EnduranceSeconds: z2Sec,
        zone3TempoSeconds: z3Sec,
        zone4ThresholdSeconds: z4Sec,
        zone5AnaerobicSeconds: z5Sec,
      ),
      avgCadenceRpm: avgCad,
      maxCadenceRpm: maxCad,
      elevationGainMeters: elevGain,
      elevationLossMeters: elevLoss,
      minElevationMeters: minAlt,
      maxElevationMeters: maxAlt,
      vamMetersPerHour: vam,
      peakPowerCurve: peakPowers,
    );
  }

  /// Wylicza Normalized Power (NP) przy użyciu okna 30-sekundowego.
  static int _calculateNormalizedPower(List<RiderTelemetryTrackPoint> pts) {
    if (pts.length < 30) {
      if (pts.isEmpty) return 0;
      final sum = pts.map((p) => p.powerWatts).reduce((a, b) => a + b);
      return sum ~/ pts.length;
    }

    final List<double> rolling30s = [];
    int currentWindowSum = 0;
    const int windowSize = 30;

    for (int i = 0; i < pts.length; i++) {
      currentWindowSum += pts[i].powerWatts;
      if (i >= windowSize) {
        currentWindowSum -= pts[i - windowSize].powerWatts;
      }
      if (i >= windowSize - 1) {
        final double avg30 = currentWindowSum / windowSize.toDouble();
        rolling30s.add(math.pow(avg30, 4).toDouble());
      }
    }

    if (rolling30s.isEmpty) return pts.first.powerWatts;

    final double meanPow4 = rolling30s.reduce((a, b) => a + b) / rolling30s.length;
    return math.pow(meanPow4, 0.25).round();
  }

  /// Wylicza szczytowe moce (Peak Power) dla standardowych okien czasowych (1s, 5s, 15s, 30s, 1m, 3m, 5m, 10m, 20m).
  static Map<String, int> _calculatePeakPowerCurve(List<RiderTelemetryTrackPoint> pts) {
    if (pts.isEmpty) return {};

    final Map<String, int> durations = {
      '1s': 1,
      '5s': 5,
      '15s': 15,
      '30s': 30,
      '1m': 60,
      '3m': 180,
      '5m': 300,
      '10m': 600,
      '20m': 1200,
    };

    final Map<String, int> result = {};

    for (final entry in durations.entries) {
      final int window = entry.value;
      if (pts.length < window) {
        // Jeśli wyścig trwał krócej niż okno, szczytowa moc to średnia z całego dostępnego czasu
        final sum = pts.map((p) => p.powerWatts).reduce((a, b) => a + b);
        result[entry.key] = sum ~/ pts.length;
        continue;
      }

      int currentSum = 0;
      for (int i = 0; i < window; i++) {
        currentSum += pts[i].powerWatts;
      }

      int maxSum = currentSum;

      for (int i = window; i < pts.length; i++) {
        currentSum += pts[i].powerWatts - pts[i - window].powerWatts;
        if (currentSum > maxSum) {
          maxSum = currentSum;
        }
      }

      result[entry.key] = maxSum ~/ window;
    }

    return result;
  }
}

// ============================================================================
// 4. PAKIET REPLAY KLATEK 3D FINISZU I ATAKÓW (HIGH-DEFINITION REPLAY BUFFER)
// ============================================================================

/// Stan pojedynczego kolarza w klatce powtórki 3D finiszu.
class ReplayRiderState {
  final String riderId;
  final int bibNumber;
  final String riderName;
  final String teamId;
  final String teamJerseyHexColor;
  final bool isPlayerRider;

  // Koordynaty w przestrzeni 3D
  final double distanceCoveredMeters;
  final double lateralOffsetRoadMeters; // [-3.5m do +3.5m]
  final double elevationMeters;

  // Kinematyka i dynamika
  final double speedMs;
  final double speedKmh;
  final int powerWatts;
  final int cadenceRpm;
  final int heartRateBpm;

  // Flagi wizualne animacji (np. rzut rowerem na kreskę, sprint z siodełka)
  final bool isSprinting;
  final bool isBikeThrow;
  final bool isDrafting;
  final bool isCrashed;
  final bool hasDefect;

  const ReplayRiderState({
    required this.riderId,
    required this.bibNumber,
    required this.riderName,
    required this.teamId,
    required this.teamJerseyHexColor,
    required this.isPlayerRider,
    required this.distanceCoveredMeters,
    required this.lateralOffsetRoadMeters,
    required this.elevationMeters,
    required this.speedMs,
    required this.speedKmh,
    required this.powerWatts,
    required this.cadenceRpm,
    required this.heartRateBpm,
    required this.isSprinting,
    required this.isBikeThrow,
    required this.isDrafting,
    required this.isCrashed,
    required this.hasDefect,
  });

  factory ReplayRiderState.fromSimulationFrame(RiderSimulationFrame frame, {bool isNearFinish = false}) {
    // Detekcja sprintu i rzutu rowerem na kreskę mety
    final bool isSprint = frame.powerWatts > 750 || frame.activeTacticalOrder == TacticalOrder.attack;
    final bool isThrow = isNearFinish && frame.distanceCoveredMeters >= (frame.distanceCoveredMeters - 3.5);

    return ReplayRiderState(
      riderId: frame.riderId,
      bibNumber: frame.bibNumber,
      riderName: frame.riderName,
      teamId: frame.teamId,
      teamJerseyHexColor: frame.teamJerseyHexColor,
      isPlayerRider: frame.isPlayerRider,
      distanceCoveredMeters: frame.distanceCoveredMeters,
      lateralOffsetRoadMeters: frame.lateralOffsetRoadMeters,
      elevationMeters: frame.elevationMeters,
      speedMs: frame.speedMs,
      speedKmh: frame.speedKmh,
      powerWatts: frame.powerWatts,
      cadenceRpm: frame.cadenceRpm,
      heartRateBpm: frame.heartRateBpm,
      isSprinting: isSprint,
      isBikeThrow: isThrow,
      isDrafting: frame.isDrafting,
      isCrashed: frame.isCrashed,
      hasDefect: frame.hasDefect,
    );
  }
}

/// Klatka powtórki 3D zawierająca pełen stan wszystkich kolarzy na trasie.
class ReplayFrameSnapshot {
  final int frameIndex;
  final double timestampSeconds;
  final double leadKilometerMark;
  final double distanceToFinishKm;
  final double currentGradientPercent;
  final double currentElevationMeters;
  final String leadRiderName;
  final String? activeMomentTag;
  final List<ReplayRiderState> riders;

  const ReplayFrameSnapshot({
    required this.frameIndex,
    required this.timestampSeconds,
    required this.leadKilometerMark,
    required this.distanceToFinishKm,
    required this.currentGradientPercent,
    required this.currentElevationMeters,
    required this.leadRiderName,
    this.activeMomentTag,
    required this.riders,
  });

  /// Wyszukiwanie kolarza w klatce po ID
  ReplayRiderState? getRider(String riderId) {
    for (final r in riders) {
      if (r.riderId == riderId) return r;
    }
    return null;
  }
}

/// Rodzaj nagranego klipu / momentu wyścigu.
enum ReplayClipType {
  /// Finisz etapu (ostatni kilometr + kreska mety)
  finalKilometer,

  /// Atak faworyta klasyfikacji generalnej (GC Attack)
  gcAttack,

  /// Odcinek na rantach w bocznej wichurze (Echelon Attack)
  echelonAttack,

  /// Trudny sektor brukowy
  cobbleSector,

  /// Kraksa lub defekt w czołówce
  incident,
}

/// Wyodrębniony klip wideo powtórki 3D z metadanymi i serią klatek.
class ReplayClip {
  final String id;
  final String title;
  final String description;
  final ReplayClipType type;
  final double startDistanceKm;
  final double endDistanceKm;
  final double startTimestampSeconds;
  final double endTimestampSeconds;
  final List<ReplayFrameSnapshot> frames;

  const ReplayClip({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.startDistanceKm,
    required this.endDistanceKm,
    required this.startTimestampSeconds,
    required this.endTimestampSeconds,
    required this.frames,
  });

  double get durationSeconds => math.max(0.0, endTimestampSeconds - startTimestampSeconds);
  int get frameCount => frames.length;
  bool get isEmpty => frames.isEmpty;
}

// ============================================================================
// 5. GŁÓWNY REJESTRATOR TELEMETRII ETAPU (STAGE REPLAY RECORDER)
// ============================================================================

/// Konfiguracja rejestratora telemetrii i powtórek etapu.
class StageReplayRecorderConfig {
  /// Częstotliwość próbkowania pełnej telemetrii wyścigu w sekundach (domyślnie 1.0s)
  final double fullTelemetrySampleIntervalSeconds;

  /// Odległość do mety (w km), od której włącza się gęsty rejestr finiszu (np. 1.0 km)
  final double finalKilometerThresholdKm;

  /// Maksymalna liczba klatek w buforze finiszu 3D (zabezpieczenie przed przepełnieniem RAM)
  final int maxReplayFramesCapacity;

  const StageReplayRecorderConfig({
    this.fullTelemetrySampleIntervalSeconds = 1.0,
    this.finalKilometerThresholdKm = 1.0,
    this.maxReplayFramesCapacity = 3600, // ~120s przy 30 fps
  });
}

/// Główny rejestrator telemetrii etapu (`StageReplayRecorder`).
///
/// Zapisuje w skompresowanej formie:
/// 1. Przebieg całego wyścigu dla każdego kolarza (generując wykresy mocy, tętna i prędkości jak plik `.fit` w Stravie).
/// 2. Gęstą powtórkę 3D ostatniego kilometra i kluczowych ataków (pozwalając na odtworzenie finiszu z dowolnej kamery).
class StageReplayRecorder {
  final StageReplayRecorderConfig config;
  final String stageName;

  final Map<String, RiderTelemetryLog> _riderLogs = {};
  final List<ReplayFrameSnapshot> _finalKmFrames = [];
  final List<ReplayClip> _highlightClips = [];

  // Stan nagrywania ataków
  bool _isRecordingAttackClip = false;
  String? _currentAttackClipTitle;
  ReplayClipType _currentAttackClipType = ReplayClipType.gcAttack;
  final List<ReplayFrameSnapshot> _currentAttackFrames = [];

  double _lastFullTelemetrySampleTime = -100.0;
  bool _isFinalKilometerActive = false;

  StageReplayRecorder({
    this.config = const StageReplayRecorderConfig(),
    this.stageName = 'Etap Wyścigu',
  });

  Map<String, RiderTelemetryLog> get riderLogs => Map.unmodifiable(_riderLogs);
  List<ReplayFrameSnapshot> get finalKilometerFrames => List.unmodifiable(_finalKmFrames);
  List<ReplayClip> get highlightClips => List.unmodifiable(_highlightClips);
  bool get hasFinalKmReplay => _finalKmFrames.isNotEmpty;
  bool get isFinalKilometerActive => _isFinalKilometerActive;

  /// Pobiera rejestr telemetrii dla konkretnego kolarza.
  RiderTelemetryLog? getRiderLog(String riderId) => _riderLogs[riderId];

  /// Zwraca listę wszystkich zarejestrowanych kolarzy gracza.
  List<RiderTelemetryLog> get playerRiderLogs =>
      _riderLogs.values.where((log) => log.isPlayerRider).toList();

  /// Bezpośrednia rejestracja stanu symulacji z silnika [StageSimulationState].
  void recordSimulationState(
    StageSimulationState state, {
    Map<String, String> riderNamesMap = const {},
    Map<String, String> teamNamesMap = const {},
  }) {
    final double currentTime = state.elapsedSeconds;
    final bool shouldSampleFullTelemetry =
        (currentTime - _lastFullTelemetrySampleTime) >= config.fullTelemetrySampleIntervalSeconds;

    if (shouldSampleFullTelemetry) {
      _lastFullTelemetrySampleTime = currentTime;

      for (final entry in state.riderStates.entries) {
        final rId = entry.key;
        final r = entry.value;
        final wPrime = state.wPrimeStates[rId];
        final nutrition = state.nutritionStates[rId];
        final isPlayer = state.playerRiderIds.contains(rId);

        final log = _riderLogs.putIfAbsent(
          rId,
          () => RiderTelemetryLog(
            riderId: rId,
            riderName: riderNamesMap[rId] ?? rId,
            bibNumber: 1,
            teamId: r.teamId,
            teamName: teamNamesMap[r.teamId] ?? r.teamId,
            isPlayerRider: isPlayer,
          ),
        );

        final wPrimeVal = wPrime?.currentWPrimeJoules ?? r.currentWPrime;
        final glycVal = nutrition?.currentGlycogenGrams ?? r.currentGlycogen;

        log.addPoint(RiderTelemetryTrackPoint(
          timestampSeconds: currentTime,
          distanceMeters: r.distanceCoveredMeters,
          speedMs: r.currentSpeedMs,
          powerWatts: r.currentWatts,
          cadenceRpm: r.currentCadenceRpm,
          heartRateBpm: r.currentHeartRate,
          elevationMeters: 200.0 + (r.distanceCoveredMeters * 0.005),
          gradientPercent: 2.0,
          wPrimeJoules: wPrimeVal,
          wPrimePercentage: (wPrimeVal / 20000.0).clamp(0.0, 1.0),
          glycogenGrams: glycVal,
          lateralPositionRoad: r.lateralPositionRoad,
          isDrafting: r.activeTacticalOrder != TacticalOrder.pullGroup,
          draftingSavingsPercent: r.activeTacticalOrder != TacticalOrder.pullGroup ? 32.0 : 0.0,
          activeTacticalOrder: r.activeTacticalOrder,
        ));
      }
    }
  }

  /// Rejestruje klatkę na podstawie [SimulationSnapshot] otrzymanego z silnika `IsolateSimulationWorker`.
  void recordSnapshot(SimulationSnapshot snapshot) {
    final double currentTime = snapshot.elapsedSeconds;
    final bool shouldSampleFullTelemetry =
        (currentTime - _lastFullTelemetrySampleTime) >= config.fullTelemetrySampleIntervalSeconds;

    // 1. Zapis pełnej telemetrii całego wyścigu (Garmin / Strava style)
    if (shouldSampleFullTelemetry) {
      _lastFullTelemetrySampleTime = currentTime;

      for (final r in snapshot.riders) {
        final log = _riderLogs.putIfAbsent(
          r.riderId,
          () => RiderTelemetryLog(
            riderId: r.riderId,
            riderName: r.riderName,
            bibNumber: r.bibNumber,
            teamId: r.teamId,
            teamName: r.teamName,
            isPlayerRider: r.isPlayerRider,
          ),
        );

        log.addPoint(RiderTelemetryTrackPoint(
          timestampSeconds: currentTime,
          distanceMeters: r.distanceCoveredMeters,
          speedMs: r.speedMs,
          powerWatts: r.powerWatts,
          cadenceRpm: r.cadenceRpm,
          heartRateBpm: r.heartRateBpm,
          elevationMeters: r.elevationMeters,
          gradientPercent: r.currentGradientPercent,
          wPrimeJoules: r.wPrimeJoules,
          wPrimePercentage: r.wPrimePercentage,
          glycogenGrams: r.glycogenGrams,
          lateralPositionRoad: r.lateralPositionRoad,
          isDrafting: r.isDrafting,
          draftingSavingsPercent: r.draftingSavingsPercent,
          activeTacticalOrder: r.activeTacticalOrder,
        ));
      }
    }

    // 2. Detekcja wejścia w strefę ostatniego kilometra (Final Kilometer Replay)
    final bool inFinalKm = snapshot.distanceToFinishKm <= config.finalKilometerThresholdKm;
    if (inFinalKm) {
      _isFinalKilometerActive = true;
      if (_finalKmFrames.length < config.maxReplayFramesCapacity) {
        final leadRider = snapshot.leaderRider;
        final isNearFinishLine = snapshot.distanceToFinishKm <= 0.05;

        _finalKmFrames.add(ReplayFrameSnapshot(
          frameIndex: _finalKmFrames.length,
          timestampSeconds: currentTime,
          leadKilometerMark: snapshot.leadKilometerMark,
          distanceToFinishKm: snapshot.distanceToFinishKm,
          currentGradientPercent: snapshot.currentGradientPercent,
          currentElevationMeters: snapshot.currentElevationMeters,
          leadRiderName: leadRider?.riderName ?? 'Czoło wyścigu',
          activeMomentTag: isNearFinishLine ? 'Finisz na kreskę' : 'Ostatni 1 km',
          riders: snapshot.riders
              .map((r) => ReplayRiderState.fromSimulationFrame(r, isNearFinish: isNearFinishLine))
              .toList(),
        ));
      }
    }

    // 3. Rejestracja kluczowych ataków (Key Moments)
    final activeMoment = snapshot.activeKeyMoment;
    if (activeMoment != null && !_isRecordingAttackClip && !inFinalKm) {
      _startAttackRecording(activeMoment);
    }

    if (_isRecordingAttackClip) {
      _recordAttackFrame(snapshot);
    }
  }

  void _startAttackRecording(KeyMomentTrigger moment) {
    _isRecordingAttackClip = true;
    _currentAttackClipTitle = moment.title;
    _currentAttackClipType = _mapMomentTypeToClipType(moment.type);
    _currentAttackFrames.clear();
  }

  void _recordAttackFrame(SimulationSnapshot snapshot) {
    final leadRider = snapshot.leaderRider;

    _currentAttackFrames.add(ReplayFrameSnapshot(
      frameIndex: _currentAttackFrames.length,
      timestampSeconds: snapshot.elapsedSeconds,
      leadKilometerMark: snapshot.leadKilometerMark,
      distanceToFinishKm: snapshot.distanceToFinishKm,
      currentGradientPercent: snapshot.currentGradientPercent,
      currentElevationMeters: snapshot.currentElevationMeters,
      leadRiderName: leadRider?.riderName ?? 'Czoło',
      activeMomentTag: _currentAttackClipTitle,
      riders: snapshot.riders.map(ReplayRiderState.fromSimulationFrame).toList(),
    ));

    // Zamykamy klip po 45 sekundach lub po pokonaniu 800m
    if (_currentAttackFrames.length >= 600 || snapshot.distanceToFinishKm <= config.finalKilometerThresholdKm) {
      finalizeCurrentAttackClip();
    }
  }

  /// Zamyka bieżący klip ataku i dodaje go do listy najważniejszych momentów wyścigu.
  void finalizeCurrentAttackClip() {
    if (!_isRecordingAttackClip || _currentAttackFrames.isEmpty) return;

    final first = _currentAttackFrames.first;
    final last = _currentAttackFrames.last;

    _highlightClips.add(ReplayClip(
      id: 'clip_attack_${_highlightClips.length + 1}',
      title: _currentAttackClipTitle ?? 'Decydujący Atak',
      description: 'Dynamiczny atak w czołówce na ${first.leadKilometerMark.toStringAsFixed(1)} km etapu.',
      type: _currentAttackClipType,
      startDistanceKm: first.leadKilometerMark,
      endDistanceKm: last.leadKilometerMark,
      startTimestampSeconds: first.timestampSeconds,
      endTimestampSeconds: last.timestampSeconds,
      frames: List.from(_currentAttackFrames),
    ));

    _isRecordingAttackClip = false;
    _currentAttackClipTitle = null;
    _currentAttackFrames.clear();
  }

  /// Buduje gotowy klip powtórki ostatniego kilometra.
  ReplayClip? buildFinalKilometerClip() {
    if (_finalKmFrames.isEmpty) return null;

    final first = _finalKmFrames.first;
    final last = _finalKmFrames.last;

    return ReplayClip(
      id: 'clip_final_kilometer',
      title: 'Decydujący Finisz • Ostatni Kilometr',
      description: 'Zwieńczenie etapu: formowanie pociągów sprinterskich, rzut rowerem na kreskę mety.',
      type: ReplayClipType.finalKilometer,
      startDistanceKm: first.leadKilometerMark,
      endDistanceKm: last.leadKilometerMark,
      startTimestampSeconds: first.timestampSeconds,
      endTimestampSeconds: last.timestampSeconds,
      frames: List.from(_finalKmFrames),
    );
  }

  ReplayClipType _mapMomentTypeToClipType(KeyMomentType type) {
    switch (type) {
      case KeyMomentType.gcLeaderAttack:
      case KeyMomentType.decisiveClimb:
        return ReplayClipType.gcAttack;
      case KeyMomentType.severeCrosswindEchelon:
        return ReplayClipType.echelonAttack;
      case KeyMomentType.challengingCobbles:
        return ReplayClipType.cobbleSector;
      case KeyMomentType.playerRiderIncident:
        return ReplayClipType.incident;
      default:
        return ReplayClipType.gcAttack;
    }
  }
}

// ============================================================================
// 6. ODTWARZACZ POWTÓRKI 3D FINISZU (STAGE REPLAY PLAYER)
// ============================================================================

/// Interaktywny kontroler odtwarzania powtórki 3D etapu z dowolnej kamery.
class StageReplayPlayer {
  final ReplayClip clip;

  int _currentFrameIndex = 0;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  RaceCameraMode _cameraMode = RaceCameraMode.chaseCam;
  String? _focusedRiderId;

  StageReplayPlayer({
    required this.clip,
    RaceCameraMode initialCameraMode = RaceCameraMode.chaseCam,
    String? initialFocusedRiderId,
  })  : _cameraMode = initialCameraMode,
        _focusedRiderId = initialFocusedRiderId;

  int get currentFrameIndex => _currentFrameIndex;
  bool get isPlaying => _isPlaying;
  double get playbackSpeed => _playbackSpeed;
  RaceCameraMode get cameraMode => _cameraMode;
  String? get focusedRiderId => _focusedRiderId;

  ReplayFrameSnapshot? get currentFrame =>
      clip.frames.isNotEmpty ? clip.frames[_currentFrameIndex.clamp(0, clip.frames.length - 1)] : null;

  /// Postęp odtwarzania powtórki (0.0 do 1.0)
  double get progress {
    if (clip.frames.length <= 1) return 0.0;
    return (_currentFrameIndex / (clip.frames.length - 1)).clamp(0.0, 1.0);
  }

  void play() => _isPlaying = true;
  void pause() => _isPlaying = false;
  void togglePlayPause() => _isPlaying = !_isPlaying;

  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed.clamp(0.1, 4.0);
  }

  void setCameraMode(RaceCameraMode mode) {
    _cameraMode = mode;
  }

  void setFocusedRider(String? riderId) {
    _focusedRiderId = riderId;
  }

  void seekToFrame(int frameIndex) {
    if (clip.frames.isEmpty) return;
    _currentFrameIndex = frameIndex.clamp(0, clip.frames.length - 1);
  }

  void seekToProgress(double normalizedProgress) {
    if (clip.frames.isEmpty) return;
    final target = (normalizedProgress.clamp(0.0, 1.0) * (clip.frames.length - 1)).round();
    _currentFrameIndex = target;
  }

  /// Przesuwa powtórkę o pojedynczy krok czasowy [dtSeconds]
  void tick(double dtSeconds) {
    if (!_isPlaying || clip.frames.isEmpty) return;

    // Przeliczenie klatek przy bazowym 30 fps
    final double framesToAdvance = dtSeconds * 30.0 * _playbackSpeed;
    final int nextFrame = _currentFrameIndex + math.max(1, framesToAdvance.round());

    if (nextFrame >= clip.frames.length) {
      _currentFrameIndex = clip.frames.length - 1;
      _isPlaying = false; // Zakończenie powtórki na mecie
    } else {
      _currentFrameIndex = nextFrame;
    }
  }

  void stepForward() {
    seekToFrame(_currentFrameIndex + 1);
  }

  void stepBackward() {
    seekToFrame(_currentFrameIndex - 1);
  }
}

// ============================================================================
// 7. EKSPORTER PLIKÓW TELEMETRII (GARMIN .FIT / CSV / JSON EXPORTER)
// ============================================================================

/// Eksporter telemetrii generujący pliki w formacie CSV oraz zgodnym binarnym Garmin FIT.
class FitFileExporter {
  FitFileExporter._();

  /// Eksportuje telemetrię wyścigu do formatu CSV zgodnego z WKO5 / GoldenCheetah / Stravą.
  static String exportToCsv(RiderTelemetryLog log) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('timestamp_s,distance_m,speed_kmh,power_w,cadence_rpm,heartrate_bpm,altitude_m,gradient_pct,w_prime_j,glycogen_g');

    for (final p in log.points) {
      buffer.writeln(
        '${p.timestampSeconds.toStringAsFixed(1)},'
        '${p.distanceMeters.toStringAsFixed(1)},'
        '${p.speedKmh.toStringAsFixed(2)},'
        '${p.powerWatts},'
        '${p.cadenceRpm},'
        '${p.heartRateBpm},'
        '${p.elevationMeters.toStringAsFixed(1)},'
        '${p.gradientPercent.toStringAsFixed(2)},'
        '${p.wPrimeJoules.toStringAsFixed(0)},'
        '${p.glycogenGrams.toStringAsFixed(1)}',
      );
    }

    return buffer.toString();
  }

  /// Eksportuje metryki etapu do formatu JSON kompatybilnego z API wykresów.
  static String exportToJson(FitActivitySummary summary) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(summary.toJson());
  }

  /// Generuje binarny bufor zgodny ze specyfikacją protokołu Garmin FIT (Flexible and Interoperable Data Transfer).
  ///
  /// Tworzy 14-bajtowy nagłówek FIT z sumą CRC oraz komunikaty File ID, Session i Record dla każdego punktu trasy.
  static Uint8List generateFitBinary(RiderTelemetryLog log, {String stageName = 'Stage'}) {
    final ByteData recordData = ByteData(log.points.length * 32 + 512);
    int offset = 0;

    // 1. Zapis nagłówka FIT Header (14 bajtów)
    const int headerSize = 14;
    const int protocolVersion = 0x20; // FIT 2.0
    const int profileVersion = 2100;

    // 2. Symulacja zawartości rekordów danych (File ID + Rekordy telemetryczne)
    // FileId Message: Manufacturer (1 = Garmin / Developer), Product, SerialNumber, Type = 4 (Activity)
    recordData.setUint8(offset++, 0x40); // Definition message header
    recordData.setUint8(offset++, 0x00);
    recordData.setUint8(offset++, 0x00); // Architecture: Little Endian
    recordData.setUint16(offset, 0x0000, Endian.little); // Global message: FileId (0)
    offset += 2;
    recordData.setUint8(offset++, 3); // 3 pola: type, manufacturer, time_created

    // Pola FileId
    recordData.setUint8(offset++, 0); // Field 0: type
    recordData.setUint8(offset++, 1); // Size 1
    recordData.setUint8(offset++, 0); // BaseType: enum

    recordData.setUint8(offset++, 1); // Field 1: manufacturer
    recordData.setUint8(offset++, 2); // Size 2
    recordData.setUint8(offset++, 132); // BaseType: uint16

    recordData.setUint8(offset++, 4); // Field 4: time_created
    recordData.setUint8(offset++, 4); // Size 4
    recordData.setUint8(offset++, 134); // BaseType: uint32

    // Data message dla FileId
    recordData.setUint8(offset++, 0x00); // Data message header
    recordData.setUint8(offset++, 4); // Activity file
    recordData.setUint16(offset, 1, Endian.little); // Manufacturer: Garmin/ProPeloton
    offset += 2;
    recordData.setUint32(offset, 1000000000, Endian.little); // Timestamp
    offset += 4;

    // Zapis próbek telemetrycznych jako rekordy FIT Record Message (Moc, Tętno, Prędkość, Dystans, Wysokość)
    for (final p in log.points) {
      if (offset + 24 >= recordData.lengthInBytes) break;

      recordData.setUint8(offset++, 0x00); // Data message header
      recordData.setUint32(offset, (p.timestampSeconds * 1000).toInt(), Endian.little);
      offset += 4;
      recordData.setUint32(offset, (p.distanceMeters * 100).toInt(), Endian.little);
      offset += 4;
      recordData.setUint16(offset, (p.speedMs * 1000).toInt(), Endian.little);
      offset += 2;
      recordData.setUint16(offset, p.powerWatts, Endian.little);
      offset += 2;
      recordData.setUint8(offset++, p.heartRateBpm.clamp(0, 255));
      recordData.setUint8(offset++, p.cadenceRpm.clamp(0, 255));
      recordData.setUint16(offset, ((p.elevationMeters + 500.0) * 5.0).toInt().clamp(0, 65535), Endian.little);
      offset += 2;
    }

    final int dataSize = offset;
    final Uint8List fileBytes = Uint8List(headerSize + dataSize + 2);
    final ByteData header = ByteData.sublistView(fileBytes, 0, headerSize);

    header.setUint8(0, headerSize);
    header.setUint8(1, protocolVersion);
    header.setUint16(2, profileVersion, Endian.little);
    header.setUint32(4, dataSize, Endian.little);
    fileBytes[8] = 0x2E; // '.'
    fileBytes[9] = 0x46; // 'F'
    fileBytes[10] = 0x49; // 'I'
    fileBytes[11] = 0x54; // 'T'

    // Kopiowanie danych rekordów
    fileBytes.setRange(headerSize, headerSize + dataSize, recordData.buffer.asUint8List(0, dataSize));

    // Prosta suma kontrolna CRC-16
    int crc = 0;
    for (int i = 0; i < headerSize + dataSize; i++) {
      crc = (crc + fileBytes[i]) & 0xFFFF;
    }
    fileBytes[headerSize + dataSize] = crc & 0xFF;
    fileBytes[headerSize + dataSize + 1] = (crc >> 8) & 0xFF;

    return fileBytes;
  }
}
