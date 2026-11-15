// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/photo_finish_replay_widget.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_results_calculator.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhotoFinish - Enums and Data Models', () {
    test('PhotoFinishStatus properties and labels', () {
      expect(PhotoFinishStatus.underReview.label, contains('ANALIZA FOTOKOMÓRKI'));
      expect(PhotoFinishStatus.officialConfirmed.label, contains('OFICJALNY WERDYKT'));
      expect(PhotoFinishStatus.protestFiled.label, contains('PROTEST'));
    });

    test('PhotoFinishSensorMode properties and icons', () {
      expect(PhotoFinishSensorMode.trueColorSlitScan.label, contains('Kolor CCD'));
      expect(PhotoFinishSensorMode.monochromeInfrared.label, contains('Podczerwień IR'));
      expect(PhotoFinishSensorMode.edgeContour.label, contains('Kontur Krawędzi'));
    });

    test('PhotoFinishRider gap and millimeter calculations', () {
      const rider1 = PhotoFinishRider(
        rank: 1,
        riderId: 'pogacar',
        riderName: 'Tadej Pogačar',
        teamName: 'UAE',
        bibNumber: 1,
        countryIso: 'SLO',
        finishTimeSeconds: 14200.000,
        gapToWinnerSeconds: 0.0,
        speedKmh: 68.0,
        primaryJerseyColor: Colors.white,
        secondaryJerseyColor: Colors.red,
        bikeColor: Colors.black,
      );

      const rider2 = PhotoFinishRider(
        rank: 2,
        riderId: 'vingegaard',
        riderName: 'Jonas Vingegaard',
        teamName: 'Visma',
        bibNumber: 11,
        countryIso: 'DEN',
        finishTimeSeconds: 14200.004,
        gapToWinnerSeconds: 0.004,
        speedKmh: 68.0,
        primaryJerseyColor: Colors.yellow,
        secondaryJerseyColor: Colors.black,
        bikeColor: Colors.orange,
      );

      // Zwycięzca
      expect(rider1.gapMilliseconds, 0.0);
      expect(rider1.gapMillimeters, 0.0);
      expect(rider1.formattedGapSeconds, contains('0.000s'));
      expect(rider1.formattedGapDistance, '0 mm');

      // Drugie miejsce: przy 68 km/h (18.888 m/s), 0.004s = ~75.55 mm
      expect(rider2.gapMilliseconds, closeTo(4.0, 0.001));
      expect(rider2.gapMillimeters, closeTo(75.55, 0.5));
      expect(rider2.formattedGapSeconds, '+0.004s');
      expect(rider2.formattedGapDistance, contains('76 mm'));
    });

    test('PhotoFinishRider copyWith works correctly', () {
      const rider = PhotoFinishRider(
        rank: 2,
        riderId: 'van_aert',
        riderName: 'Wout van Aert',
        teamName: 'Visma',
        bibNumber: 12,
        countryIso: 'BEL',
        finishTimeSeconds: 14200.012,
        gapToWinnerSeconds: 0.012,
        speedKmh: 67.5,
        primaryJerseyColor: Colors.yellow,
        secondaryJerseyColor: Colors.black,
        bikeColor: Colors.yellow,
      );

      final updated = rider.copyWith(
        rank: 1,
        gapToWinnerSeconds: 0.0,
      );

      expect(updated.rank, 1);
      expect(updated.gapToWinnerSeconds, 0.0);
      expect(updated.riderName, 'Wout van Aert');
    });
  });

  group('PhotoFinishData - Activation Rule & Factories', () {
    test('isPhotoFinishRequired activates only for gaps under 0.15s (150 ms)', () {
      // Zacięte finisze kwalifikujące się do fotokomórki (< 0.15s)
      expect(PhotoFinishData.isPhotoFinishRequired(0.000), isTrue);
      expect(PhotoFinishData.isPhotoFinishRequired(0.003), isTrue);
      expect(PhotoFinishData.isPhotoFinishRequired(0.050), isTrue);
      expect(PhotoFinishData.isPhotoFinishRequired(0.149), isTrue);

      // Finisze z wyraźną przewagą (>= 0.15s) – brak potrzeby Photo Finish
      expect(PhotoFinishData.isPhotoFinishRequired(0.150), isFalse);
      expect(PhotoFinishData.isPhotoFinishRequired(0.200), isFalse);
      expect(PhotoFinishData.isPhotoFinishRequired(1.500), isFalse);
      expect(PhotoFinishData.isPhotoFinishRequired(-0.01), isFalse);
    });

    test('demoSprintFinish creates realistic 4ms finish between Pogacar and Vingegaard', () {
      final demo = PhotoFinishData.demoSprintFinish();

      expect(demo.riders.length, 2);
      expect(demo.winner.riderName, 'Tadej Pogačar');
      expect(demo.secondPlace.riderName, 'Jonas Vingegaard');
      expect(demo.gapSecondsToSecondPlace, 0.004);
      expect(demo.gapMillimetersToSecondPlace, closeTo(75.3, 1.0));
      expect(demo.status, PhotoFinishStatus.officialConfirmed);
      expect(demo.cameraSamplingRateHz, 10000);
    });

    test('fromStageResults converts OfficialRiderStageResult into PhotoFinishData', () {
      const stage = RaceStage(
        id: 'stage_test',
        stageNumber: 7,
        name: 'Sprint Stage',
        stageType: StageType.flat,
        segments: [
          StageSegment(
            index: 0,
            startKm: 0.0,
            lengthKm: 180.0,
            startElevationM: 50.0,
            endElevationM: 50.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 10.0,
            windDirectionDegrees: 0.0,
            roadBearingDegrees: 0.0,
            sprintOrKomClassification: SegmentClassification.none,
          ),
        ],
        baseTemperatureCelsius: 22.0,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 10.0,
      );

      final results = [
        const OfficialRiderStageResult(
          riderId: 'rider_1',
          riderName: 'Jasper Philipsen',
          teamId: 'alpecin',
          rank: 1,
          rawFinishTimeSeconds: 15400.125,
          officialFinishTimeSeconds: 15400.0,
          gapToWinnerSeconds: 0.0,
        ),
        const OfficialRiderStageResult(
          riderId: 'rider_2',
          riderName: 'Mark Cavendish',
          teamId: 'astana',
          rank: 2,
          rawFinishTimeSeconds: 15400.133,
          officialFinishTimeSeconds: 15400.0,
          gapToWinnerSeconds: 0.008,
        ),
      ];

      final photoData = PhotoFinishData.fromStageResults(stage: stage, results: results);

      expect(photoData.riders.length, 2);
      expect(photoData.winner.riderName, 'Jasper Philipsen');
      expect(photoData.secondPlace.riderName, 'Mark Cavendish');
      expect(photoData.gapSecondsToSecondPlace, closeTo(0.008, 0.0001));
    });
  });

  group('PhotoFinishDisplayConfig', () {
    test('default configuration and copyWith', () {
      const config = PhotoFinishDisplayConfig();

      expect(config.showRedMeasurementLine, isTrue);
      expect(config.showSecondMeasurementLine, isTrue);
      expect(config.showMillimeterVernier, isTrue);
      expect(config.showMagnifierLoupe, isTrue);
      expect(config.magnifierZoom, 3.5);
      expect(config.sensorMode, PhotoFinishSensorMode.trueColorSlitScan);

      final updated = config.copyWith(
        showMagnifierLoupe: false,
        sensorMode: PhotoFinishSensorMode.monochromeInfrared,
        magnifierZoom: 5.0,
      );

      expect(updated.showMagnifierLoupe, isFalse);
      expect(updated.sensorMode, PhotoFinishSensorMode.monochromeInfrared);
      expect(updated.magnifierZoom, 5.0);
    });
  });

  group('PhotoFinishSlitScanPainter - Canvas Drawing', () {
    test('renders complete slit-scan scene without errors', () {
      final data = PhotoFinishData.demoSprintFinish();
      const config = PhotoFinishDisplayConfig();
      final painter = PhotoFinishSlitScanPainter(data: data, config: config);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(960, 540);

      painter.paint(canvas, size);
      final picture = recorder.endRecording();

      expect(picture, isNotNull);
    });

    test('renders in monochrome infrared and edge contour modes', () {
      final data = PhotoFinishData.demoSprintFinish();

      for (final mode in PhotoFinishSensorMode.values) {
        final config = PhotoFinishDisplayConfig(sensorMode: mode);
        final painter = PhotoFinishSlitScanPainter(data: data, config: config);

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(960, 540);

        painter.paint(canvas, size);
        final picture = recorder.endRecording();
        expect(picture, isNotNull);
      }
    });

    test('gracefully ignores zero size', () {
      final data = PhotoFinishData.demoSprintFinish();
      const config = PhotoFinishDisplayConfig();
      final painter = PhotoFinishSlitScanPainter(data: data, config: config);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size.zero;

      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('PhotoFinishReplayWidget - Interactive UI Tests', () {
    testWidgets('mounts replay widget and displays official UCI Photo Finish header and cards', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final demoData = PhotoFinishData.demoSprintFinish();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1080,
              height: 640,
              child: PhotoFinishReplayWidget(
                data: demoData,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 32));

      // Sprawdzenie nagłówków i etykiet
      expect(find.text('PHOTO FINISH REPLAY'), findsOneWidget);
      expect(find.text('LINE-SCAN 10kHz'), findsOneWidget);
      expect(find.text('OFICJALNY WERDYKT SĘDZIÓW UCI'), findsOneWidget);
      expect(find.textContaining('Tadej Pogačar'), findsOneWidget);
      expect(find.textContaining('Jonas Vingegaard'), findsOneWidget);
      expect(find.textContaining('ZATWIERDŹ WYNIK I PODIUM'), findsOneWidget);
    });

    testWidgets('toggles sensor modes and inspection chips on tap', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final demoData = PhotoFinishData.demoSprintFinish();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1080,
              height: 640,
              child: PhotoFinishReplayWidget(
                data: demoData,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 32));

      // Przełączenie trybu sensora na "Podczerwień IR"
      final irSensorButton = find.text('Podczerwień');
      expect(irSensorButton, findsOneWidget);
      await tester.tap(irSensorButton);
      await tester.pump(const Duration(milliseconds: 32));

      // Przełączenie lupy optycznej
      final loupeButton = find.text('LUPA 3.5x');
      expect(loupeButton, findsOneWidget);
      await tester.tap(loupeButton);
      await tester.pump(const Duration(milliseconds: 32));

      // Przełączenie siatki milimetrowej
      final gridButton = find.text('SIATKA MM');
      expect(gridButton, findsOneWidget);
      await tester.tap(gridButton);
      await tester.pump(const Duration(milliseconds: 32));

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('calls onConfirmResult callback when button is clicked', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool confirmed = false;
      final demoData = PhotoFinishData.demoSprintFinish();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1080,
              height: 640,
              child: PhotoFinishReplayWidget(
                data: demoData,
                onConfirmResult: () => confirmed = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 32));

      final confirmBtn = find.text('ZATWIERDŹ WYNIK I PODIUM');
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      await tester.pump(const Duration(milliseconds: 32));

      expect(confirmed, isTrue);
    });

    testWidgets('showPhotoFinishReplayDialog opens dialog modal correctly', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final demoData = PhotoFinishData.demoSprintFinish();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showPhotoFinishReplayDialog(context, data: demoData),
                child: const Text('OPEN PHOTO FINISH'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN PHOTO FINISH'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PHOTO FINISH REPLAY'), findsOneWidget);

      // Zamknięcie dialogu
      await tester.tap(find.text('ZATWIERDŹ WYNIK I PODIUM'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PHOTO FINISH REPLAY'), findsNothing);
    });
  });
}
