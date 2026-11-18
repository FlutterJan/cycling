// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/rendering3d/camera_rig_controller.dart';
import 'package:pro_peloton_manager/engine/rendering3d/peloton_instanced_renderer.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:pro_peloton_manager/services/career/cyclist_olympic_and_world_champion_custom_gear.dart';
import 'package:pro_peloton_manager/state/race_simulation_notifier.dart';

void main() {
  group('CyclistOlympicAndWorldChampionCustomGear', () {
    const service = CyclistOlympicAndWorldChampionCustomGear();

    test('World Champion receives white frame with rainbow seat tube, white rainbow helmet, and white shoes', () {
      final grant = service.grantWorldChampionGear(
        riderId: 'r_wc',
        riderName: 'Tadej Pogačar',
        nationalityIso: 'SLO',
        teamName: 'UAE Team Emirates',
        yearWon: 2026,
        discipline: ChampionGearRaceDiscipline.roadRace,
      );

      final spec = service.resolveVisualSpecForRider(
        riderId: 'r_wc',
        grants: [grant],
        currentYear: 2026,
        raceDiscipline: ChampionGearRaceDiscipline.roadRace,
      );

      expect(spec.hasCustomGear, isTrue);
      expect(spec.framePrimaryHex, '#FFFFFF');
      expect(spec.hasSeatTubeRainbowBands, isTrue);
      expect(spec.helmetPrimaryHex, '#FFFFFF');
      expect(spec.hasHelmetRainbowBand, isTrue);
      expect(spec.shoesHex, '#FFFFFF');
      expect(spec.isGoldOlympicHelmet, isFalse);

      // Po 1 roku tytuł MŚ wygasa
      final expiredSpec = service.resolveVisualSpecForRider(
        riderId: 'r_wc',
        grants: [grant],
        currentYear: 2027,
        raceDiscipline: ChampionGearRaceDiscipline.roadRace,
      );
      expect(expiredSpec.hasCustomGear, isFalse);
    });

    test('Olympic Champion receives Gold Olympic Helmet, gold handlebar tape, and gold frame details for 4 years in all races', () {
      final grant = service.grantOlympicChampionGear(
        riderId: 'r_og',
        riderName: 'Remco Evenepoel',
        nationalityIso: 'BEL',
        teamName: 'Soudal Quick-Step',
        olympicYearWon: 2024,
        discipline: ChampionGearRaceDiscipline.roadRace,
      );

      // Widoczny we wszystkich wyścigach (Road Race i ITT) przez kolejne 4 lata: 2024, 2025, 2026, 2027
      for (final year in [2024, 2025, 2026, 2027]) {
        for (final disc in [
          ChampionGearRaceDiscipline.roadRace,
          ChampionGearRaceDiscipline.individualTimeTrial,
        ]) {
          final spec = service.resolveVisualSpecForRider(
            riderId: 'r_og',
            grants: [grant],
            currentYear: year,
            raceDiscipline: disc,
          );
          expect(spec.hasCustomGear, isTrue, reason: 'Active in $year ($disc)');
          expect(spec.isGoldOlympicHelmet, isTrue);
          expect(spec.helmetPrimaryHex, '#D4AF37');
          expect(spec.handlebarTapeHex, '#D4AF37');
          expect(spec.hasGoldFrameDetails, isTrue);
          expect(spec.frameAccentHex, '#D4AF37');
        }
      }

      // W 5. roku (2028) przywilej wygasa
      final expiredSpec = service.resolveVisualSpecForRider(
        riderId: 'r_og',
        grants: [grant],
        currentYear: 2028,
        raceDiscipline: ChampionGearRaceDiscipline.roadRace,
      );
      expect(expiredSpec.hasCustomGear, isFalse);
    });

    test('Dual Champion merges World Champion white rainbow frame/shoes with Olympic gold details/tape/helmet and serializes JSON', () {
      final wc = service.grantWorldChampionGear(
        riderId: 'r_dual',
        riderName: 'Dual Legend',
        nationalityIso: 'BEL',
        teamName: 'Pro Team',
        yearWon: 2026,
      );
      final og = service.grantOlympicChampionGear(
        riderId: 'r_dual',
        riderName: 'Dual Legend',
        nationalityIso: 'BEL',
        teamName: 'Pro Team',
        olympicYearWon: 2024,
      );

      final roundTrippedGrants = [
        ChampionCustomGearGrant.fromJson(wc.toJson()),
        ChampionCustomGearGrant.fromJson(og.toJson()),
      ];

      final spec = service.resolveVisualSpecForRider(
        riderId: 'r_dual',
        grants: roundTrippedGrants,
        currentYear: 2026,
      );

      final specFromJson = ChampionGear3dVisualSpec.fromJson(spec.toJson());
      expect(specFromJson.framePrimaryHex, '#FFFFFF');
      expect(specFromJson.hasSeatTubeRainbowBands, isTrue);
      expect(specFromJson.hasGoldFrameDetails, isTrue);
      expect(specFromJson.handlebarTapeHex, '#D4AF37');
      expect(specFromJson.shoesHex, '#FFFFFF');
      expect(specFromJson.isGoldOlympicHelmet, isTrue);
      expect(specFromJson.activeTitles.length, 2);
    });

    test('PelotonInstancedRenderer prepares and paints riders with championGearSpecs without errors', () {
      final renderer = PelotonInstancedRenderer();
      final projection = Scene3DMathProjection(
        viewportWidth: 1280,
        viewportHeight: 720,
      );
      final camera = CameraRigController();

      final riders = [
        const RiderPositionSnapshot(
          riderId: 'wc_1',
          riderName: 'World Champ',
          bibNumber: 1,
          teamId: 't1',
          teamName: 'Team A',
          teamJerseyHexColor: '#FFFFFF',
          isPlayerRider: true,
          distanceCoveredMeters: 15.0,
          kilometerMark: 0.015,
          elevationMeters: 100.0,
          currentGradientPercent: 0.0,
          currentSegmentIndex: 0,
          speedMs: 12.0,
          speedKmh: 43.2,
          powerWatts: 350,
          wattsPerKg: 5.2,
          cadenceRpm: 92,
          heartRateBpm: 162,
          wPrimePercentage: 95.0,
          wPrimeJoules: 19000.0,
          glycogenPercentage: 90.0,
          glycogenGrams: 450.0,
          hydrationPercent: 95.0,
          bidonsLeft: 2,
          gelsLeft: 3,
          activeTacticalOrder: TacticalOrder.holdPosition,
          groupIndex: 0,
          groupType: GroupType.peloton,
          timeGapToLeaderSeconds: 0.0,
          lateralPositionRoad: 0.0,
          lateralOffsetRoadMeters: 0.0,
          isDrafting: true,
          draftingSavingsPercent: 25.0,
          isPulling: false,
          hasDefect: false,
          isCrashed: false,
          isDnf: false,
        ),
      ];

      final grants = service.buildDefaultDemoGrants(2026);
      final specs = service.resolvePelotonVisualSpecs(
        riderIds: ['wc_1'],
        grants: [
          grants.first.toJson().let((m) => ChampionCustomGearGrant.fromJson({
                ...m,
                'riderId': 'wc_1',
              })),
        ],
        currentYear: 2026,
      );

      final items = renderer.prepareDrawList(
        riders: riders,
        projection: projection,
        cameraController: camera,
        championGearSpecs: specs,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      renderer.renderPeloton(
        canvas: canvas,
        size: const Size(1280, 720),
        projection: projection,
        renderItems: items,
      );
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('CyclistOlympicAndWorldChampionCustomGearPanel responsive UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
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
                  body: CyclistOlympicAndWorldChampionCustomGearPanel(),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          expect(
            find.text('Sprzęt Mistrzowski 3D — MŚ UCI & Igrzyska Olimpijskie'),
            findsOneWidget,
          );
        },
      );
    }
  });
}

extension _LetExt<T> on T {
  R let<R>(R Function(T value) block) => block(this);
}
