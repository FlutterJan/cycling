// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/engine/rendering3d/cyclist_3d_pose_animator.dart';

void main() {
  group('Cyclist3DPoseAnimator - Crank Angle & Pedal Cadence', () {
    test('obrót korby jest całkowany w czasie na podstawie zadanej kadencji', () {
      final animator = Cyclist3DPoseAnimator(initialCrankAngle: 0.0);

      // Przy 60 RPM korba obraca się o 1 pełny obrót (2π rad) w ciągu 1 sekundy
      const dt = 0.02; // 50 klatek na sekundę
      AnimatedCyclistPose3D? lastPose;

      for (int i = 0; i < 50; i++) {
        lastPose = animator.update(
          dt,
          const CyclistTelemetryInput(
            riderId: 'rider_1',
            speedMs: 11.0,
            powerWatts: 300,
            cadenceRpm: 60,
          ),
        );
      }

      expect(lastPose, isNotNull);
      // Po 1 sekundzie przy 60 RPM obrót powinien wynieść ~2π rad (lub 0 z modulo)
      expect(lastPose!.crankAngularVelocity, closeTo(2.0 * math.pi, 1e-3));
      expect(lastPose.crankAngleRadians, closeTo(0.0, 0.15));

      // Lewy i prawy pedał są przesunięte dokładnie o π rad (180 stopni)
      final diff = (lastPose.leftCrankAngleRadians - lastPose.crankAngleRadians).abs();
      expect(diff, closeTo(math.pi, 1e-4));
    });

    test('pozycja pedałów w przestrzeni 3D obraca się po okręgu o promieniu korby', () {
      final animator = Cyclist3DPoseAnimator(initialCrankAngle: 0.0);

      final pose = animator.update(
        0.016,
        const CyclistTelemetryInput(
          riderId: 'rider_1',
          speedMs: 10.0,
          powerWatts: 250,
          cadenceRpm: 90,
        ),
      );

      // Promień korby w płaszczyźnie Y-Z (odległość od osi suportu [0, 0])
      final rPedal = math.sqrt(
        pose.rightPedalPosition.y * pose.rightPedalPosition.y +
            pose.rightPedalPosition.z * pose.rightPedalPosition.z,
      );
      final lPedal = math.sqrt(
        pose.leftPedalPosition.y * pose.leftPedalPosition.y +
            pose.leftPedalPosition.z * pose.leftPedalPosition.z,
      );

      // Długość korby szosowej to 172.5 mm
      expect(rPedal, closeTo(0.1725, 1e-3));
      expect(lPedal, closeTo(0.1725, 1e-3));

      // Rozstaw pedałów w osi X (Q-Factor)
      expect(pose.rightPedalPosition.x, greaterThan(0.0));
      expect(pose.leftPedalPosition.x, lessThan(0.0));
    });
  });

  group('Cyclist3DPoseAnimator - Cornering Lean Angle Physics', () {
    test('na prostej drodze kąt pochylenia roweru wynosi 0 stopni', () {
      final lean = Cyclist3DPoseAnimator.calculateCorneringLeanAngleDegrees(
        speedMs: 14.0,
        turningRadiusMeters: double.infinity,
      );
      expect(lean, equals(0.0));
    });

    test('zakręt w prawo (R > 0) daje dodatni kąt, a w lewo (R < 0) ujemny z prawa fizyki', () {
      const speed = 12.0; // ~43 km/h
      const radius = 60.0; // Łuk 60m

      final leanRight = Cyclist3DPoseAnimator.calculateCorneringLeanAngleDegrees(
        speedMs: speed,
        turningRadiusMeters: radius,
      );
      final leanLeft = Cyclist3DPoseAnimator.calculateCorneringLeanAngleDegrees(
        speedMs: speed,
        turningRadiusMeters: -radius,
      );

      // Wzór: tan(θ) = v^2 / (R * g) = 144 / (60 * 9.80665) = 144 / 588.4 ~ 0.2447
      // θ = atan(0.2447) ~ 13.75°
      const expectedAngle = 13.75;
      expect(leanRight, closeTo(expectedAngle, 0.4));
      expect(leanLeft, closeTo(-expectedAngle, 0.4));
      expect(leanLeft.abs(), closeTo(leanRight, 1e-4));
    });

    test('ekstremalny zakręt przy dużej prędkości jest bezpiecznie ograniczany do maxLean', () {
      final leanClamped = Cyclist3DPoseAnimator.calculateCorneringLeanAngleDegrees(
        speedMs: 25.0, // 90 km/h
        turningRadiusMeters: 15.0, // ciasna agrafka
        maxLeanDegrees: 44.0,
      );

      expect(leanClamped, closeTo(44.0, 1e-3));
    });
  });

  group('Cyclist3DPoseAnimator - Bike Sway & Standing Climb / Sprint >800W', () {
    test('w pozycji siedzącej kołysanie roweru jest minimalne (< 1 stopień)', () {
      final sway = Cyclist3DPoseAnimator.calculateBikeSwayAngleDegrees(
        crankAngleRadians: math.pi * 0.5,
        powerWatts: 350,
        standingProgress: 0.0, // W siodle
        isSprinting: false,
      );

      expect(sway.abs(), lessThan(1.0));
    });

    test('taniec na pedałach na podjeździe generuje kołysanie roweru 4-7 stopni', () {
      final swayClimb = Cyclist3DPoseAnimator.calculateBikeSwayAngleDegrees(
        crankAngleRadians: math.pi, // Faza maksymalnego nacisku
        powerWatts: 450,
        standingProgress: 1.0, // Pełne stanie
        isSprinting: false,
      );

      expect(swayClimb.abs(), greaterThan(4.0));
      expect(swayClimb.abs(), lessThan(8.0));
    });

    test('agresywny sprint z mocą >800W generuje maksymalne kołysanie roweru 9-14 stopni', () {
      final swaySprint = Cyclist3DPoseAnimator.calculateBikeSwayAngleDegrees(
        crankAngleRadians: math.pi,
        powerWatts: 1250, // Pełen sprint finiszowy 1250W
        standingProgress: 1.0,
        isSprinting: true,
      );

      expect(swaySprint.abs(), greaterThan(9.0));
      expect(swaySprint.abs(), lessThanOrEqualTo(14.0));
    });

    test('tułów kolarza przeciw-pochyla się w stronę przeciwną do kołysania roweru', () {
      final animator = Cyclist3DPoseAnimator();

      final pose = animator.update(
        0.016,
        const CyclistTelemetryInput(
          riderId: 'sprinter_1',
          speedMs: 17.5,
          powerWatts: 1100,
          cadenceRpm: 110,
          isSprinting: true,
          isStanding: true,
        ),
      );

      // Jeśli rower przechyla się w jedną stronę, przeciw-pochylenie tułowia ma przeciwny znak
      if (pose.bikeSwayAngleDegrees.abs() > 1.0) {
        expect(
          pose.riderCounterLeanAngleDegrees * pose.bikeSwayAngleDegrees,
          lessThan(0.0),
        );
      }
    });
  });

  group('Cyclist3DPoseAnimator - Handlebar Grips & Torso Incline', () {
    test('chwyt dolny (Drops) i lemondka (TT) mocniej obniżają sylwetkę niż klamkomanetki (Hoods)', () {
      final animatorHoods = Cyclist3DPoseAnimator(initialGrip: HandlebarGrip.hoods);
      final animatorDrops = Cyclist3DPoseAnimator(initialGrip: HandlebarGrip.drops);
      final animatorTt = Cyclist3DPoseAnimator(initialGrip: HandlebarGrip.ttExtensions);

      final poseHoods = animatorHoods.update(
        0.016,
        const CyclistTelemetryInput(
          riderId: 'r1',
          speedMs: 11.0,
          powerWatts: 280,
          cadenceRpm: 88,
          overrideGrip: HandlebarGrip.hoods,
        ),
      );

      final poseDrops = animatorDrops.update(
        0.016,
        const CyclistTelemetryInput(
          riderId: 'r1',
          speedMs: 15.0,
          powerWatts: 420,
          cadenceRpm: 95,
          overrideGrip: HandlebarGrip.drops,
        ),
      );

      final poseTt = animatorTt.update(
        0.016,
        const CyclistTelemetryInput(
          riderId: 'r1',
          speedMs: 14.5,
          powerWatts: 400,
          cadenceRpm: 92,
          isTimeTrial: true,
          overrideGrip: HandlebarGrip.ttExtensions,
        ),
      );

      // Kąt nachylenia tułowia: Hoods (~36°) > Drops (~24°) > TT (~9°)
      expect(poseHoods.torsoInclineDegrees, greaterThan(poseDrops.torsoInclineDegrees));
      expect(poseDrops.torsoInclineDegrees, greaterThan(poseTt.torsoInclineDegrees));
      expect(poseTt.torsoInclineDegrees, lessThan(15.0));

      // Dłonie na lemondce TT są skupione blisko osi symetrii (wąski rozstaw aero)
      final ttHandWidth = (poseTt.rightHandPosition.x - poseTt.leftHandPosition.x).abs();
      final hoodsHandWidth = (poseHoods.rightHandPosition.x - poseHoods.leftHandPosition.x).abs();
      expect(ttHandWidth, lessThan(hoodsHandWidth));
    });

    test('chwyt Aero Puppy Paws skupia dłonie blisko siebie i mocno pochyla tułów', () {
      final animator = Cyclist3DPoseAnimator(initialGrip: HandlebarGrip.aeroPuppyPaws);

      final pose = animator.update(
        0.016,
        const CyclistTelemetryInput(
          riderId: 'breakaway_solo',
          speedMs: 13.8,
          powerWatts: 380,
          cadenceRpm: 96,
          isAttacking: true,
          overrideGrip: HandlebarGrip.aeroPuppyPaws,
        ),
      );

      expect(pose.grip, equals(HandlebarGrip.aeroPuppyPaws));
      expect(pose.torsoInclineDegrees, closeTo(16.0, 1.0));
      // Dłonie skupione blisko siebie (rozstaw < 20 cm)
      final handSpread = (pose.rightHandPosition.x - pose.leftHandPosition.x).abs();
      expect(handSpread, lessThan(0.20));
    });
  });

  group('Cyclist3DPoseAnimator - Inverse Kinematics (IK) & Special Postures', () {
    test('kinematyka odwrotna (IK) zachowuje anatomiczne długości uda i podudzia kolarza', () {
      final animator = Cyclist3DPoseAnimator();

      final pose = animator.update(
        0.016,
        const CyclistTelemetryInput(
          riderId: 'r1',
          speedMs: 12.0,
          powerWatts: 320,
          cadenceRpm: 90,
        ),
      );

      // Odległość biodro -> kolano (Udo ~0.44m)
      final rThighLength = (pose.rightKneePosition - pose.hipPosition).length;
      final lThighLength = (pose.leftKneePosition - pose.hipPosition).length;
      expect(rThighLength, closeTo(0.44, 0.05));
      expect(lThighLength, closeTo(0.44, 0.05));

      // Odległość kolano -> pedał (Podudzie ~0.42m)
      final rCalfLength = (pose.rightPedalPosition - pose.rightKneePosition).length;
      final lCalfLength = (pose.leftPedalPosition - pose.leftKneePosition).length;
      expect(rCalfLength, closeTo(0.42, 0.05));
      expect(lCalfLength, closeTo(0.42, 0.05));
    });

    test('gest zwycięstwa na mecie (Victory Salute) unosi ręce wysoko w górę', () {
      final animator = Cyclist3DPoseAnimator();

      final pose = animator.update(
        0.016,
        const CyclistTelemetryInput(
          riderId: 'winner',
          speedMs: 11.5,
          powerWatts: 200,
          cadenceRpm: 80,
          hasWonStage: true,
        ),
      );

      expect(pose.posture, equals(RidingPosture.victorySalute));
      // Ręce uniesione powyżej głowy kolarza (> 1.25m nad suportem)
      expect(pose.rightHandPosition.y, greaterThan(1.25));
      expect(pose.leftHandPosition.y, greaterThan(1.25));
    });

    test('sięganie po bidon (Drinking Bidon) opuszcza prawą dłoń w stronę ramy', () {
      final animator = Cyclist3DPoseAnimator();

      final pose = animator.update(
        0.016,
        const CyclistTelemetryInput(
          riderId: 'helper',
          speedMs: 10.0,
          powerWatts: 220,
          cadenceRpm: 85,
          isDrinking: true,
        ),
      );

      expect(pose.posture, equals(RidingPosture.drinkingBidon));
      // Prawa dłoń przy koszyku na bidon (~0.38m nad suportem)
      expect(pose.rightHandPosition.y, lessThan(0.45));
      // Lewa dłoń bezpiecznie trzyma klamkomanetkę (~0.64m)
      expect(pose.leftHandPosition.y, greaterThan(0.60));
    });
  });
}

