// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/wheel_and_drivetrain_rotator.dart';

void main() {
  group('WheelAndDrivetrainRotator', () {
    test('obraca koła zgodnie z prędkością v/R i generuje kąty szprych', () {
      final WheelAndDrivetrainRotator rotator = WheelAndDrivetrainRotator(
        config: const DrivetrainConfig(
          wheelRadiusMeters: 0.34,
          spokeCount: 16,
        ),
      );

      final WheelAndDrivetrainFrameState state = rotator.update(
        riderId: 'r1',
        dtSeconds: 0.05,
        speedMs: 10.0, // 36 km/h
        cadenceRpm: 90,
      );

      expect(state.wheelAngularVelocity, closeTo(10.0 / 0.34, 1e-6));
      expect(state.wheelAngleRadians, closeTo((10.0 / 0.34) * 0.05, 1e-6));
      expect(state.spokeAnglesRadians.length, 16);
      expect(state.motionBlur.isActive, isFalse);
      expect(state.motionBlur.intensity, 0.0);
      expect(state.motionBlur.sharpSpokeOpacity, 1.0);
    });

    test('aktywuje motion blur szprych wyłącznie powyżej 40 km/h', () {
      final WheelAndDrivetrainRotator rotator = WheelAndDrivetrainRotator();

      // Dokładnie 40 km/h -> brak motion blur
      final WheelAndDrivetrainFrameState at40 = rotator.update(
        riderId: 'r40',
        dtSeconds: 0.016,
        speedMs: 40.0 / 3.6,
        cadenceRpm: 95,
      );
      expect(at40.motionBlur.isActive, isFalse);

      // 55 km/h -> umiarkowany motion blur
      final WheelAndDrivetrainFrameState at55 = rotator.update(
        riderId: 'r55',
        dtSeconds: 0.016,
        speedMs: 55.0 / 3.6,
        cadenceRpm: 105,
      );
      expect(at55.motionBlur.isActive, isTrue);
      expect(at55.motionBlur.intensity, greaterThan(0.3));
      expect(at55.motionBlur.sharpSpokeOpacity, lessThan(1.0));
      expect(at55.motionBlur.trailSweepRadians, greaterThan(0.0));

      // 80 km/h (zjazd) -> mocniejszy motion blur niż przy 55 km/h
      final WheelAndDrivetrainFrameState at80 = rotator.update(
        riderId: 'r80',
        dtSeconds: 0.016,
        speedMs: 80.0 / 3.6,
        cadenceRpm: 0,
      );
      expect(at80.motionBlur.isActive, isTrue);
      expect(
        at80.motionBlur.intensity,
        greaterThan(at55.motionBlur.intensity),
      );
      expect(at80.isCoasting, isTrue);
    });

    test('obraca tarczę korby dokładnie zgodnie z kadencją RPM i zatrzymuje na luzie', () {
      final WheelAndDrivetrainRotator rotator = WheelAndDrivetrainRotator();

      // 60 RPM = 1 obrót/s = 2π rad/s. Po 0.25 s powinno być π/2 rad.
      final WheelAndDrivetrainFrameState s1 = rotator.update(
        riderId: 'crank_test',
        dtSeconds: 0.05,
        speedMs: 11.0,
        cadenceRpm: 60,
      );
      expect(s1.crankAngularVelocity, closeTo(2.0 * math.pi, 1e-6));
      expect(s1.crankAngleRadians, closeTo(2.0 * math.pi * 0.05, 1e-6));
      expect(
        s1.leftCrankAngleRadians,
        closeTo((s1.crankAngleRadians + math.pi) % (2.0 * math.pi), 1e-6),
      );

      // Zjazd na luzie (0 RPM): korba i kaseta zatrzymują się, koło nadal się kręci.
      final double prevCrank = s1.crankAngleRadians;
      final double prevWheel = s1.wheelAngleRadians;
      final WheelAndDrivetrainFrameState s2 = rotator.update(
        riderId: 'crank_test',
        dtSeconds: 0.05,
        speedMs: 16.0,
        cadenceRpm: 0,
      );
      expect(s2.crankAngleRadians, closeTo(prevCrank, 1e-9));
      expect(s2.wheelAngleRadians, isNot(closeTo(prevWheel, 1e-4)));
    });

    test('wychyla wózek tylnej przerzutki zależnie od wybranego przełożenia', () {
      final WheelAndDrivetrainRotator rotator = WheelAndDrivetrainRotator();
      const DrivetrainGearSelection lightSprint = DrivetrainGearSelection(
        frontChainringIndex: 0, // 40T
        rearCogIndex: 0, // 11T
        frontTeeth: 40,
        rearTeeth: 11,
      );
      const DrivetrainGearSelection heavyDemand = DrivetrainGearSelection(
        frontChainringIndex: 1, // 54T
        rearCogIndex: 11, // 34T
        frontTeeth: 54,
        rearTeeth: 34,
      );

      late WheelAndDrivetrainFrameState minState;
      for (int i = 0; i < 30; i++) {
        minState = rotator.update(
          riderId: 'der_min',
          dtSeconds: 0.05,
          speedMs: 8.0,
          cadenceRpm: 85,
          manualGear: lightSprint,
        );
      }

      late WheelAndDrivetrainFrameState maxState;
      for (int i = 0; i < 30; i++) {
        maxState = rotator.update(
          riderId: 'der_max',
          dtSeconds: 0.05,
          speedMs: 8.0,
          cadenceRpm: 85,
          manualGear: heavyDemand,
        );
      }

      expect(
        maxState.derailleur.cageSwingAngleDegrees,
        greaterThan(minState.derailleur.cageSwingAngleDegrees + 40.0),
      );
      expect(maxState.derailleur.lateralCassetteProgress, closeTo(1.0, 0.01));
      expect(minState.derailleur.lateralCassetteProgress, closeTo(0.0, 0.01));
      expect(
        maxState.derailleur.lateralOffsetMeters,
        greaterThan(minState.derailleur.lateralOffsetMeters),
      );
    });

    test('renderuje koło z motion blur i napęd na Canvas bez błędów', () {
      final WheelAndDrivetrainRotator rotator = WheelAndDrivetrainRotator();
      final WheelAndDrivetrainFrameState state = rotator.update(
        riderId: 'canvas_test',
        dtSeconds: 0.016,
        speedMs: 16.5, // ~59.4 km/h (>40 km/h)
        cadenceRpm: 102,
      );

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      WheelAndDrivetrainRotator.paintWheelWithMotionBlur(
        canvas: canvas,
        center: const Offset(120, 180),
        outerRadiusPx: 90,
        rimInnerRadiusPx: 72,
        state: state,
      );
      WheelAndDrivetrainRotator.paintDrivetrain(
        canvas: canvas,
        rearAxleCenter: const Offset(120, 180),
        bottomBracketCenter: const Offset(265, 195),
        pixelsPerMeter: 350.0,
        state: state,
        config: rotator.config,
      );

      final ui.Picture picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });
}
