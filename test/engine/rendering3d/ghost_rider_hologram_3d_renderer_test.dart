import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/rendering3d/ghost_rider_hologram_3d_renderer.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  group('GhostRiderHologram3dRenderer', () {
    test('interpolates historical samples and estimates elapsed time accurately', () {
      final GhostRiderRecordProfile profile =
          GhostRiderRecordProfile.ittWorldChampionshipPreset();
      final GhostRiderHologram3dRenderer renderer =
          GhostRiderHologram3dRenderer(recordProfile: profile);

      final GhostRiderHistoricalSample midSample = renderer.sampleAtElapsedTime(
        profile.targetTimeSeconds * 0.5,
      );
      expect(midSample.distanceMeters, greaterThan(0.0));
      expect(midSample.distanceMeters, lessThan(profile.totalDistanceMeters));
      expect(midSample.powerWatts, greaterThan(350.0));

      final double estTime = renderer.estimateElapsedAtDistance(
        profile.totalDistanceMeters * 0.5,
      );
      expect(
        estTime,
        closeTo(profile.targetTimeSeconds * 0.5, 45.0),
      );
    });

    test('handles empty sample list gracefully via analytical fallback', () {
      const GhostRiderRecordProfile emptyProfile = GhostRiderRecordProfile(
        recordId: 'empty_test',
        riderName: 'Test Rider',
        teamCode: 'TST',
        recordYear: 2025,
        discipline: GhostHologramDiscipline.komClimb,
        courseOrSegmentName: 'Test Climb',
        totalDistanceMeters: 10000.0,
        targetTimeSeconds: 2000.0,
        averageSpeedKmh: 18.0,
        averagePowerWatts: 380.0,
        samples: <GhostRiderHistoricalSample>[],
      );
      final GhostRiderHologram3dRenderer renderer =
          GhostRiderHologram3dRenderer(recordProfile: emptyProfile);

      final GhostRiderHistoricalSample sample = renderer.sampleAtElapsedTime(
        1000.0,
      );
      expect(sample.distanceMeters, closeTo(5000.0, 1e-3));
      expect(sample.powerWatts, closeTo(380.0, 1e-3));
      expect(renderer.estimateElapsedAtDistance(5000.0), closeTo(1000.0, 1e-3));
    });

    test('evaluates side-by-side lane offset and velodrome lap wrapping', () {
      final GhostRiderRecordProfile hourProfile =
          GhostRiderRecordProfile.velodromeHourRecordPreset();
      final GhostRiderHologram3dRenderer renderer =
          GhostRiderHologram3dRenderer(
            recordProfile: hourProfile,
            config: const GhostRiderHologramConfig(
              lateralLaneOffsetMeters: 1.2,
            ),
          );

      final GhostRiderHistoricalSample sampleAt30s = renderer
          .sampleAtElapsedTime(30.0);
      final GhostRiderHologramFrameState state = renderer.evaluateFrame(
        GhostRiderHologramFrameInput(
          playerDistanceMeters: sampleAt30s.distanceMeters - 1.0,
          playerElapsedSeconds: 30.0,
          playerSpeedMs: sampleAt30s.speedMs,
          playerLateralOffsetMeters: sampleAt30s.lateralOffsetMeters,
          animationTimeSeconds: 30.0,
          isVelodrome: true,
          velodromeTrackLengthMeters: 250.0,
        ),
      );

      expect(state.isVisible, isTrue);
      expect(state.sideBySideStatus, GhostHologramSideBySideStatus.neckAndNeck);
      expect(
        (state.ghostLateralOffsetMeters - sampleAt30s.lateralOffsetMeters)
            .abs(),
        greaterThanOrEqualTo(1.1),
      );
      expect(state.ghostTrackWrappedDistanceMeters, inInclusiveRange(0.0, 250.0));
      expect(state.trailSamples, isNotEmpty);
    });

    test('hides hologram when disabled or beyond maxVisibleRangeMeters', () {
      final GhostRiderRecordProfile komProfile =
          GhostRiderRecordProfile.alpeDhuezKomPreset();
      final GhostRiderHologram3dRenderer renderer =
          GhostRiderHologram3dRenderer(
            recordProfile: komProfile,
            config: const GhostRiderHologramConfig(enabled: false),
          );

      final GhostRiderHologramFrameState disabledState = renderer.evaluateFrame(
        const GhostRiderHologramFrameInput(
          playerDistanceMeters: 500.0,
          playerElapsedSeconds: 100.0,
          playerSpeedMs: 5.5,
        ),
      );
      expect(disabledState.isVisible, isFalse);
      expect(disabledState.effectiveOpacity, 0.0);

      renderer.updateConfig(
        const GhostRiderHologramConfig(
          enabled: true,
          maxVisibleRangeMeters: 100.0,
        ),
      );
      final GhostRiderHologramFrameState farState = renderer.evaluateFrame(
        const GhostRiderHologramFrameInput(
          playerDistanceMeters: 5000.0,
          playerElapsedSeconds: 10.0,
          playerSpeedMs: 5.5,
        ),
      );
      expect(farState.isVisible, isFalse);
    });

    test('serializes and deserializes GhostRiderRecordProfile cleanly', () {
      final GhostRiderRecordProfile original =
          GhostRiderRecordProfile.alpeDhuezKomPreset();
      final Map<String, dynamic> json = original.toJson();
      final GhostRiderRecordProfile decoded = GhostRiderRecordProfile.fromJson(
        json,
      );

      expect(decoded.recordId, original.recordId);
      expect(decoded.discipline, original.discipline);
      expect(decoded.samples.length, original.samples.length);
      expect(
        decoded.samples.first.powerWatts,
        closeTo(original.samples.first.powerWatts, 1e-6),
      );
    });

    test('paints 3D hologram onto Canvas without errors', () {
      final GhostRiderRecordProfile profile =
          GhostRiderRecordProfile.ittWorldChampionshipPreset();
      final GhostRiderHologram3dRenderer renderer =
          GhostRiderHologram3dRenderer(recordProfile: profile);
      final GhostRiderHologramFrameState state = renderer.evaluateFrame(
        const GhostRiderHologramFrameInput(
          playerDistanceMeters: 300.0,
          playerElapsedSeconds: 20.0,
          playerSpeedMs: 14.8,
          animationTimeSeconds: 20.0,
        ),
      );

      final Scene3DMathProjection projection = Scene3DMathProjection(
        viewportWidth: 800,
        viewportHeight: 450,
      )..updateCamera(
          Camera3DConfig(
            position: Vector3(0.0, 2.0, -5.0),
            target: Vector3(0.0, 1.0, 6.0),
          ),
          viewportWidth: 800,
          viewportHeight: 450,
        );

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      renderer.paintGhostRider3d(
        canvas: canvas,
        size: const Size(800, 450),
        projection: projection,
        state: state,
        ghostWorldBase: Vector3(1.1, 0.0, 3.0),
        playerWorldBase: Vector3(-0.6, 0.0, 0.0),
      );
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('GhostRiderHologramControlPanel responsive UI', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: GhostRiderHologramControlPanel(
                onConfigChanged: (_) {},
                onProfileChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders without overflow on 390x844 mobile', (
      WidgetTester tester,
    ) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(find.text('Złoty Hologram Rekordzisty 3D'), findsOneWidget);
      expect(find.text('HOLOGRAM WŁ.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on 1024x768 tablet', (
      WidgetTester tester,
    ) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.text('Jazda na czas (ITT)'), findsOneWidget);
      expect(find.text('Rekord Godzinny (Tor)'), findsOneWidget);
      expect(find.text('Podjazd KOM'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on 1600x900 desktop and switches modes', (
      WidgetTester tester,
    ) async {
      await pumpAtSize(tester, const Size(1600, 900));

      await tester.tap(find.text('Rekord Godzinny (Tor)'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Grenchen'), findsWidgets);

      await tester.tap(find.text('HOLOGRAM WŁ.'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('HOLOGRAM WYŁ.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
