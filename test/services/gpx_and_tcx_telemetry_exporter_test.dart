import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_replay_recorder.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/services/export/gpx_and_tcx_telemetry_exporter.dart';

TelemetryExportSession _buildSampleSession({
  String stageName = 'Etap 14: Alpe d\'Huez & Galibier',
  String riderName = 'Tadej & Jonas <Pro>',
  int seconds = 40,
}) {
  final samples = <TelemetryExportSample>[];
  double lat = 45.0558;
  double lon = 6.0289;
  double dist = 0.0;
  double ele = 720.0;

  for (int s = 0; s < seconds; s++) {
    final double speed = 8.5 + (s % 5) * 0.2;
    dist += speed;
    ele += 0.45;
    lat += 0.00006;
    lon += 0.00004;
    samples.add(
      TelemetryExportSample(
        elapsedSeconds: s.toDouble(),
        latitude: lat,
        longitude: lon,
        elevationMeters: ele,
        distanceMeters: dist,
        speedMs: speed,
        powerWatts: 340 + (s % 7) * 15,
        heartRateBpm: 162 + (s % 6),
        cadenceRpm: 88 + (s % 4),
        temperatureCelsius: 19.5,
      ),
    );
  }

  return TelemetryExportSession(
    stageId: 'stage_14_alpe',
    stageName: stageName,
    riderName: riderName,
    teamName: 'Team Apex Pro',
    riderWeightKg: 66.5,
    startTimeUtc: DateTime.utc(2026, 7, 18, 12, 0, 0),
    samples: samples,
  );
}

void main() {
  const exporter = GpxAndTcxTelemetryExporter();

  group('GpxAndTcxTelemetryExporter — TCX & GPX generation', () {
    test('generuje poprawny standard Garmin TCX v2 sekunda po sekundzie z mocą, tętnem i kadencją', () {
      final session = _buildSampleSession(seconds: 35);
      final result = exporter.export(
        session: session,
        format: TelemetryExportFormat.tcx,
      );

      expect(result.format, TelemetryExportFormat.tcx);
      expect(result.trackpointCount, 35);
      expect(result.suggestedFileName, endsWith('.tcx'));
      expect(result.xmlContent, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(result.xmlContent, contains('xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"'));
      expect(result.xmlContent, contains('xmlns:ns3="http://www.garmin.com/xmlschemas/ActivityExtension/v2"'));
      expect(result.xmlContent, contains('<Activity Sport="Biking">'));
      expect(result.xmlContent, contains('<ns3:Watts>'));
      expect(result.xmlContent, contains('<HeartRateBpm>'));
      expect(result.xmlContent, contains('<Cadence>'));
      expect(result.xmlContent, contains('<AltitudeMeters>'));
      // Weryfikacja escapowania znaków XML (&, <, >)
      expect(result.xmlContent, contains('Tadej &amp; Jonas &lt;Pro&gt;'));
      expect(result.normalizedPowerWatts, greaterThan(300.0));

      final validation = exporter.validateExportedXml(
        result.xmlContent,
        TelemetryExportFormat.tcx,
      );
      expect(validation.isValid, isTrue, reason: validation.errors.join(', '));
      expect(validation.detectedTrackpoints, 35);
      expect(validation.hasPowerData, isTrue);
      expect(validation.hasHeartRateData, isTrue);
      expect(validation.hasCadenceData, isTrue);
      expect(validation.hasElevationData, isTrue);
      expect(validation.hasMonotonicTimestamps, isTrue);
    });

    test('generuje poprawny standard GPX 1.1 z Garmin TrackPointExtension v1', () {
      final session = _buildSampleSession(seconds: 25);
      final result = exporter.export(
        session: session,
        format: TelemetryExportFormat.gpx,
      );

      expect(result.format, TelemetryExportFormat.gpx);
      expect(result.trackpointCount, 25);
      expect(result.suggestedFileName, endsWith('.gpx'));
      expect(result.xmlContent, contains('<gpx version="1.1"'));
      expect(result.xmlContent, contains('xmlns="http://www.topografix.com/GPX/1/1"'));
      expect(result.xmlContent, contains('xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1"'));
      expect(result.xmlContent, contains('<trkpt lat="'));
      expect(result.xmlContent, contains('<power>'));
      expect(result.xmlContent, contains('<gpxtpx:hr>'));
      expect(result.xmlContent, contains('<gpxtpx:cad>'));
      expect(result.xmlContent, contains('<gpxtpx:atemp>19.5</gpxtpx:atemp>'));

      final validation = exporter.validateExportedXml(
        result.xmlContent,
        TelemetryExportFormat.gpx,
      );
      expect(validation.isValid, isTrue, reason: validation.errors.join(', '));
      expect(validation.detectedTrackpoints, 25);
      expect(validation.hasMonotonicTimestamps, isTrue);
    });

    test('resampling 1 Hz interpoluje nieregularne znaczniki czasu do siatki co 1 sekundę', () {
      final raw = [
        const TelemetryExportSample(
          elapsedSeconds: 0.0,
          latitude: 45.0,
          longitude: 6.0,
          elevationMeters: 1000.0,
          distanceMeters: 0.0,
          speedMs: 10.0,
          powerWatts: 300,
          heartRateBpm: 150,
          cadenceRpm: 80,
        ),
        const TelemetryExportSample(
          elapsedSeconds: 4.0,
          latitude: 45.0004,
          longitude: 6.0004,
          elevationMeters: 1004.0,
          distanceMeters: 40.0,
          speedMs: 14.0,
          powerWatts: 380,
          heartRateBpm: 170,
          cadenceRpm: 96,
        ),
      ];

      final resampled = exporter.resampleToOneSecond(raw);
      expect(resampled.length, 5); // 0, 1, 2, 3, 4 s
      expect(resampled[2].elapsedSeconds, 2.0);
      expect(resampled[2].elevationMeters, closeTo(1002.0, 0.01));
      expect(resampled[2].distanceMeters, closeTo(20.0, 0.01));
      expect(resampled[2].powerWatts, 340);
      expect(resampled[2].heartRateBpm, 160);
      expect(resampled[2].cadenceRpm, 88);
    });

    test('fromStageReplayTrackPoints rzutuje trasę RaceStage na współrzędne GPS WGS84', () {
      const stage = RaceStage(
        id: 'st_alpe',
        stageNumber: 14,
        name: 'Alpe d\'Huez',
        stageType: StageType.summitFinish,
        segments: [
          StageSegment(
            index: 0,
            startKm: 0.0,
            lengthKm: 14.0,
            startElevationM: 720.0,
            endElevationM: 1850.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 45.0,
            windDirectionDegrees: 180.0,
            roadBearingDegrees: 45.0,
            sprintOrKomClassification: SegmentClassification.horsCategorie,
          ),
        ],
        baseTemperatureCelsius: 22.0,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 10.0,
      );

      final trackPoints = List.generate(
        10,
        (i) => RiderTelemetryTrackPoint(
          timestampSeconds: i.toDouble(),
          distanceMeters: i * 6.5,
          speedMs: 6.5,
          powerWatts: 390,
          cadenceRpm: 84,
          heartRateBpm: 174,
          elevationMeters: 720.0 + i * 0.5,
          gradientPercent: 8.1,
          wPrimeJoules: 18000.0,
          wPrimePercentage: 0.9,
          glycogenGrams: 420.0,
          lateralPositionRoad: 0.0,
          isDrafting: false,
          draftingSavingsPercent: 0.0,
          activeTacticalOrder: TacticalOrder.pullGroup,
        ),
      );

      final session = GpxAndTcxTelemetryExporter.fromStageReplayTrackPoints(
        stage: stage,
        riderName: 'Jan Kowalski',
        teamName: 'Polonia Racing',
        riderWeightKg: 64.0,
        trackPoints: trackPoints,
        originPreset: GpsOriginPreset.alpeDHuez,
      );

      expect(session.samples.length, 10);
      expect(session.samples.first.latitude, closeTo(GpsOriginPreset.alpeDHuez.latitude, 1e-4));
      expect(session.samples.last.latitude, greaterThan(session.samples.first.latitude));
      expect(session.samples.last.longitude, greaterThan(session.samples.first.longitude));
    });

    test('exportToFile zapisuje plik .tcx na dysku oraz rzuca wyjątek dla pustej sesji', () async {
      final tempDir = await Directory.systemTemp.createTemp('ppm_export_test_');
      try {
        final session = _buildSampleSession(seconds: 10);
        final file = await exporter.exportToFile(
          session: session,
          format: TelemetryExportFormat.tcx,
          targetDirectory: tempDir,
        );

        expect(await file.exists(), isTrue);
        final contents = await file.readAsString();
        expect(contents, contains('<TrainingCenterDatabase'));
        expect(exporter.validateExportedXml(contents, TelemetryExportFormat.tcx).isValid, isTrue);

        final emptySession = TelemetryExportSession(
          stageId: 'empty',
          stageName: 'Empty',
          riderName: 'Rider',
          teamName: 'Team',
          riderWeightKg: 70,
          startTimeUtc: DateTime.utc(2026, 7, 1),
          samples: const [],
        );
        expect(
          () => exporter.export(session: emptySession, format: TelemetryExportFormat.gpx),
          throwsArgumentError,
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });

  group('GpxAndTcxTelemetryExporterPanel — Responsywność i stany UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renderuje się bez przepełnień przy ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        TelemetryExportResult? exported;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xFF0F1115),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: GpxAndTcxTelemetryExporterPanel(
                  session: _buildSampleSession(seconds: 20),
                  onExported: (res) => exported = res,
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('EKSPORT TELEMETRII (.TCX / .GPX)'), findsOneWidget);
        expect(find.text('STANDARD XML ZWERYFIKOWANY'), findsOneWidget);

        // Przełączenie na GPX i eksport
        await tester.tap(find.text('GPX 1.1 + Extensions (.gpx)'));
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.text('Eksportuj .gpx'));
        await tester.pump(const Duration(milliseconds: 250));

        expect(exported, isNotNull);
        expect(exported!.format, TelemetryExportFormat.gpx);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('obsługuje stan pusty oraz stan wyłączony (disabled)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GpxAndTcxTelemetryExporterPanel(
              session: null,
              enabled: false,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.textContaining('Ukończ etap, aby wygenerować ślad GPS 1 Hz'),
        findsOneWidget,
      );
    });
  });
}
