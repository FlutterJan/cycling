import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/simulation/stage_replay_recorder.dart';
import '../../models/race/race_stage.dart';

/// Obsługiwane standardy eksportu telemetrii kolarskiej do programów zewnętrznych
/// (Strava, TrainingPeaks, WKO5, Intervals.icu, GoldenCheetah, Garmin Connect).
enum TelemetryExportFormat {
  tcx('tcx', 'Garmin TCX v2 (.tcx)', 'Training Center XML + Power/Cadence'),
  gpx('gpx', 'GPX 1.1 + Extensions (.gpx)', 'Topografix GPX + Garmin TrackPointExtension');

  final String fileExtension;
  final String displayName;
  final String subtitle;

  const TelemetryExportFormat(this.fileExtension, this.displayName, this.subtitle);
}

/// Predefiniowane współrzędne startowe (WGS84) dla kultowych regionów kolarskich.
enum GpsOriginPreset {
  alpeDHuez('Bourg-d\'Oisans (Alpy)', 45.0558, 6.0289),
  montVentoux('Bédoin (Prowansja)', 44.1235, 5.1795),
  roubaix('Compiègne (Paryż-Roubaix)', 49.4179, 2.8261),
  tourmalet('Sainte-Marie-de-Campan (Pireneje)', 42.9864, 0.2261),
  siena('Siena (Strade Bianche)', 43.3188, 11.3308),
  flanders('Antwerpia (Flandria)', 51.2194, 4.4025);

  final String label;
  final double latitude;
  final double longitude;

  const GpsOriginPreset(this.label, this.latitude, this.longitude);
}

/// Pojedyncza próbka telemetryczna gotowa do zapisu w pliku `.tcx` / `.gpx`.
class TelemetryExportSample {
  /// Czas od startu ostrego w sekundach [s].
  final double elapsedSeconds;

  /// Szerokość geograficzna WGS84 [deg].
  final double latitude;

  /// Długość geograficzna WGS84 [deg].
  final double longitude;

  /// Wysokość n.p.m. [m].
  final double elevationMeters;

  /// Dystans narastająco od startu [m].
  final double distanceMeters;

  /// Prędkość chwilowa [m/s].
  final double speedMs;

  /// Moc na pedałach [W].
  final int powerWatts;

  /// Tętno [bpm].
  final int heartRateBpm;

  /// Kadencja [rpm].
  final int cadenceRpm;

  /// Opcjonalna temperatura otoczenia [°C].
  final double? temperatureCelsius;

  const TelemetryExportSample({
    required this.elapsedSeconds,
    required this.latitude,
    required this.longitude,
    required this.elevationMeters,
    required this.distanceMeters,
    required this.speedMs,
    required this.powerWatts,
    required this.heartRateBpm,
    required this.cadenceRpm,
    this.temperatureCelsius,
  });

  TelemetryExportSample copyWith({
    double? elapsedSeconds,
    double? latitude,
    double? longitude,
    double? elevationMeters,
    double? distanceMeters,
    double? speedMs,
    int? powerWatts,
    int? heartRateBpm,
    int? cadenceRpm,
    double? temperatureCelsius,
  }) {
    return TelemetryExportSample(
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      elevationMeters: elevationMeters ?? this.elevationMeters,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      speedMs: speedMs ?? this.speedMs,
      powerWatts: powerWatts ?? this.powerWatts,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      cadenceRpm: cadenceRpm ?? this.cadenceRpm,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
    );
  }
}

/// Pełna sesja ukończonego etapu kolarza do eksportu telemetrycznego.
class TelemetryExportSession {
  final String stageId;
  final String stageName;
  final String riderName;
  final String teamName;
  final double riderWeightKg;
  final DateTime startTimeUtc;
  final List<TelemetryExportSample> samples;
  final String creatorAppName;

  const TelemetryExportSession({
    required this.stageId,
    required this.stageName,
    required this.riderName,
    required this.teamName,
    required this.riderWeightKg,
    required this.startTimeUtc,
    required this.samples,
    this.creatorAppName = 'Pro Peloton Manager',
  });
}

/// Wynik eksportu zawierający gotowy dokument XML oraz podsumowanie metryk.
class TelemetryExportResult {
  final TelemetryExportFormat format;
  final String xmlContent;
  final String suggestedFileName;
  final int trackpointCount;
  final double durationSeconds;
  final double totalDistanceMeters;
  final double elevationGainMeters;
  final double averagePowerWatts;
  final double normalizedPowerWatts;
  final int maxPowerWatts;
  final int averageHeartRateBpm;
  final int maxHeartRateBpm;
  final int averageCadenceRpm;
  final double averageSpeedMs;
  final double maxSpeedMs;
  final int estimatedCaloriesKcal;
  final int byteSize;

  const TelemetryExportResult({
    required this.format,
    required this.xmlContent,
    required this.suggestedFileName,
    required this.trackpointCount,
    required this.durationSeconds,
    required this.totalDistanceMeters,
    required this.elevationGainMeters,
    required this.averagePowerWatts,
    required this.normalizedPowerWatts,
    required this.maxPowerWatts,
    required this.averageHeartRateBpm,
    required this.maxHeartRateBpm,
    required this.averageCadenceRpm,
    required this.averageSpeedMs,
    required this.maxSpeedMs,
    required this.estimatedCaloriesKcal,
    required this.byteSize,
  });
}

/// Raport walidacji poprawności wygenerowanego pliku `.tcx` lub `.gpx`.
class TelemetryXmlValidationReport {
  final bool isValid;
  final TelemetryExportFormat format;
  final int detectedTrackpoints;
  final bool hasPowerData;
  final bool hasHeartRateData;
  final bool hasCadenceData;
  final bool hasElevationData;
  final bool hasMonotonicTimestamps;
  final List<String> errors;

  const TelemetryXmlValidationReport({
    required this.isValid,
    required this.format,
    required this.detectedTrackpoints,
    required this.hasPowerData,
    required this.hasHeartRateData,
    required this.hasCadenceData,
    required this.hasElevationData,
    required this.hasMonotonicTimestamps,
    required this.errors,
  });
}

/// Projektor współrzędnych geograficznych WGS84 na podstawie profilu etapu i azymutów.
class GpsTrackProjector {
  static const double _earthRadiusMeters = 6371000.0;

  /// Wylicza docelowy punkt (lat, lon) przesunięty o [distanceMeters]
  /// pod azymutem [bearingDegrees] (0° = północ, 90° = wschód).
  static ({double latitude, double longitude}) destinationPoint({
    required double startLatitude,
    required double startLongitude,
    required double distanceMeters,
    required double bearingDegrees,
  }) {
    if (distanceMeters == 0.0) {
      return (latitude: startLatitude, longitude: startLongitude);
    }

    final double lat1 = _degToRad(startLatitude);
    final double lon1 = _degToRad(startLongitude);
    final double brng = _degToRad(bearingDegrees);
    final double angularDistance = distanceMeters / _earthRadiusMeters;

    final double sinLat1 = math.sin(lat1);
    final double cosLat1 = math.cos(lat1);
    final double sinAd = math.sin(angularDistance);
    final double cosAd = math.cos(angularDistance);

    final double lat2 = math.asin(
      (sinLat1 * cosAd + cosLat1 * sinAd * math.cos(brng)).clamp(-1.0, 1.0),
    );
    final double lon2 = lon1 +
        math.atan2(
          math.sin(brng) * sinAd * cosLat1,
          cosAd - sinLat1 * math.sin(lat2),
        );

    return (
      latitude: _radToDeg(lat2),
      longitude: ((_radToDeg(lon2) + 540.0) % 360.0) - 180.0,
    );
  }

  /// Rzutuje punkty dystansu z [RaceStage] na ślad GPS WGS84.
  static List<({double latitude, double longitude})> projectRouteDistances({
    required List<double> distancesMeters,
    required RaceStage stage,
    required double startLatitude,
    required double startLongitude,
    List<double>? lateralRoadOffsets,
  }) {
    if (distancesMeters.isEmpty) return const [];

    final segments = stage.segments;
    final List<({double latitude, double longitude})> coords =
        List.filled(distancesMeters.length, (latitude: startLatitude, longitude: startLongitude));

    double currentLat = startLatitude;
    double currentLon = startLongitude;
    double prevDist = 0.0;

    for (int i = 0; i < distancesMeters.length; i++) {
      final double dist = math.max(0.0, distancesMeters[i]);
      final double deltaDist = math.max(0.0, dist - prevDist);
      final double distKm = dist / 1000.0;

      double bearing = 90.0;
      if (segments.isNotEmpty) {
        var matched = segments.last;
        for (final seg in segments) {
          if (distKm >= seg.startKm && distKm <= seg.endKm) {
            matched = seg;
            break;
          }
        }
        bearing = matched.roadBearingDegrees;
      }

      if (deltaDist > 0.0) {
        final next = destinationPoint(
          startLatitude: currentLat,
          startLongitude: currentLon,
          distanceMeters: deltaDist,
          bearingDegrees: bearing,
        );
        currentLat = next.latitude;
        currentLon = next.longitude;
      }

      double finalLat = currentLat;
      double finalLon = currentLon;
      if (lateralRoadOffsets != null && i < lateralRoadOffsets.length) {
        final double lateralMeters = lateralRoadOffsets[i].clamp(-1.0, 1.0) * 3.5;
        if (lateralMeters.abs() > 0.01) {
          final lateralPoint = destinationPoint(
            startLatitude: currentLat,
            startLongitude: currentLon,
            distanceMeters: lateralMeters.abs(),
            bearingDegrees: (bearing + (lateralMeters >= 0 ? 90.0 : 270.0)) % 360.0,
          );
          finalLat = lateralPoint.latitude;
          finalLon = lateralPoint.longitude;
        }
      }

      coords[i] = (latitude: finalLat, longitude: finalLon);
      prevDist = dist;
    }

    return coords;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
  static double _radToDeg(double rad) => rad * (180.0 / math.pi);
}

/// Produkcyjny eksporter danych wyścigowych do standardów `.tcx` (Garmin TCX v2)
/// oraz `.gpx` (GPX 1.1 + Garmin TrackPointExtension v1) z zapisem sekunda po sekundzie.
class GpxAndTcxTelemetryExporter {
  const GpxAndTcxTelemetryExporter();

  /// Konwertuje punkty nagrane przez `StageReplayRecorder` i model `RaceStage`
  /// na sesję eksportową z wyliczonymi współrzędnymi GPS WGS84.
  static TelemetryExportSession fromStageReplayTrackPoints({
    required RaceStage stage,
    required String riderName,
    required String teamName,
    required double riderWeightKg,
    required List<RiderTelemetryTrackPoint> trackPoints,
    DateTime? startTimeUtc,
    GpsOriginPreset originPreset = GpsOriginPreset.alpeDHuez,
    double? customStartLatitude,
    double? customStartLongitude,
  }) {
    final double originLat = customStartLatitude ?? originPreset.latitude;
    final double originLon = customStartLongitude ?? originPreset.longitude;
    final DateTime effectiveStart = (startTimeUtc ?? DateTime.now().toUtc()).toUtc();

    if (trackPoints.isEmpty) {
      return TelemetryExportSession(
        stageId: stage.id,
        stageName: stage.name,
        riderName: riderName,
        teamName: teamName,
        riderWeightKg: riderWeightKg,
        startTimeUtc: effectiveStart,
        samples: const [],
      );
    }

    final sorted = List<RiderTelemetryTrackPoint>.from(trackPoints)
      ..sort((a, b) => a.timestampSeconds.compareTo(b.timestampSeconds));

    final distances = sorted.map((p) => p.distanceMeters).toList(growable: false);
    final laterals = sorted.map((p) => p.lateralPositionRoad).toList(growable: false);
    final coords = GpsTrackProjector.projectRouteDistances(
      distancesMeters: distances,
      stage: stage,
      startLatitude: originLat,
      startLongitude: originLon,
      lateralRoadOffsets: laterals,
    );

    final samples = <TelemetryExportSample>[];
    for (int i = 0; i < sorted.length; i++) {
      final pt = sorted[i];
      final coord = coords[i];
      // Temperatura spada z wysokością (~0.65°C na 100 m powyżej 500 m)
      final double localTemp =
          stage.baseTemperatureCelsius - math.max(0.0, pt.elevationMeters - 500.0) * 0.0065;

      samples.add(
        TelemetryExportSample(
          elapsedSeconds: pt.timestampSeconds,
          latitude: coord.latitude,
          longitude: coord.longitude,
          elevationMeters: pt.elevationMeters,
          distanceMeters: pt.distanceMeters,
          speedMs: pt.speedMs,
          powerWatts: pt.powerWatts,
          heartRateBpm: pt.heartRateBpm,
          cadenceRpm: pt.cadenceRpm,
          temperatureCelsius: localTemp,
        ),
      );
    }

    return TelemetryExportSession(
      stageId: stage.id,
      stageName: stage.name,
      riderName: riderName,
      teamName: teamName,
      riderWeightKg: riderWeightKg,
      startTimeUtc: effectiveStart,
      samples: samples,
    );
  }

  /// Resampluje próbkę wejściową do idealnej siatki 1 Hz (sekunda po sekundzie),
  /// stosując interpolację liniową dla wszystkich kanałów telemetrycznych.
  List<TelemetryExportSample> resampleToOneSecond(List<TelemetryExportSample> rawSamples) {
    if (rawSamples.isEmpty) return const [];
    final sorted = List<TelemetryExportSample>.from(rawSamples)
      ..sort((a, b) => a.elapsedSeconds.compareTo(b.elapsedSeconds));

    if (sorted.length == 1) {
      final only = sorted.first;
      return [
        only.copyWith(elapsedSeconds: only.elapsedSeconds.roundToDouble()),
      ];
    }

    final int startSec = sorted.first.elapsedSeconds.floor();
    final int endSec = sorted.last.elapsedSeconds.ceil();
    final List<TelemetryExportSample> resampled = [];

    int cursor = 0;
    for (int sec = startSec; sec <= endSec; sec++) {
      final double targetT = sec.toDouble();
      while (cursor + 1 < sorted.length && sorted[cursor + 1].elapsedSeconds < targetT) {
        cursor++;
      }

      if (targetT <= sorted.first.elapsedSeconds) {
        resampled.add(sorted.first.copyWith(elapsedSeconds: targetT));
        continue;
      }
      if (targetT >= sorted.last.elapsedSeconds || cursor + 1 >= sorted.length) {
        resampled.add(sorted.last.copyWith(elapsedSeconds: targetT));
        continue;
      }

      final a = sorted[cursor];
      final b = sorted[cursor + 1];
      final double span = b.elapsedSeconds - a.elapsedSeconds;
      final double ratio = span <= 1e-6 ? 0.0 : ((targetT - a.elapsedSeconds) / span).clamp(0.0, 1.0);

      double lerpDouble(double v1, double v2) => v1 + (v2 - v1) * ratio;
      int lerpInt(int v1, int v2) => (v1 + (v2 - v1) * ratio).round();

      final double? temp = (a.temperatureCelsius != null && b.temperatureCelsius != null)
          ? lerpDouble(a.temperatureCelsius!, b.temperatureCelsius!)
          : (a.temperatureCelsius ?? b.temperatureCelsius);

      resampled.add(
        TelemetryExportSample(
          elapsedSeconds: targetT,
          latitude: lerpDouble(a.latitude, b.latitude),
          longitude: lerpDouble(a.longitude, b.longitude),
          elevationMeters: lerpDouble(a.elevationMeters, b.elevationMeters),
          distanceMeters: lerpDouble(a.distanceMeters, b.distanceMeters),
          speedMs: math.max(0.0, lerpDouble(a.speedMs, b.speedMs)),
          powerWatts: math.max(0, lerpInt(a.powerWatts, b.powerWatts)),
          heartRateBpm: lerpInt(a.heartRateBpm, b.heartRateBpm).clamp(30, 230),
          cadenceRpm: lerpInt(a.cadenceRpm, b.cadenceRpm).clamp(0, 200),
          temperatureCelsius: temp,
        ),
      );
    }

    return resampled;
  }

  /// Generuje kompletny, zgodny ze standardem dokument `.tcx` lub `.gpx`.
  TelemetryExportResult export({
    required TelemetryExportSession session,
    required TelemetryExportFormat format,
    bool resampleOneSecond = true,
  }) {
    if (session.samples.isEmpty) {
      throw ArgumentError('Nie można wyeksportować pustej sesji telemetrycznej (brak punktów).');
    }

    final List<TelemetryExportSample> points = resampleOneSecond
        ? resampleToOneSecond(session.samples)
        : (List<TelemetryExportSample>.from(session.samples)
          ..sort((a, b) => a.elapsedSeconds.compareTo(b.elapsedSeconds)));

    final _TelemetryMetrics metrics = _computeMetrics(points);
    final String xmlContent = format == TelemetryExportFormat.tcx
        ? _buildTcxXml(session, points, metrics)
        : _buildGpxXml(session, points);

    final String fileName = _buildSuggestedFileName(session, format);

    return TelemetryExportResult(
      format: format,
      xmlContent: xmlContent,
      suggestedFileName: fileName,
      trackpointCount: points.length,
      durationSeconds: metrics.durationSeconds,
      totalDistanceMeters: metrics.totalDistanceMeters,
      elevationGainMeters: metrics.elevationGainMeters,
      averagePowerWatts: metrics.averagePowerWatts,
      normalizedPowerWatts: metrics.normalizedPowerWatts,
      maxPowerWatts: metrics.maxPowerWatts,
      averageHeartRateBpm: metrics.averageHeartRateBpm,
      maxHeartRateBpm: metrics.maxHeartRateBpm,
      averageCadenceRpm: metrics.averageCadenceRpm,
      averageSpeedMs: metrics.averageSpeedMs,
      maxSpeedMs: metrics.maxSpeedMs,
      estimatedCaloriesKcal: metrics.estimatedCaloriesKcal,
      byteSize: xmlContent.length,
    );
  }

  /// Zapisuje wyeksportowany plik `.tcx` / `.gpx` na dysku w katalogu [targetDirectory].
  Future<File> exportToFile({
    required TelemetryExportSession session,
    required TelemetryExportFormat format,
    required Directory targetDirectory,
    bool resampleOneSecond = true,
    String? customFileName,
  }) async {
    final result = export(
      session: session,
      format: format,
      resampleOneSecond: resampleOneSecond,
    );

    if (!await targetDirectory.exists()) {
      await targetDirectory.create(recursive: true);
    }

    final String fileName = (customFileName != null && customFileName.trim().isNotEmpty)
        ? customFileName.trim()
        : result.suggestedFileName;
    final String sep = Platform.pathSeparator;
    final String fullPath = targetDirectory.path.endsWith(sep)
        ? '${targetDirectory.path}$fileName'
        : '${targetDirectory.path}$sep$fileName';

    final file = File(fullPath);
    return file.writeAsString(result.xmlContent, flush: true);
  }

  /// Weryfikuje zgodność wygenerowanego XML ze schematem TCX v2 lub GPX 1.1.
  TelemetryXmlValidationReport validateExportedXml(
    String xml,
    TelemetryExportFormat format,
  ) {
    final errors = <String>[];
    if (!xml.startsWith('<?xml version="1.0" encoding="UTF-8"?>')) {
      errors.add('Brak nagłówka XML UTF-8.');
    }

    int trackpointCount = 0;
    bool hasPower = false;
    bool hasHr = false;
    bool hasCad = false;
    bool hasEle = false;

    if (format == TelemetryExportFormat.tcx) {
      if (!xml.contains('<TrainingCenterDatabase') || !xml.contains('</TrainingCenterDatabase>')) {
        errors.add('Brak głównego kontenera <TrainingCenterDatabase>.');
      }
      if (!xml.contains('<Activity Sport="Biking">')) {
        errors.add('Brak aktywności <Activity Sport="Biking">.');
      }
      trackpointCount = RegExp(r'<Trackpoint>').allMatches(xml).length;
      final closeCount = RegExp(r'</Trackpoint>').allMatches(xml).length;
      if (trackpointCount == 0 || trackpointCount != closeCount) {
        errors.add('Nieprawidłowa liczba znaczników <Trackpoint>.');
      }
      hasPower = xml.contains('<ns3:Watts>');
      hasHr = xml.contains('<HeartRateBpm>');
      hasCad = xml.contains('<Cadence>');
      hasEle = xml.contains('<AltitudeMeters>');
    } else {
      if (!xml.contains('<gpx ') || !xml.contains('</gpx>')) {
        errors.add('Brak głównego kontenera <gpx>.');
      }
      if (!xml.contains('<trkseg>') || !xml.contains('</trkseg>')) {
        errors.add('Brak segmentu trasy <trkseg>.');
      }
      trackpointCount = RegExp(r'<trkpt\s+lat="').allMatches(xml).length;
      final closeCount = RegExp(r'</trkpt>').allMatches(xml).length;
      if (trackpointCount == 0 || trackpointCount != closeCount) {
        errors.add('Nieprawidłowa liczba znaczników <trkpt>.');
      }
      hasPower = xml.contains('<power>');
      hasHr = xml.contains('<gpxtpx:hr>');
      hasCad = xml.contains('<gpxtpx:cad>');
      hasEle = xml.contains('<ele>');
    }

    final timeMatches = RegExp(r'<Time>([^<]+)</Time>|<time>([^<]+)</time>').allMatches(xml);
    DateTime? prevTime;
    bool monotonic = true;
    int pointTimesChecked = 0;
    for (final m in timeMatches) {
      final raw = m.group(1) ?? m.group(2);
      if (raw == null) continue;
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) {
        errors.add('Nieprawidłowy znacznik czasu ISO-8601: $raw');
        monotonic = false;
        break;
      }
      // Pomijamy <time> z nagłówka <metadata> lub <Id> w porównaniu sekwencyjnym jeśli są równe pierwszemu
      if (prevTime != null && parsed.isBefore(prevTime)) {
        monotonic = false;
        errors.add('Niemotoniczny znacznik czasu: $raw < ${prevTime.toIso8601String()}');
        break;
      }
      prevTime = parsed;
      pointTimesChecked++;
    }
    if (pointTimesChecked == 0) {
      monotonic = false;
      errors.add('Brak znaczników czasu.');
    }

    return TelemetryXmlValidationReport(
      isValid: errors.isEmpty,
      format: format,
      detectedTrackpoints: trackpointCount,
      hasPowerData: hasPower,
      hasHeartRateData: hasHr,
      hasCadenceData: hasCad,
      hasElevationData: hasEle,
      hasMonotonicTimestamps: monotonic,
      errors: errors,
    );
  }

  String _buildTcxXml(
    TelemetryExportSession session,
    List<TelemetryExportSample> points,
    _TelemetryMetrics metrics,
  ) {
    final buf = StringBuffer();
    final DateTime startUtc = session.startTimeUtc.toUtc();
    final String activityIdIso = _formatIsoUtc(startUtc);

    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.writeln(
      '<TrainingCenterDatabase '
      'xsi:schemaLocation="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2 '
      'http://www.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd" '
      'xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2" '
      'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
      'xmlns:ns3="http://www.garmin.com/xmlschemas/ActivityExtension/v2">',
    );
    buf.writeln('  <Activities>');
    buf.writeln('    <Activity Sport="Biking">');
    buf.writeln('      <Id>$activityIdIso</Id>');
    buf.writeln('      <Lap StartTime="$activityIdIso">');
    buf.writeln('        <TotalTimeSeconds>${metrics.durationSeconds.toStringAsFixed(1)}</TotalTimeSeconds>');
    buf.writeln('        <DistanceMeters>${metrics.totalDistanceMeters.toStringAsFixed(2)}</DistanceMeters>');
    buf.writeln('        <MaximumSpeed>${metrics.maxSpeedMs.toStringAsFixed(3)}</MaximumSpeed>');
    buf.writeln('        <Calories>${metrics.estimatedCaloriesKcal}</Calories>');
    buf.writeln('        <AverageHeartRateBpm>');
    buf.writeln('          <Value>${metrics.averageHeartRateBpm}</Value>');
    buf.writeln('        </AverageHeartRateBpm>');
    buf.writeln('        <MaximumHeartRateBpm>');
    buf.writeln('          <Value>${metrics.maxHeartRateBpm}</Value>');
    buf.writeln('        </MaximumHeartRateBpm>');
    buf.writeln('        <Intensity>Active</Intensity>');
    buf.writeln('        <Cadence>${metrics.averageCadenceRpm}</Cadence>');
    buf.writeln('        <TriggerMethod>Manual</TriggerMethod>');
    buf.writeln('        <Track>');

    for (final pt in points) {
      final DateTime ptTime = startUtc.add(
        Duration(milliseconds: (pt.elapsedSeconds * 1000.0).round()),
      );
      buf.writeln('          <Trackpoint>');
      buf.writeln('            <Time>${_formatIsoUtc(ptTime)}</Time>');
      buf.writeln('            <Position>');
      buf.writeln('              <LatitudeDegrees>${pt.latitude.toStringAsFixed(7)}</LatitudeDegrees>');
      buf.writeln('              <LongitudeDegrees>${pt.longitude.toStringAsFixed(7)}</LongitudeDegrees>');
      buf.writeln('            </Position>');
      buf.writeln('            <AltitudeMeters>${pt.elevationMeters.toStringAsFixed(1)}</AltitudeMeters>');
      buf.writeln('            <DistanceMeters>${pt.distanceMeters.toStringAsFixed(2)}</DistanceMeters>');
      buf.writeln('            <HeartRateBpm>');
      buf.writeln('              <Value>${pt.heartRateBpm.clamp(30, 230)}</Value>');
      buf.writeln('            </HeartRateBpm>');
      buf.writeln('            <Cadence>${pt.cadenceRpm.clamp(0, 200)}</Cadence>');
      buf.writeln('            <Extensions>');
      buf.writeln('              <ns3:TPX>');
      buf.writeln('                <ns3:Speed>${pt.speedMs.toStringAsFixed(3)}</ns3:Speed>');
      buf.writeln('                <ns3:Watts>${math.max(0, pt.powerWatts)}</ns3:Watts>');
      buf.writeln('              </ns3:TPX>');
      buf.writeln('            </Extensions>');
      buf.writeln('          </Trackpoint>');
    }

    buf.writeln('        </Track>');
    buf.writeln('        <Extensions>');
    buf.writeln('          <ns3:LX>');
    buf.writeln('            <ns3:AvgSpeed>${metrics.averageSpeedMs.toStringAsFixed(3)}</ns3:AvgSpeed>');
    buf.writeln('            <ns3:AvgWatts>${metrics.averagePowerWatts.round()}</ns3:AvgWatts>');
    buf.writeln('            <ns3:MaxWatts>${metrics.maxPowerWatts}</ns3:MaxWatts>');
    buf.writeln('          </ns3:LX>');
    buf.writeln('        </Extensions>');
    buf.writeln('      </Lap>');
    buf.writeln(
      '      <Notes>${_escapeXml('${session.stageName} — ${session.riderName} (${session.teamName})')}</Notes>',
    );
    buf.writeln('      <Creator xsi:type="Device_t">');
    buf.writeln('        <Name>${_escapeXml(session.creatorAppName)}</Name>');
    buf.writeln('        <UnitId>20260001</UnitId>');
    buf.writeln('        <ProductID>4026</ProductID>');
    buf.writeln('        <Version>');
    buf.writeln('          <VersionMajor>2</VersionMajor>');
    buf.writeln('          <VersionMinor>0</VersionMinor>');
    buf.writeln('          <BuildMajor>1</BuildMajor>');
    buf.writeln('          <BuildMinor>0</BuildMinor>');
    buf.writeln('        </Version>');
    buf.writeln('      </Creator>');
    buf.writeln('    </Activity>');
    buf.writeln('  </Activities>');
    buf.writeln('  <Author xsi:type="Application_t">');
    buf.writeln('    <Name>${_escapeXml(session.creatorAppName)}</Name>');
    buf.writeln('    <Build>');
    buf.writeln('      <Version>');
    buf.writeln('        <VersionMajor>2</VersionMajor>');
    buf.writeln('        <VersionMinor>0</VersionMinor>');
    buf.writeln('      </Version>');
    buf.writeln('    </Build>');
    buf.writeln('    <LangID>en</LangID>');
    buf.writeln('    <PartNumber>PPM-TCX-001</PartNumber>');
    buf.writeln('  </Author>');
    buf.writeln('</TrainingCenterDatabase>');

    return buf.toString();
  }

  String _buildGpxXml(
    TelemetryExportSession session,
    List<TelemetryExportSample> points,
  ) {
    final buf = StringBuffer();
    final DateTime startUtc = session.startTimeUtc.toUtc();
    final String startIso = _formatIsoUtc(startUtc);
    final String trackName = '${session.stageName} - ${session.riderName}';

    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.writeln(
      '<gpx version="1.1" creator="${_escapeXml(session.creatorAppName)}" '
      'xmlns="http://www.topografix.com/GPX/1/1" '
      'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
      'xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1" '
      'xmlns:gpxpx="http://www.garmin.com/xmlschemas/PowerExtension/v1" '
      'xsi:schemaLocation="http://www.topografix.com/GPX/1/1 '
      'http://www.topografix.com/GPX/1/1/gpx.xsd '
      'http://www.garmin.com/xmlschemas/TrackPointExtension/v1 '
      'http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd">',
    );
    buf.writeln('  <metadata>');
    buf.writeln('    <name>${_escapeXml(trackName)}</name>');
    buf.writeln(
      '    <desc>${_escapeXml('Race telemetry exported from ${session.creatorAppName} (${session.teamName})')}</desc>',
    );
    buf.writeln('    <author>');
    buf.writeln('      <name>${_escapeXml(session.riderName)}</name>');
    buf.writeln('    </author>');
    buf.writeln('    <time>$startIso</time>');
    buf.writeln('  </metadata>');
    buf.writeln('  <trk>');
    buf.writeln('    <name>${_escapeXml(trackName)}</name>');
    buf.writeln('    <type>cycling</type>');
    buf.writeln('    <trkseg>');

    for (final pt in points) {
      final DateTime ptTime = startUtc.add(
        Duration(milliseconds: (pt.elapsedSeconds * 1000.0).round()),
      );
      buf.writeln(
        '      <trkpt lat="${pt.latitude.toStringAsFixed(7)}" '
        'lon="${pt.longitude.toStringAsFixed(7)}">',
      );
      buf.writeln('        <ele>${pt.elevationMeters.toStringAsFixed(1)}</ele>');
      buf.writeln('        <time>${_formatIsoUtc(ptTime)}</time>');
      buf.writeln('        <extensions>');
      buf.writeln('          <power>${math.max(0, pt.powerWatts)}</power>');
      buf.writeln('          <gpxtpx:TrackPointExtension>');
      if (pt.temperatureCelsius != null) {
        buf.writeln(
          '            <gpxtpx:atemp>${pt.temperatureCelsius!.toStringAsFixed(1)}</gpxtpx:atemp>',
        );
      }
      buf.writeln('            <gpxtpx:hr>${pt.heartRateBpm.clamp(30, 230)}</gpxtpx:hr>');
      buf.writeln('            <gpxtpx:cad>${pt.cadenceRpm.clamp(0, 200)}</gpxtpx:cad>');
      buf.writeln('            <gpxtpx:speed>${pt.speedMs.toStringAsFixed(3)}</gpxtpx:speed>');
      buf.writeln('          </gpxtpx:TrackPointExtension>');
      buf.writeln('        </extensions>');
      buf.writeln('      </trkpt>');
    }

    buf.writeln('    </trkseg>');
    buf.writeln('  </trk>');
    buf.writeln('</gpx>');

    return buf.toString();
  }

  _TelemetryMetrics _computeMetrics(List<TelemetryExportSample> points) {
    final double firstT = points.first.elapsedSeconds;
    final double lastT = points.last.elapsedSeconds;
    final double durationSec = math.max(1.0, lastT - firstT);
    final double totalDist = math.max(0.0, points.last.distanceMeters - points.first.distanceMeters);

    double elevGain = 0.0;
    double sumPower = 0.0;
    int maxPower = 0;
    double sumHr = 0.0;
    int maxHr = 0;
    double sumCadence = 0.0;
    int activeCadenceCount = 0;
    double sumSpeed = 0.0;
    double maxSpeed = 0.0;
    double totalWorkJoules = 0.0;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      if (i > 0) {
        final double dEle = pt.elevationMeters - points[i - 1].elevationMeters;
        if (dEle > 0.0) elevGain += dEle;
        final double dt = math.max(0.0, pt.elapsedSeconds - points[i - 1].elapsedSeconds);
        totalWorkJoules += pt.powerWatts * dt;
      }
      sumPower += pt.powerWatts;
      if (pt.powerWatts > maxPower) maxPower = pt.powerWatts;
      sumHr += pt.heartRateBpm;
      if (pt.heartRateBpm > maxHr) maxHr = pt.heartRateBpm;
      if (pt.cadenceRpm > 0) {
        sumCadence += pt.cadenceRpm;
        activeCadenceCount++;
      }
      sumSpeed += pt.speedMs;
      if (pt.speedMs > maxSpeed) maxSpeed = pt.speedMs;
    }

    // Normalized Power (Coggan 30s rolling average ^ 4)
    final double np = _computeNormalizedPower(points);
    // Szacunek kalorii przy sprawności mechanicznej ~24% (~1 kcal ≈ 4.184 kJ pracy metabolicznej)
    final int calories = (totalWorkJoules / 1000.0).round();

    return _TelemetryMetrics(
      durationSeconds: durationSec,
      totalDistanceMeters: totalDist,
      elevationGainMeters: elevGain,
      averagePowerWatts: sumPower / points.length,
      normalizedPowerWatts: np,
      maxPowerWatts: maxPower,
      averageHeartRateBpm: (sumHr / points.length).round(),
      maxHeartRateBpm: maxHr,
      averageCadenceRpm: activeCadenceCount > 0 ? (sumCadence / activeCadenceCount).round() : 0,
      averageSpeedMs: sumSpeed / points.length,
      maxSpeedMs: maxSpeed,
      estimatedCaloriesKcal: math.max(1, calories),
    );
  }

  double _computeNormalizedPower(List<TelemetryExportSample> points) {
    if (points.isEmpty) return 0.0;
    if (points.length < 30) {
      final avg = points.fold<double>(0.0, (s, p) => s + p.powerWatts) / points.length;
      return avg;
    }

    double rollingSum = 0.0;
    double fourthPowerSum = 0.0;
    int windowCount = 0;

    for (int i = 0; i < points.length; i++) {
      rollingSum += points[i].powerWatts;
      if (i >= 30) {
        rollingSum -= points[i - 30].powerWatts;
      }
      if (i >= 29) {
        final double avg30 = rollingSum / 30.0;
        fourthPowerSum += math.pow(avg30, 4).toDouble();
        windowCount++;
      }
    }

    if (windowCount == 0) return 0.0;
    return math.pow(fourthPowerSum / windowCount, 0.25).toDouble();
  }

  String _buildSuggestedFileName(
    TelemetryExportSession session,
    TelemetryExportFormat format,
  ) {
    final String datePart =
        '${session.startTimeUtc.year.toString().padLeft(4, '0')}'
        '-${session.startTimeUtc.month.toString().padLeft(2, '0')}'
        '-${session.startTimeUtc.day.toString().padLeft(2, '0')}';
    final String safeRider = _slugify(session.riderName);
    final String safeStage = _slugify(session.stageName);
    return '${datePart}_${safeStage}_$safeRider.${format.fileExtension}';
  }

  static String _slugify(String raw) {
    final normalized = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'stage' : normalized;
  }

  static String _formatIsoUtc(DateTime dt) {
    final u = dt.toUtc();
    String p2(int v) => v.toString().padLeft(2, '0');
    return '${u.year.toString().padLeft(4, '0')}-${p2(u.month)}-${p2(u.day)}'
        'T${p2(u.hour)}:${p2(u.minute)}:${p2(u.second)}Z';
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

class _TelemetryMetrics {
  final double durationSeconds;
  final double totalDistanceMeters;
  final double elevationGainMeters;
  final double averagePowerWatts;
  final double normalizedPowerWatts;
  final int maxPowerWatts;
  final int averageHeartRateBpm;
  final int maxHeartRateBpm;
  final int averageCadenceRpm;
  final double averageSpeedMs;
  final double maxSpeedMs;
  final int estimatedCaloriesKcal;

  const _TelemetryMetrics({
    required this.durationSeconds,
    required this.totalDistanceMeters,
    required this.elevationGainMeters,
    required this.averagePowerWatts,
    required this.normalizedPowerWatts,
    required this.maxPowerWatts,
    required this.averageHeartRateBpm,
    required this.maxHeartRateBpm,
    required this.averageCadenceRpm,
    required this.averageSpeedMs,
    required this.maxSpeedMs,
    required this.estimatedCaloriesKcal,
  });
}

// ============================================================================
// PANEL UI EKSPORTU TELEMETRII (.TCX / .GPX) — PALETA AppColors & INTER
// ============================================================================

/// Interaktywny panel eksportu telemetrii ukończonego etapu do `.tcx` / `.gpx`.
/// Zaprojektowany responsywnie (390x844 / 1024x768 / 1600x900) z pełnymi
/// stanami interakcji `hover` / `active` / `disabled` / `focus`.
class GpxAndTcxTelemetryExporterPanel extends StatefulWidget {
  final TelemetryExportSession? session;
  final ValueChanged<TelemetryExportResult>? onExported;
  final bool enabled;

  const GpxAndTcxTelemetryExporterPanel({
    super.key,
    required this.session,
    this.onExported,
    this.enabled = true,
  });

  @override
  State<GpxAndTcxTelemetryExporterPanel> createState() =>
      _GpxAndTcxTelemetryExporterPanelState();
}

class _GpxAndTcxTelemetryExporterPanelState
    extends State<GpxAndTcxTelemetryExporterPanel> {
  final GpxAndTcxTelemetryExporter _exporter = const GpxAndTcxTelemetryExporter();
  TelemetryExportFormat _selectedFormat = TelemetryExportFormat.tcx;
  bool _resample1Hz = true;
  bool _showXmlPreview = false;
  TelemetryExportResult? _lastResult;
  TelemetryXmlValidationReport? _validationReport;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _recomputeExport();
  }

  @override
  void didUpdateWidget(covariant GpxAndTcxTelemetryExporterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _recomputeExport();
    }
  }

  void _recomputeExport() {
    final session = widget.session;
    if (session == null || session.samples.isEmpty) {
      _lastResult = null;
      _validationReport = null;
      return;
    }
    final res = _exporter.export(
      session: session,
      format: _selectedFormat,
      resampleOneSecond: _resample1Hz,
    );
    _lastResult = res;
    _validationReport = _exporter.validateExportedXml(res.xmlContent, _selectedFormat);
  }

  void _triggerExport() {
    if (!widget.enabled || _lastResult == null) return;
    widget.onExported?.call(_lastResult!);
    setState(() {
      _statusMessage =
          'Wygenerowano ${_lastResult!.suggestedFileName} (${_lastResult!.trackpointCount} pkt)';
    });
  }

  Future<void> _copyXmlToClipboard() async {
    if (!widget.enabled || _lastResult == null) return;
    await Clipboard.setData(ClipboardData(text: _lastResult!.xmlContent));
    if (!mounted) return;
    setState(() {
      _statusMessage = 'Skopiowano XML (${_formatBytes(_lastResult!.byteSize)}) do schowka';
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasSession = widget.session != null && widget.session!.samples.isNotEmpty;
    final bool canInteract = widget.enabled && hasSession;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 600;
        final bool isWide = constraints.maxWidth >= 980;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isCompact, hasSession),
                const SizedBox(height: 16),
                if (!hasSession)
                  _buildEmptyState()
                else ...[
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _buildFormatSelector(canInteract)),
                        const SizedBox(width: 16),
                        Expanded(flex: 6, child: _buildTelemetrySummary(isCompact)),
                      ],
                    )
                  else ...[
                    _buildFormatSelector(canInteract),
                    const SizedBox(height: 14),
                    _buildTelemetrySummary(isCompact),
                  ],
                  const SizedBox(height: 16),
                  _buildActionBar(isCompact, canInteract),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 12),
                    _buildStatusBanner(),
                  ],
                  if (_showXmlPreview && _lastResult != null) ...[
                    const SizedBox(height: 14),
                    _buildXmlPreviewBox(),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact, bool hasSession) {
    final valid = _validationReport?.isValid ?? false;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.4)),
              ),
              child: const Icon(
                Icons.file_download_outlined,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EKSPORT TELEMETRII (.TCX / .GPX)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 13 : 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    hasSession
                        ? '${widget.session!.stageName} • ${widget.session!.riderName}'
                        : 'Brak ukończonego etapu do eksportu',
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
        if (hasSession)
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (valid ? AppColors.statusSuccess : AppColors.amberWarning)
                  .withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (valid ? AppColors.statusSuccess : AppColors.amberWarning)
                    .withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  valid ? Icons.verified_outlined : Icons.warning_amber_rounded,
                  size: 14,
                  color: valid ? AppColors.statusSuccess : AppColors.amberWarning,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    valid ? 'STANDARD XML ZWERYFIKOWANY' : 'WYMAGA WERYFIKACJI',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: valid ? AppColors.statusSuccess : AppColors.amberWarning,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.route_outlined, color: AppColors.textSecondary, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ukończ etap, aby wygenerować ślad GPS 1 Hz z mocą (W), tętnem (BPM), kadencją (RPM) i wysokością n.p.m.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelector(bool canInteract) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FORMAT PLIKU ANALITYCZNEGO',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          for (final fmt in TelemetryExportFormat.values) ...[
            _InteractiveFormatTile(
              format: fmt,
              selected: _selectedFormat == fmt,
              enabled: canInteract,
              onTap: () {
                setState(() {
                  _selectedFormat = fmt;
                  _statusMessage = null;
                  _recomputeExport();
                });
              },
            ),
            if (fmt != TelemetryExportFormat.values.last) const SizedBox(height: 8),
          ],
          const SizedBox(height: 10),
          _InteractiveToggleRow(
            label: 'Resampling 1 Hz (sekunda po sekundzie)',
            value: _resample1Hz,
            enabled: canInteract,
            onChanged: (val) {
              setState(() {
                _resample1Hz = val;
                _recomputeExport();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetrySummary(bool isCompact) {
    final res = _lastResult;
    if (res == null) return const SizedBox.shrink();

    final items = <({String label, String value, Color accent})>[
      (
        label: 'PUNKTY GPS',
        value: '${res.trackpointCount} s',
        accent: AppColors.accentBlue,
      ),
      (
        label: 'DYSTANS',
        value: '${(res.totalDistanceMeters / 1000.0).toStringAsFixed(2)} km',
        accent: AppColors.textPrimary,
      ),
      (
        label: 'PRZEWYŻSZENIE',
        value: '+${res.elevationGainMeters.round()} m',
        accent: AppColors.goldAccent,
      ),
      (
        label: 'ŚR. MOC / NP',
        value: '${res.averagePowerWatts.round()} / ${res.normalizedPowerWatts.round()} W',
        accent: AppColors.cyanAccent,
      ),
      (
        label: 'ŚR. TĘTNO',
        value: '${res.averageHeartRateBpm} bpm',
        accent: AppColors.crimsonAlert,
      ),
      (
        label: 'ŚR. KADENCJA',
        value: '${res.averageCadenceRpm} rpm',
        accent: AppColors.statusSuccess,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PODSUMOWANIE ŚLADU',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _formatBytes(res.byteSize),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.goldAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isCompact ? 2 : 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: isCompact ? 2.5 : 2.3,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.value,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: item.accent,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(bool isCompact, bool canInteract) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ExporterActionButton(
              label: 'Eksportuj .${_selectedFormat.fileExtension}',
              icon: Icons.save_alt_rounded,
              isPrimary: true,
              enabled: canInteract,
              onPressed: _triggerExport,
            ),
            _ExporterActionButton(
              label: 'Kopiuj XML',
              icon: Icons.copy_rounded,
              isPrimary: false,
              enabled: canInteract,
              onPressed: _copyXmlToClipboard,
            ),
          ],
        ),
        _ExporterActionButton(
          label: _showXmlPreview ? 'Ukryj podgląd XML' : 'Podgląd XML',
          icon: _showXmlPreview ? Icons.code_off_rounded : Icons.code_rounded,
          isPrimary: false,
          enabled: canInteract,
          onPressed: () {
            setState(() {
              _showXmlPreview = !_showXmlPreview;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.statusSuccess.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.statusSuccess.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: AppColors.statusSuccess),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage ?? '',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXmlPreviewBox() {
    final lines = _lastResult!.xmlContent.split('\n').take(18).join('\n');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          '$lines\n...',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: AppColors.accentBlue,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class _InteractiveFormatTile extends StatefulWidget {
  final TelemetryExportFormat format;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _InteractiveFormatTile({
    required this.format,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_InteractiveFormatTile> createState() => _InteractiveFormatTileState();
}

class _InteractiveFormatTileState extends State<_InteractiveFormatTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : widget.selected
            ? AppColors.goldAccent
            : _focused
                ? AppColors.accentBlue
                : _hovered
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : AppColors.cardBorder;

    final Color bgColor = !widget.enabled
        ? AppColors.background.withValues(alpha: 0.5)
        : widget.selected
            ? AppColors.primaryAccent.withValues(alpha: _pressed ? 0.35 : 0.22)
            : _hovered
                ? AppColors.surface
                : AppColors.background;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: MouseRegion(
          cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: widget.selected ? 1.4 : 1.0),
            ),
            child: Row(
              children: [
                Icon(
                  widget.selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 18,
                  color: !widget.enabled
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
                      : widget.selected
                          ? AppColors.goldAccent
                          : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.format.displayName,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: widget.enabled
                              ? AppColors.textPrimary
                              : AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                      ),
                      Text(
                        widget.format.subtitle,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: widget.enabled
                              ? AppColors.textSecondary
                              : AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _InteractiveToggleRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeThumbColor: AppColors.goldAccent,
          activeTrackColor: AppColors.primaryAccent.withValues(alpha: 0.6),
        ),
      ],
    );
  }
}

class _ExporterActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback onPressed;

  const _ExporterActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_ExporterActionButton> createState() => _ExporterActionButtonState();
}

class _ExporterActionButtonState extends State<_ExporterActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color baseBg = widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceLight;
    final Color effectiveBg = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _pressed
            ? baseBg.withValues(alpha: 0.75)
            : _hovered
                ? (widget.isPrimary ? AppColors.goldAccent.withValues(alpha: 0.9) : AppColors.cardBorder)
                : baseBg;

    final Color textColor = !widget.enabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : (widget.isPrimary && _hovered)
            ? AppColors.background
            : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: MouseRegion(
          cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: effectiveBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.accentBlue
                    : widget.isPrimary
                        ? AppColors.goldAccent.withValues(alpha: widget.enabled ? 0.65 : 0.2)
                        : AppColors.cardBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 16, color: textColor),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
