// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';
import 'package:pro_peloton_manager/ui/widgets/polar_pedal_force_diagram_painter.dart';

void main() {
  group('PolarPedalForceDiagramCalculator', () {
    test('Góral ma wyższą płynność (PS%) i mniejszy spadek w martwych punktach niż Sprinter', () {
      final climber = PolarPedalForceDiagramCalculator.analyzeClimberSmoothSpin(
        powerWatts: 385,
        cadenceRpm: 94,
      );
      final sprinter = PolarPedalForceDiagramCalculator.analyzeSprinterPowerMash(
        powerWatts: 980,
        cadenceRpm: 96,
      );

      final climberMetrics =
          PolarPedalForceDiagramCalculator.computeMetrics(climber);
      final sprinterMetrics =
          PolarPedalForceDiagramCalculator.computeMetrics(sprinter);

      expect(
        climberMetrics.pedalSmoothnessPercent,
        greaterThan(sprinterMetrics.pedalSmoothnessPercent),
      );
      expect(
        climberMetrics.torqueEffectivenessPercent,
        greaterThan(sprinterMetrics.torqueEffectivenessPercent),
      );
      expect(
        climberMetrics.deadToPeakRatioPercent,
        greaterThan(sprinterMetrics.deadToPeakRatioPercent),
      );
      expect(
        sprinterMetrics.peakCombinedForceN,
        greaterThan(climberMetrics.peakCombinedForceN),
      );
    });

    test('analyzeForRider obsługuje wygenerowanego kolarza oraz null', () {
      final rider = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.pureClimber,
        targetOverallRating: 86,
      );

      final withRider =
          PolarPedalForceDiagramCalculator.analyzeForRider(rider: rider);
      final withoutRider =
          PolarPedalForceDiagramCalculator.analyzeForRider(rider: null);

      expect(withRider.samples.length, 360);
      expect(withoutRider.samples.length, 360);
      expect(withRider.totalPowerWatts, greaterThan(0));
      expect(withoutRider.totalPowerWatts, greaterThan(0));
    });
  });

  group('PolarPedalForceDiagramWidget UI & Responsywność', () {
    Widget buildTestHost({
      required Size viewportSize,
      Rider? rider,
      bool isDisabled = false,
      bool autoAnimate = true,
    }) {
      return MediaQuery(
        data: MediaQueryData(size: viewportSize),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: PolarPedalForceDiagramWidget(
                  rider: rider,
                  isDisabled: isDisabled,
                  autoAnimate: autoAnimate,
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (final Size size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez błędów przepełnienia w rozdzielczości ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final rider = RiderProceduralGenerator.generateRider(
            specialization: RiderSpecialization.gcClimber,
            targetOverallRating: 88,
          );

          await tester.pumpWidget(
            buildTestHost(viewportSize: size, rider: rider, autoAnimate: true),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(
            find.text('WYKRES KOŁOWY SIŁY NA PEDAŁY (PEANUT DIAGRAM 0°–360°)'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('obsługuje przełączanie trybów, warstw, pauzę oraz stan disabled',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestHost(viewportSize: const Size(1280, 900), autoAnimate: true),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Przełączenie na Sprinter: Siłowe Depnięcie
      await tester.tap(find.text('Sprinter: Siłowe Depnięcie'));
      await tester.pump(const Duration(milliseconds: 300));

      // Pauza animacji korby
      await tester.tap(find.text('Pauza'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Start'), findsOneWidget);

      // Wyłączenie i włączenie martwych punktów
      await tester.tap(find.text('Martwe punkty 0°/180°'));
      await tester.pump(const Duration(milliseconds: 300));

      // Stan disabled
      await tester.pumpWidget(
        buildTestHost(
          viewportSize: const Size(1280, 900),
          isDisabled: true,
          autoAnimate: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });
}
