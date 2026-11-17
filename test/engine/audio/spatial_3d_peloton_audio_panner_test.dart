// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/audio/procedural_cycling_audio_engine.dart';
import 'package:pro_peloton_manager/engine/audio/spatial_3d_peloton_audio_panner.dart';
import 'package:pro_peloton_manager/engine/rendering3d/camera_rig_controller.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  group('Spatial3dPelotonAudioPanner — Fizyka 3D i Panorama Stereo', () {
    test('panoramuje źródła po lewej na kanał L i po prawej na kanał R', () {
      const panner = Spatial3dPelotonAudioPanner();
      final listener = SpatialAudioListener3D.fromLookAt(
        position: Vector3(0.0, 2.0, 0.0),
        target: Vector3(0.0, 2.0, 10.0),
      );

      // W układzie prawoskrętnym: forward = (0,0,1), up = (0,1,0) => right = forward x up = (-1,0,0)
      final rightPos = listener.position + (listener.right * 10.0) + (listener.forward * 5.0);
      final leftPos = listener.position - (listener.right * 10.0) + (listener.forward * 5.0);

      final rightCar = SpatialAudioSource3D(
        id: 'car_r',
        label: 'Wóz Prawy',
        category: SpatialAudioSourceCategory.teamCar,
        position: rightPos,
      );
      final leftCrowd = SpatialAudioSource3D(
        id: 'fan_l',
        label: 'Kibice Lewi',
        category: SpatialAudioSourceCategory.spectatorCrowd,
        position: leftPos,
      );

      final resRight = panner.computeSourcePan(source: rightCar, listener: listener);
      final resLeft = panner.computeSourcePan(source: leftCrowd, listener: listener);

      expect(resRight.pan, greaterThan(0.3));
      expect(resRight.rightGain, greaterThan(resRight.leftGain));

      expect(resLeft.pan, lessThan(-0.2));
      expect(resLeft.leftGain, greaterThan(resLeft.rightGain));
    });

    test('Equal Power zachowuje stałą energię L^2 + R^2', () {
      const panner = Spatial3dPelotonAudioPanner(
        panningLaw: SpatialPanningLaw.equalPower,
      );
      final listener = SpatialAudioListener3D.fromLookAt(
        position: Vector3.zero(),
        target: Vector3(0.0, 0.0, 10.0),
      );
      final source = SpatialAudioSource3D(
        id: 'car_side',
        label: 'Wóz z boku',
        category: SpatialAudioSourceCategory.teamCar,
        position: listener.right * 6.0,
        spreadRadiusMeters: 0.0,
      );

      final res = panner.computeSourcePan(source: source, listener: listener);
      final energy = (res.leftGain * res.leftGain) + (res.rightGain * res.rightGain);
      final expectedGain = res.distanceAttenuation * source.baseGain;
      expect(energy, closeTo(expectedGain * expectedGain, 0.02));
    });

    test('wycisza i odcina źródła poza maxDistanceMeters oraz wyciszone', () {
      const panner = Spatial3dPelotonAudioPanner();
      final listener = SpatialAudioListener3D.fromLookAt(
        position: Vector3.zero(),
        target: Vector3(0.0, 0.0, 10.0),
      );
      final farSource = SpatialAudioSource3D(
        id: 'far_crowd',
        label: 'Daleki tłum',
        category: SpatialAudioSourceCategory.spectatorCrowd,
        position: Vector3(0.0, 0.0, 300.0),
        maxDistanceMeters: 250.0,
      );
      final mutedSource = farSource.copyWith(
        id: 'muted',
        position: Vector3(0.0, 0.0, 5.0),
        isMuted: true,
      );

      expect(panner.computeSourcePan(source: farSource, listener: listener).isCulled, isTrue);
      expect(panner.computeSourcePan(source: mutedSource, listener: listener).isCulled, isTrue);
    });

    test('oblicza efekt Dopplera dla zbliżającego się i oddalającego wozu', () {
      const panner = Spatial3dPelotonAudioPanner(dopplerEnabled: true);
      final listener = SpatialAudioListener3D.fromLookAt(
        position: Vector3.zero(),
        target: Vector3(0.0, 0.0, 10.0),
        velocity: Vector3.zero(),
      );

      final approachingCar = SpatialAudioSource3D(
        id: 'car_in',
        label: 'Wóz zbliżający się',
        category: SpatialAudioSourceCategory.teamCar,
        position: Vector3(0.0, 0.0, 30.0),
        velocity: Vector3(0.0, 0.0, -20.0),
      );
      final recedingCar = SpatialAudioSource3D(
        id: 'car_out',
        label: 'Wóz oddalający się',
        category: SpatialAudioSourceCategory.teamCar,
        position: Vector3(0.0, 0.0, 30.0),
        velocity: Vector3(0.0, 0.0, 20.0),
      );

      final resIn = panner.computeSourcePan(source: approachingCar, listener: listener);
      final resOut = panner.computeSourcePan(source: recedingCar, listener: listener);

      expect(resIn.dopplerPitchRatio, greaterThan(1.04));
      expect(resOut.dopplerPitchRatio, lessThan(0.96));
    });

    test('integruje się bezpośrednio z CameraRigController i miksuje ramki z limiterem', () {
      final rig = CameraRigController(
        initialMode: RaceCameraMode.motoTvCam,
        initialPosition: Vector3(1.2, 1.65, 8.0),
        initialTarget: Vector3(0.0, 1.0, 0.0),
      );
      final listener = SpatialAudioListener3D.fromCameraRig(rig);
      expect(listener.cameraMode, RaceCameraMode.motoTvCam);
      expect(listener.forward.length, closeTo(1.0, 1e-5));
      expect(listener.right.dot(listener.forward).abs(), lessThan(1e-5));

      const panner = Spatial3dPelotonAudioPanner();
      final sources = Spatial3dPelotonAudioPanner.buildDefaultRaceSceneSources();
      final mixed = panner.mixSourcesToFrame(
        inputs: sources
            .map((s) => (source: s, frame: const AudioStereoFrame(0.8, 0.8)))
            .toList(),
        listener: listener,
      );
      expect(mixed.left.abs(), lessThanOrEqualTo(1.0));
      expect(mixed.right.abs(), lessThanOrEqualTo(1.0));
      expect(math.max(mixed.left.abs(), mixed.right.abs()), greaterThan(0.1));
    });
  });

  group('Spatial3dPelotonAudioPannerNotifier & Panel UI', () {
    test('notifier poprawnie przełącza kamery, prawo panoramy i wyciszenie', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(spatial3dPelotonAudioPannerProvider.notifier);

      expect(
        container.read(spatial3dPelotonAudioPannerProvider).listener.cameraMode,
        RaceCameraMode.chaseCam,
      );

      notifier.setCameraModePreset(RaceCameraMode.heliCam);
      expect(
        container.read(spatial3dPelotonAudioPannerProvider).listener.cameraMode,
        RaceCameraMode.heliCam,
      );

      notifier.setPanningLaw(SpatialPanningLaw.linear);
      expect(
        container.read(spatial3dPelotonAudioPannerProvider).panningLaw,
        SpatialPanningLaw.linear,
      );

      notifier.toggleBypass();
      final bypassed = container.read(spatial3dPelotonAudioPannerProvider);
      expect(bypassed.isBypassed, isTrue);
      for (final res in bypassed.results.values) {
        expect(res.leftGain, 0.0);
        expect(res.rightGain, 0.0);
      }
    });

    for (final size in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'panel renderuje się bez błędów i przepełnień w ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: Spatial3dPelotonAudioPannerPanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Panoramowanie 3D Audio Wyścigu'), findsOneWidget);
          expect(find.text('RADAR POLA STEREO 3D'), findsOneWidget);
          expect(find.text('Główna grupa peletonu'), findsOneWidget);

          await tester.tap(find.text('Helikopter'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.textContaining('Kamera: Helikopter'), findsOneWidget);

          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
