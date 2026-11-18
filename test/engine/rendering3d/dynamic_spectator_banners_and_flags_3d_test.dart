import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/dynamic_spectator_banners_and_flags_3d.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

void main() {
  group('DynamicSpectatorBannersAndFlags3dRenderer', () {
    test('generates deterministic banners with normalized leader surname', () {
      final DynamicSpectatorBannersAndFlags3dRenderer renderer =
          DynamicSpectatorBannersAndFlags3dRenderer();

      const DynamicSpectatorBannerConfig config = DynamicSpectatorBannerConfig(
        leaderSurname: '  pogacar  ',
        leaderFirstName: 'Tadej',
        primaryRegion: SpectatorRegionFlag.slovenia,
        stageSeed: 12345,
      );

      final List<StageSegment> segments = <StageSegment>[
        const StageSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 2.0,
          startElevationM: 1200.0,
          endElevationM: 1370.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 42.0,
          windDirectionDegrees: 180.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.cat1,
        ),
      ];

      final DynamicSpectatorBannersPack packA = renderer.generateStageBanners(
        config: config,
        segments: segments,
        endDistanceMeters: 2000,
      );
      final DynamicSpectatorBannersPack packB = renderer.generateStageBanners(
        config: config,
        segments: segments,
        endDistanceMeters: 2000,
      );

      expect(packA.activeLeaderName, 'POGACAR');
      expect(packA.dominantRegion, SpectatorRegionFlag.slovenia);
      expect(packA.instances, isNotEmpty);
      expect(packA.instances.length, packB.instances.length);
      expect(packA.instances.first.id, packB.instances.first.id);

      final bool hasLeaderNameBanner = packA.instances.any(
        (SpectatorBannerInstance3D item) =>
            item.bannerText.contains('POGACAR'),
      );
      expect(hasLeaderNameBanner, isTrue);
    });

    test('handles empty and overly long leader surnames gracefully', () {
      const DynamicSpectatorBannerConfig emptyCfg =
          DynamicSpectatorBannerConfig(leaderSurname: '   ');
      expect(emptyCfg.normalizedLeaderSurname, 'LIDER');

      const DynamicSpectatorBannerConfig longCfg = DynamicSpectatorBannerConfig(
        leaderSurname: 'VERYLONGCHAMPIONNAME12345',
      );
      expect(longCfg.normalizedLeaderSurname.length, 16);
    });

    test('queryVisibleRange returns only items within window', () {
      final DynamicSpectatorBannersAndFlags3dRenderer renderer =
          DynamicSpectatorBannersAndFlags3dRenderer();
      final DynamicSpectatorBannersPack pack = renderer.generateStageBanners(
        config: const DynamicSpectatorBannerConfig(),
        startDistanceMeters: 0.0,
        endDistanceMeters: 1000.0,
      );

      final List<SpectatorBannerInstance3D> window =
          pack.queryVisibleRange(200.0, 400.0);
      expect(window, isNotEmpty);
      for (final SpectatorBannerInstance3D item in window) {
        expect(item.distanceMeters, greaterThanOrEqualTo(200.0));
        expect(item.distanceMeters, lessThanOrEqualTo(400.0));
      }
      expect(pack.queryVisibleRange(500.0, 200.0), isEmpty);
    });

    test('renders 3D banners and flags onto Canvas and reports telemetry', () {
      final DynamicSpectatorBannersAndFlags3dRenderer renderer =
          DynamicSpectatorBannersAndFlags3dRenderer();
      const DynamicSpectatorBannerConfig config = DynamicSpectatorBannerConfig(
        leaderSurname: 'KWIATKOWSKI',
        primaryRegion: SpectatorRegionFlag.poland,
      );
      final DynamicSpectatorBannersPack pack = renderer.generateStageBanners(
        config: config,
        startDistanceMeters: 0.0,
        endDistanceMeters: 1000.0,
      );

      final Scene3DMathProjection projection = Scene3DMathProjection(
        viewportWidth: 1280,
        viewportHeight: 720,
      );
      projection.setView(
        eye: Scene3DMathProjection.courseToWorld3D(
          distanceMeters: 0.0,
          lateralOffsetMeters: 0.0,
          elevationMeters: 0.0,
          verticalOffsetMeters: 2.2,
        ),
        target: Scene3DMathProjection.courseToWorld3D(
          distanceMeters: 30.0,
          lateralOffsetMeters: 0.0,
          elevationMeters: 0.0,
          verticalOffsetMeters: 1.0,
        ),
      );

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      final SpectatorBannersTelemetry telemetry = renderer.render(
        canvas: canvas,
        size: const Size(1280, 720),
        projection: projection,
        pack: pack,
        config: config,
        cameraDistanceMeters: 100.0,
        animationTimeSeconds: 1.25,
      );
      recorder.endRecording();

      expect(telemetry.totalGenerated, pack.instances.length);
      expect(telemetry.visibleInFrame, greaterThan(0));
      expect(
        telemetry.bannersRendered + telemetry.flagsRendered,
        telemetry.visibleInFrame,
      );
    });
  });

  group('DynamicSpectatorBannersControlPanel', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: const DynamicSpectatorBannersControlPanel(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    }

    testWidgets('renders cleanly at 390x844 mobile layout', (
      WidgetTester tester,
    ) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(find.text('Banery Kibiców i Flagi Regionów 3D'), findsOneWidget);
    });

    testWidgets('renders cleanly at 1024x768 tablet layout', (
      WidgetTester tester,
    ) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.text('Banery Kibiców i Flagi Regionów 3D'), findsOneWidget);
    });

    testWidgets('renders cleanly at 1600x900 desktop layout and updates surname',
        (WidgetTester tester) async {
      await pumpAtSize(tester, const Size(1600, 900));
      await tester.enterText(find.byType(TextField), 'MAJKA');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Lider: MAJKA'), findsOneWidget);
    });
  });
}
