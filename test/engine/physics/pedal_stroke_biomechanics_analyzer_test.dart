// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/pedal_stroke_biomechanics_analyzer.dart';

void main() {
  const analyzer = PedalStrokeBiomechanicsAnalyzer();

  group('PedalStrokeBiomechanicsAnalyzer - Physics & Dual-Sided Metrics', () {
    test('produces 360 samples and matches target power within tolerance', () {
      const input = PedalStrokeAnalysisInput(
        targetPowerWatts: 360.0,
        cadenceRpm: 90.0,
      );
      final result = analyzer.analyze(input);

      expect(result.samples.length, 360);
      expect(result.samples.first.angleDeg, 0);
      expect(result.samples.last.angleDeg, 359);
      expect(result.totalPowerWatts, closeTo(360.0, 0.5));
      expect(
        result.leftPowerWatts + result.rightPowerWatts,
        closeTo(result.totalPowerWatts, 0.1),
      );
    });

    test('healthy baseline yields ~49.2% / 50.8% L/R balance and realistic TE/PS', () {
      const input = PedalStrokeAnalysisInput(
        targetPowerWatts: 320.0,
        cadenceRpm: 92.0,
      );
      final result = analyzer.analyze(input);

      expect(result.leftBalancePercent, closeTo(49.2, 0.2));
      expect(result.rightBalancePercent, closeTo(50.8, 0.2));
      expect(
        result.leftBalancePercent + result.rightBalancePercent,
        closeTo(100.0, 0.01),
      );
      expect(result.status, PedalStrokeStatus.balanced);

      // Realistic pro cycling Torque Effectiveness (65%..95%) & Pedal Smoothness (18%..40%).
      expect(result.combinedTorqueEffectivenessPercent, inInclusiveRange(65.0, 96.0));
      expect(result.combinedPedalSmoothnessPercent, inInclusiveRange(18.0, 42.0));
      expect(result.leftPeakAngleDeg, inInclusiveRange(75.0, 120.0));
      expect(result.rightPeakAngleDeg, inInclusiveRange(75.0, 120.0));
    });

    test('left knee injury deepens L/R asymmetry to ~44.0% / 56.0%', () {
      const input = PedalStrokeAnalysisInput(
        targetPowerWatts: 280.0,
        cadenceRpm: 86.0,
        kneeInjurySide: KneeInjurySide.left,
        kneeInjurySeverity: 1.0,
      );
      final result = analyzer.analyze(input);

      expect(result.leftBalancePercent, closeTo(44.0, 0.2));
      expect(result.rightBalancePercent, closeTo(56.0, 0.2));
      expect(result.status, PedalStrokeStatus.injuryCompensation);

      // Injured leg should have lower TE% than healthy compensating leg.
      expect(
        result.leftTorqueEffectivenessPercent,
        lessThan(result.rightTorqueEffectivenessPercent),
      );
    });

    test('right knee injury shifts L/R asymmetry to ~56.0% / 44.0%', () {
      const input = PedalStrokeAnalysisInput(
        targetPowerWatts: 280.0,
        cadenceRpm: 86.0,
        kneeInjurySide: KneeInjurySide.right,
        kneeInjurySeverity: 1.0,
      );
      final result = analyzer.analyze(input);

      expect(result.leftBalancePercent, closeTo(56.0, 0.2));
      expect(result.rightBalancePercent, closeTo(44.0, 0.2));
      expect(result.status, PedalStrokeStatus.injuryCompensation);
    });

    test('standing out of saddle produces sharper peak and lower smoothness than seated aero', () {
      final aeroResult = analyzer.analyze(
        const PedalStrokeAnalysisInput(
          targetPowerWatts: 400.0,
          cadenceRpm: 95.0,
          posture: PedalingPosture.seatedAero,
        ),
      );
      final standingResult = analyzer.analyze(
        const PedalStrokeAnalysisInput(
          targetPowerWatts: 400.0,
          cadenceRpm: 72.0,
          posture: PedalingPosture.standingOutOfSaddle,
        ),
      );

      expect(
        standingResult.leftPedalSmoothnessPercent,
        lessThan(aeroResult.leftPedalSmoothnessPercent),
      );
      expect(
        standingResult.leftPeakForceN,
        greaterThan(aeroResult.leftPeakForceN),
      );
    });

    test('coasting / zero power returns safe zeroed metrics without NaN', () {
      final coastResult = analyzer.analyze(
        const PedalStrokeAnalysisInput(
          targetPowerWatts: 0.0,
          cadenceRpm: 0.0,
        ),
      );

      expect(coastResult.status, PedalStrokeStatus.coasting);
      expect(coastResult.totalPowerWatts, 0.0);
      expect(coastResult.leftBalancePercent, 50.0);
      expect(coastResult.rightBalancePercent, 50.0);
      expect(coastResult.combinedTorqueEffectivenessPercent, 0.0);
      expect(coastResult.combinedPedalSmoothnessPercent, 0.0);
      expect(coastResult.samples.every((s) => !s.leftTangentialForceN.isNaN), isTrue);
    });

    test('shorter crank length increases tangential force for the same power', () {
      final shortCrank = analyzer.analyze(
        const PedalStrokeAnalysisInput(
          targetPowerWatts: 350.0,
          cadenceRpm: 90.0,
          crankLengthMm: 165.0,
        ),
      );
      final longCrank = analyzer.analyze(
        const PedalStrokeAnalysisInput(
          targetPowerWatts: 350.0,
          cadenceRpm: 90.0,
          crankLengthMm: 175.0,
        ),
      );

      expect(shortCrank.leftPeakForceN, greaterThan(longCrank.leftPeakForceN));
      expect(shortCrank.totalPowerWatts, closeTo(longCrank.totalPowerWatts, 0.5));
    });
  });

  group('PedalStrokeBiomechanicsPanel - Responsive & Interactive UI', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: PedalStrokeBiomechanicsPanel(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844 mobile without overflow', (tester) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(find.text('Biomechanika Obrotu Korby 360°'), findsOneWidget);
      expect(find.textContaining('49.2%'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1024x768 tablet without overflow', (tester) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.text('Telemetria Dual-Sided Power Meter'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1600x900 desktop and reacts to knee injury tap', (tester) async {
      await pumpAtSize(tester, const Size(1600, 900));
      expect(find.text('Parametry Symulacji'), findsOneWidget);

      await tester.tap(find.text('Lewe kolano'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('44.0%'), findsWidgets);
      expect(find.text('Kompensacja kontuzji'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
