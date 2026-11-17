// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/cobble_tire_pressure_real_time_deflection.dart';
import 'package:pro_peloton_manager/engine/physics/tire_pressure_calculator.dart';

void main() {
  group('CobbleTirePressureRealTimeDeflection physics', () {
    test('5-star cobbles yield lower optimal pressure than 1-star cobbles', () {
      const base = CobbleTireDeflectionInput(
        totalMassKg: 82.0,
        nominalTireWidthMm: 32,
        sectorRating: CobbleSectorRating.oneStar,
      );
      final opt1Star =
          CobbleTirePressureRealTimeDeflection.computeOptimalCobblePressures(
        base,
      );
      final opt5Star =
          CobbleTirePressureRealTimeDeflection.computeOptimalCobblePressures(
        base.copyWith(sectorRating: CobbleSectorRating.fiveStar),
      );

      expect(opt5Star.frontBar, lessThan(opt1Star.frontBar));
      expect(opt5Star.rearBar, lessThan(opt1Star.rearBar));
    });

    test('overpressure on 5-star cobbles causes high impedance vibration loss', () {
      const optimalInput = CobbleTireDeflectionInput(
        totalMassKg: 82.0,
        nominalTireWidthMm: 32,
        frontPressureBar: 2.95,
        rearPressureBar: 3.30,
        rimType: RimType.hooked,
        sectorRating: CobbleSectorRating.fiveStar,
        speedKmh: 40.0,
      );
      final overInput = optimalInput.copyWith(
        frontPressureBar: 6.50,
        rearPressureBar: 6.80,
      );

      final optSnap =
          CobbleTirePressureRealTimeDeflection.evaluateStep(optimalInput);
      final overSnap =
          CobbleTirePressureRealTimeDeflection.evaluateStep(overInput);

      expect(overSnap.impedanceLossWatts,
          greaterThan(optSnap.impedanceLossWatts + 12.0));
      expect(overSnap.rmsVerticalAccelerationG,
          greaterThan(optSnap.rmsVerticalAccelerationG));
      expect(overSnap.verdict, CobbleDeflectionVerdict.tooStiffHighImpedance);
      expect(overSnap.potentialSavingsWatts, greaterThan(10.0));
    });

    test('underpressure on narrow 25mm tire triggers rim strike risk and insert mitigates it', () {
      const lowInput = CobbleTireDeflectionInput(
        totalMassKg: 85.0,
        nominalTireWidthMm: 25,
        frontPressureBar: 2.00,
        rearPressureBar: 2.10,
        rimType: RimType.hooked,
        sectorRating: CobbleSectorRating.fiveStar,
        speedKmh: 42.0,
        hasTireInsert: false,
      );

      final noInsertSnap =
          CobbleTirePressureRealTimeDeflection.evaluateStep(lowInput);
      final withInsertSnap = CobbleTirePressureRealTimeDeflection.evaluateStep(
        lowInput.copyWith(hasTireInsert: true),
      );

      expect(noInsertSnap.verdict, CobbleDeflectionVerdict.imminentRimStrike);
      expect(withInsertSnap.rearWheel.rimBottomOutMarginMm,
          greaterThan(noInsertSnap.rearWheel.rimBottomOutMarginMm));
      expect(withInsertSnap.rimStrikeProbabilityPercent,
          lessThan(noInsertSnap.rimStrikeProbabilityPercent));
    });

    test('hookless rim above 5.0 BAR triggers hooklessOverpressure verdict', () {
      const hooklessHigh = CobbleTireDeflectionInput(
        frontPressureBar: 5.30,
        rearPressureBar: 5.50,
        rimType: RimType.hookless,
        sectorRating: CobbleSectorRating.fiveStar,
      );

      final snap =
          CobbleTirePressureRealTimeDeflection.evaluateStep(hooklessHigh);
      expect(snap.verdict, CobbleDeflectionVerdict.hooklessOverpressure);
    });

    test('sweepPressureCurve and simulateSectorTraversal return valid telemetry', () {
      const input = CobbleTireDeflectionInput(
        sectorRating: CobbleSectorRating.fiveStar,
        speedKmh: 38.0,
      );
      final sweep =
          CobbleTirePressureRealTimeDeflection.sweepPressureCurve(input);
      expect(sweep.length, greaterThan(10));

      final summary =
          CobbleTirePressureRealTimeDeflection.simulateSectorTraversal(
        input,
        sectorLengthKm: 2.4,
        dtSec: 2.0,
      );
      expect(summary.samples, isNotEmpty);
      expect(summary.totalEnergyLostKj, greaterThan(0.0));
      expect(summary.averageVibrationWatts, greaterThan(0.0));
    });
  });

  group('CobbleTirePressureDeflectionPanel UI', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CobbleTirePressureDeflectionPanel(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders without overflow on 390x844 mobile', (tester) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(find.text('Cobble Tire Deflection & Vibration Lab'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on 1024x768 tablet', (tester) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.text('Auto-Optimum'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on 1600x900 desktop and handles interactions', (tester) async {
      await pumpAtSize(tester, const Size(1600, 900));
      expect(find.text('Auto-Optimum'), findsOneWidget);

      await tester.tap(find.text('3★'));
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Auto-Optimum'));
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Foam Insert: WYŁ'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Foam Insert: WŁ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
