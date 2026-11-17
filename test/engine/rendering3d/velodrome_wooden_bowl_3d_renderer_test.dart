// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/velodrome_banking_and_centripetal_solver.dart';
import 'package:pro_peloton_manager/engine/rendering3d/velodrome_wooden_bowl_3d_renderer.dart';
import 'package:pro_peloton_manager/models/race/velodrome_track_and_hour_record_model.dart';

void main() {
  group('VelodromeTrackGeometryBuilder', () {
    test('generates closed 250 m oval with 13 deg straight and 42 deg turn apex',
        () {
      const facility = VelodromeFacilitySpec(
        id: 'test_250',
        name: 'Test Velodrome',
        city: 'Grenchen',
        countryCode: 'SUI',
        trackLengthMeters: 250.0,
        turnBankingDegrees: 42.0,
        straightBankingDegrees: 13.0,
        altitudeMeters: 451.0,
        turnRadiusMeters: 23.0,
      );
      final builder = VelodromeTrackGeometryBuilder(facility);

      final sStart = builder.sampleAt(0.0);
      final sWrap = builder.sampleAt(250.0);
      expect((sStart.innerEdge - sWrap.innerEdge).length, lessThan(1e-4));

      // Środek prostej 1
      final midStraight = builder.sampleAt(builder.straightLengthMeters * 0.5);
      expect(midStraight.section, VelodromeTrackSection.straight);
      expect(midStraight.bankingDegrees, closeTo(13.0, 0.5));

      // Wierzchołek wirażu 1
      final turnApex = builder.sampleAt(
        builder.straightLengthMeters + builder.turnArcLengthMeters * 0.5,
      );
      expect(turnApex.section, VelodromeTrackSection.turnApex);
      expect(turnApex.bankingDegrees, closeTo(42.0, 0.5));

      // Wektory bazy powierzchni są znormalizowane i ortogonalne
      expect(turnApex.surfaceNormal.length, closeTo(1.0, 1e-6));
      expect(turnApex.surfaceCrossVector.length, closeTo(1.0, 1e-6));
      expect(
        turnApex.surfaceNormal.dot(turnApex.surfaceCrossVector).abs(),
        lessThan(1e-6),
      );
    });
  });

  group('VelodromeWoodenBowl3dRenderer', () {
    test('renders all 4 camera modes and computes telemetry accurately', () {
      for (final mode in VelodromeCameraMode.values) {
        final renderer = VelodromeWoodenBowl3dRenderer(
          config: VelodromeWoodenBowlConfig(cameraMode: mode),
        );
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        final telemetry = renderer.paintScene(
          canvas: canvas,
          size: const Size(1280, 720),
          timeSeconds: 12.5,
          heroRider: const VelodromeTrackRider3D(
            riderId: 'ganna',
            shortName: 'GANNA',
            jerseyColor: Color(0xFF8E4A49),
            helmetColor: Color(0xFFD4AF37),
            bikeFrameColor: Color(0xFF38BDF8),
            distanceMeters: 205.0,
            metersAboveBlackLine: 0.0,
            speedKmh: 58.0,
          ),
        );
        recorder.endRecording();

        expect(telemetry.renderedTrackQuads, greaterThan(50));
        expect(telemetry.renderedSpotlights, greaterThan(0));
        expect(telemetry.currentLap, 1);
        expect(telemetry.gForceLoadFactor, greaterThanOrEqualTo(1.0));
      }
    });

    test('disabling roof spotlights yields zero rendered spotlights', () {
      final renderer = VelodromeWoodenBowl3dRenderer(
        config: const VelodromeWoodenBowlConfig(
          cameraMode: VelodromeCameraMode.broadcastBowl,
          showRoofAndSpotlights: false,
        ),
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final telemetry = renderer.paintScene(
        canvas: canvas,
        size: const Size(1024, 768),
        timeSeconds: 5.0,
        heroRider: const VelodromeTrackRider3D(
          riderId: 'test',
          shortName: 'TEST',
          jerseyColor: Colors.white,
          helmetColor: Colors.amber,
          bikeFrameColor: Colors.blue,
          distanceMeters: 60.0,
        ),
      );
      recorder.endRecording();

      expect(telemetry.renderedSpotlights, 0);
    });
  });

  group('VelodromeWoodenBowlViewportWidget', () {
    for (final viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: VelodromeWoodenBowlViewportWidget(autoPlay: false),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(VelodromeWoodenBowlViewportWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('allows switching camera mode and toggling laser WR',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VelodromeWoodenBowlViewportWidget(autoPlay: false),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('APEX 42°'));
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Laser WR'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(tester.takeException(), isNull);
    });
  });
}
