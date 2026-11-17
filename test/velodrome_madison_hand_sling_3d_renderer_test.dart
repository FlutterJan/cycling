// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/engine/physics/velodrome_keirin_and_madison_sling_solver.dart';
import 'package:pro_peloton_manager/engine/rendering3d/velodrome_madison_hand_sling_3d_renderer.dart';
import 'package:pro_peloton_manager/engine/rendering3d/velodrome_wooden_bowl_3d_renderer.dart';

void main() {
  group('VelodromeMadisonHandSling3dRenderer', () {
    test('renders Madison scene with Hand Sling & 10-lap sprint telemetry', () {
      final renderer = VelodromeMadisonHandSling3dRenderer(
        config: const VelodromeMadisonKeirinConfig(
          discipline: VelodromeTrackDisciplineMode.madison,
          totalLaps: 50,
          sprintIntervalLaps: 10,
        ),
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final pairs = [
        const MadisonHandSlingPair3D(
          teamId: 'bel',
          teamCode: 'BEL',
          jerseyColor: AppColors.accentBlue,
          secondaryColor: AppColors.goldAccent,
          activeRiderName: 'L. De Vylder',
          reliefRiderName: 'R. Ghys',
          activeDistanceMeters: 50.0,
          activeMetersAboveBlackLine: 0.9,
          activeSpeedKmh: 55.2,
          reliefDistanceMeters: 49.6,
          reliefMetersAboveBlackLine: 1.7,
          reliefSpeedKmh: 48.0,
          isSlingInProgress: true,
          slingProgress01: 0.55,
          lastSlingQuality: MadisonSlingQuality.textbookSlingshot,
          sprintPoints: 25,
          lapsGained: 1,
          isHeroTeam: true,
        ),
        const MadisonHandSlingPair3D(
          teamId: 'ned',
          teamCode: 'NED',
          jerseyColor: AppColors.amberWarning,
          secondaryColor: AppColors.textPrimary,
          activeRiderName: 'Y. Havik',
          reliefRiderName: 'J. van Schip',
          activeDistanceMeters: 42.0,
          activeMetersAboveBlackLine: 0.4,
          activeSpeedKmh: 54.6,
          reliefDistanceMeters: 34.0,
          reliefMetersAboveBlackLine: 3.1,
          reliefSpeedKmh: 35.0,
          sprintPoints: 18,
          lapsGained: 1,
        ),
      ];

      const derny = KeirinDernyMotorbike3D(
        distanceMeters: 60.0,
        metersAboveBlackLine: 0.3,
        speedKmh: 46.0,
        phase: KeirinRacePhase.dernyRampUp,
      );

      final telemetry = renderer.renderScene(
        canvas: canvas,
        size: const Size(1024, 768),
        timeSeconds: 1.5,
        madisonPairs: pairs,
        derny: derny,
        keirinRiders: const [],
        currentLap: 19,
      );
      recorder.endRecording().dispose();

      expect(telemetry.discipline, VelodromeTrackDisciplineMode.madison);
      expect(telemetry.currentLap, 19);
      expect(telemetry.lapsToNextSprint, 1);
      expect(telemetry.isSprintBellLap, isTrue);
      expect(telemetry.activeSlingCount, 1);
      expect(telemetry.standings.length, 2);
      expect(telemetry.standings.first.teamCode, 'BEL');
      expect(telemetry.standings.first.points, 25);
    });

    test('renders Keirin scene with Derny pull-off phase', () {
      final renderer = VelodromeMadisonHandSling3dRenderer(
        config: const VelodromeMadisonKeirinConfig(
          discipline: VelodromeTrackDisciplineMode.keirin,
          cameraMode: MadisonKeirinCameraMode.dernyMoto,
          totalLaps: 6,
        ),
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      const derny = KeirinDernyMotorbike3D(
        distanceMeters: 120.0,
        metersAboveBlackLine: 0.35,
        speedKmh: 50.0,
        phase: KeirinRacePhase.dernyPullOff,
        isPullingOff: true,
        pullOffProgress01: 0.6,
      );

      const keirinRiders = [
        VelodromeTrackRider3D(
          riderId: 'k1',
          shortName: 'LAV',
          jerseyColor: AppColors.amberWarning,
          helmetColor: AppColors.textPrimary,
          bikeFrameColor: AppColors.surfaceLight,
          distanceMeters: 114.0,
          metersAboveBlackLine: 0.30,
          speedKmh: 62.4,
          cadenceRpm: 126.0,
          powerWatts: 1380.0,
        ),
      ];

      final telemetry = renderer.renderScene(
        canvas: canvas,
        size: const Size(800, 600),
        timeSeconds: 3.0,
        madisonPairs: const [],
        derny: derny,
        keirinRiders: keirinRiders,
        currentLap: 4,
      );
      recorder.endRecording().dispose();

      expect(telemetry.discipline, VelodromeTrackDisciplineMode.keirin);
      expect(telemetry.dernySpeedKmh, 50.0);
      expect(telemetry.dernyPhase, KeirinRacePhase.dernyPullOff);
      expect(telemetry.visiblePairsCount, 1);
    });

    for (final viewportSize in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'VelodromeMadisonHandSlingViewportWidget renders without overflow at '
        '${viewportSize.width.toInt()}x${viewportSize.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = viewportSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: VelodromeMadisonHandSlingViewportWidget(),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.text('Madison (Pary)'), findsOneWidget);
          expect(find.text('Keirin (Derny)'), findsOneWidget);

          await tester.tap(find.text('Keirin (Derny)'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);

          await tester.ensureVisible(find.text('Zjazd Derny'));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(find.text('Zjazd Derny'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
