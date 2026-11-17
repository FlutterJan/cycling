import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/engine/rendering3d/team_bus_paddock_3d_scene_renderer.dart';
import 'package:pro_peloton_manager/models/team/team_bus_and_warmup_protocol_model.dart';

void main() {
  group('TeamBusPaddock3dSceneRenderer', () {
    test('buildDefaultRoster dopasowuje liczbę stanowisk do TeamBusTier', () {
      for (final tier in TeamBusTier.values) {
        final roster = PaddockWarmupRider3D.buildDefaultRoster(
          busTier: tier,
          teamJerseyColor: AppColors.primaryAccent,
        );
        expect(roster.length, tier.defaultTrainerSlots);
        expect(roster.first.isLeader, isTrue);
      }
    });

    test('powerZone poprawnie klasyfikuje strefy mocy Coggana 1-7', () {
      const base = PaddockWarmupRider3D(
        riderId: 'r1',
        riderName: 'Test Rider',
        bibNumber: 1,
        roleLabel: 'Lider',
        slotIndex: 0,
        ftpWatts: 400.0,
      );
      expect(base.copyWith(currentPowerWatts: 180.0).powerZone, 1);
      expect(base.copyWith(currentPowerWatts: 260.0).powerZone, 2);
      expect(base.copyWith(currentPowerWatts: 340.0).powerZone, 3);
      expect(base.copyWith(currentPowerWatts: 400.0).powerZone, 4);
      expect(base.copyWith(currentPowerWatts: 460.0).powerZone, 5);
      expect(base.copyWith(currentPowerWatts: 540.0).powerZone, 6);
      expect(base.copyWith(currentPowerWatts: 720.0).powerZone, 7);
    });

    test('paintScene generuje wielokąty 3D, telemetrię i hitboxy kolarzy', () {
      for (final mode in PaddockCameraMode.values) {
        for (final weather in PaddockWeatherPreset.values) {
          final config = TeamBusPaddock3dConfig(
            busTier: TeamBusTier.worldTourFlagshipBus,
            cameraMode: mode,
            weatherPreset: weather,
          );
          final renderer = TeamBusPaddock3dSceneRenderer(config: config);
          final riders = PaddockWarmupRider3D.buildDefaultRoster(
            busTier: config.busTier,
            teamJerseyColor: config.primaryColor,
          );

          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          final telemetry = renderer.paintScene(
            canvas: canvas,
            size: const Size(1024, 600),
            timeSeconds: 4.5,
            riders: riders,
            selectedRiderId: riders.first.riderId,
          );
          recorder.endRecording();

          expect(telemetry.renderedPolygonCount, greaterThan(40));
          expect(telemetry.activeWarmupRiders, 8);
          expect(telemetry.averagePowerWatts, greaterThan(0.0));
          expect(telemetry.riderHitboxes, isNotEmpty);
        }
      }
    });
  });

  group('TeamBusPaddock3dViewportWidget responsywność i interakcja', () {
    Future<void> pumpAtResolution(
      WidgetTester tester,
      Size size,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: const TeamBusPaddock3dViewportWidget(autoPlay: true),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    }

    testWidgets('renderuje bez overflow na 390x844 (mobile)', (tester) async {
      await pumpAtResolution(tester, const Size(390, 844));
      expect(find.text('PADDOCK & AUTOBUS 3D'), findsOneWidget);
    });

    testWidgets('renderuje bez overflow na 1024x768 (tablet)', (tester) async {
      await pumpAtResolution(tester, const Size(1024, 768));
      expect(find.text('PADDOCK & AUTOBUS 3D'), findsOneWidget);
    });

    testWidgets('renderuje bez overflow na 1600x900 (desktop)', (tester) async {
      await pumpAtResolution(tester, const Size(1600, 900));
      expect(find.text('PADDOCK & AUTOBUS 3D'), findsOneWidget);
    });

    testWidgets('obsługuje zmianę kamery, pogody, protokołu i pauzy',
        (tester) async {
      await pumpAtResolution(tester, const Size(1280, 800));

      await tester.tap(find.text('Pod Markizą'));
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Deszczowy Klasyk'));
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('4 stan.'));
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Pauza'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Wznów'), findsOneWidget);
    });
  });
}
