// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/andes_eucalyptus_and_quebec_biomes_3d.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  group('AndesEucalyptusAndQuebecBiomes3d', () {
    const AndesEucalyptusAndQuebecBiomes3d engine =
        AndesEucalyptusAndQuebecBiomes3d();

    test('generuje wszystkie 3 biomy geograficzne z poprawną geometrią 3D', () {
      for (final AndesEucalyptusQuebecBiome biome
          in AndesEucalyptusQuebecBiome.values) {
        final AndesEucalyptusQuebecFrameState frame = engine.buildFrame(
          config: AndesEucalyptusQuebecConfig(biome: biome),
          cameraDistanceMeters: 120.0,
          elapsedSeconds: 2.4,
        );

        expect(frame.biome, biome);
        expect(frame.roadSlices.length, greaterThan(20));
        expect(frame.visibleProps, isNotEmpty);
        expect(frame.particles, isNotEmpty);
        expect(frame.pelotonMarkers.length, 9);
        expect(frame.effectiveCrrMultiplier, greaterThan(1.0));
        expect(frame.visibilityRangeMeters, greaterThan(150.0));
      }
    });

    test(
      'Wysokie Andy generują wielobarwne skały, krawędź przepaści, kondory i rozrzedzone powietrze',
      () {
        final AndesEucalyptusQuebecFrameState frame = engine.buildFrame(
          config: const AndesEucalyptusQuebecConfig(
            biome: AndesEucalyptusQuebecBiome.highAndesArgentinaColombia,
            enableDynamicWildlife: true,
          ),
          cameraDistanceMeters: 100.0,
          elapsedSeconds: 1.5,
        );

        final Set<AndesEucalyptusQuebecPropKind> kinds =
            frame.visibleProps.map((e) => e.kind).toSet();
        expect(
          kinds,
          contains(AndesEucalyptusQuebecPropKind.multicolorAndeanRockStrata),
        );
        expect(
          kinds,
          contains(AndesEucalyptusQuebecPropKind.precipiceGuardStone),
        );
        expect(
          kinds,
          contains(AndesEucalyptusQuebecPropKind.circlingAndeanCondor),
        );
        expect(frame.biome.hasCliffDropOff, isTrue);
        expect(frame.airDensityKgM3, lessThan(0.95));
        expect(frame.roadSlices.first.hasGravelPatches, isTrue);
      },
    );

    test(
      'Australijski Busz i Wiktoria generują eukaliptusy, czerwono-złotą trawę, kibiców i ocean',
      () {
        final AndesEucalyptusQuebecFrameState frame = engine.buildFrame(
          config: const AndesEucalyptusQuebecConfig(
            biome: AndesEucalyptusQuebecBiome.australianBushVictoriaCoast,
          ),
          cameraDistanceMeters: 110.0,
          elapsedSeconds: 1.8,
        );

        final Set<AndesEucalyptusQuebecPropKind> kinds =
            frame.visibleProps.map((e) => e.kind).toSet();
        expect(
          kinds,
          contains(AndesEucalyptusQuebecPropKind.eucalyptusGumTree),
        );
        expect(
          kinds,
          contains(AndesEucalyptusQuebecPropKind.redGoldBushGrass),
        );
        expect(
          kinds,
          contains(AndesEucalyptusQuebecPropKind.sunHatSpectatorCrowd),
        );
        expect(frame.biome.hasOceanHorizon, isTrue);
        expect(frame.heatShimmerAmplitudePx, greaterThan(1.0));
      },
    );

    test(
      'Jesienny Québec i Montréal generuje bruk, ogniste klony, kamienice i gęste barierki',
      () {
        final AndesEucalyptusQuebecFrameState frame = engine.buildFrame(
          config: const AndesEucalyptusQuebecConfig(
            biome: AndesEucalyptusQuebecBiome.quebecMontrealAutumnCircuit,
            enableSurfaceVibration: true,
          ),
          cameraDistanceMeters: 140.0,
          elapsedSeconds: 0.7,
        );

        final Set<AndesEucalyptusQuebecPropKind> kinds =
            frame.visibleProps.map((e) => e.kind).toSet();
        expect(
          kinds,
          contains(AndesEucalyptusQuebecPropKind.fieryAutumnMapleTree),
        );
        expect(
          kinds,
          contains(AndesEucalyptusQuebecPropKind.oldTownHistoricFacade),
        );
        expect(
          kinds,
          contains(AndesEucalyptusQuebecPropKind.denseUrbanRaceBarrier),
        );
        expect(frame.biome.isCobblestone, isTrue);
        expect(frame.particles.any((p) => p.isMapleLeaf), isTrue);
        expect(frame.cameraVibrationOffsetPx.abs(), greaterThan(0.0));
      },
    );

    test('sortowanie głębi visibleProps zachowuje kolejność od najdalszych', () {
      final AndesEucalyptusQuebecFrameState frame = engine.buildFrame(
        config: const AndesEucalyptusQuebecConfig(
          biome: AndesEucalyptusQuebecBiome.quebecMontrealAutumnCircuit,
        ),
        cameraDistanceMeters: 100.0,
        elapsedSeconds: 1.0,
      );

      for (int i = 0; i < frame.visibleProps.length - 1; i++) {
        expect(
          frame.visibleProps[i].distanceAlongCourseMeters,
          greaterThanOrEqualTo(
            frame.visibleProps[i + 1].distanceAlongCourseMeters,
          ),
        );
      }
    });

    test('rzutowanie 3D zwraca null za kamerą i poprawny Offset przed kamerą', () {
      final Offset? behind = engine.projectWorldPoint(
        worldPoint: Vector3(0.0, 0.0, 95.0),
        cameraPos: Vector3(0.0, 2.7, 100.0),
        cameraYawRadians: 0.0,
        cameraPitchRadians: -0.05,
        fovDegrees: 58.0,
        viewportSize: const Size(800, 600),
      );
      expect(behind, isNull);

      final Offset? ahead = engine.projectWorldPoint(
        worldPoint: Vector3(0.0, 0.0, 140.0),
        cameraPos: Vector3(0.0, 2.7, 100.0),
        cameraYawRadians: 0.0,
        cameraPitchRadians: -0.05,
        fovDegrees: 58.0,
        viewportSize: const Size(800, 600),
      );
      expect(ahead, isNotNull);
      expect(ahead!.dx, closeTo(400.0, 1.0));
    });
  });

  group('AndesEucalyptusQuebecPanel Widget', () {
    Future<void> pumpAtSize(
      WidgetTester tester,
      Size size, {
      bool autoPlay = false,
      bool enabled = true,
      ValueChanged<AndesEucalyptusQuebecBiome>? onBiomeChanged,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AndesEucalyptusQuebecPanel(
              autoPlay: autoPlay,
              enabled: enabled,
              onBiomeChanged: onBiomeChanged,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renderuje się bez przepełnień w 390x844 (mobile)', (
      WidgetTester tester,
    ) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(find.byType(AndesEucalyptusQuebecPanel), findsOneWidget);
      expect(find.text('WYSOKIE ANDY'), findsWidgets);
      expect(find.text('BUSZ & WIKTORIA'), findsOneWidget);
      expect(find.text('QUÉBEC JESIEŃ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się bez przepełnień w 1024x768 (tablet)', (
      WidgetTester tester,
    ) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.byType(AndesEucalyptusQuebecPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się bez przepełnień w 1600x900 (desktop)', (
      WidgetTester tester,
    ) async {
      await pumpAtSize(tester, const Size(1600, 900));
      expect(find.byType(AndesEucalyptusQuebecPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('przełącza biom, kamerę oraz krok +0.6s', (
      WidgetTester tester,
    ) async {
      AndesEucalyptusQuebecBiome? selected;
      await pumpAtSize(
        tester,
        const Size(1280, 800),
        onBiomeChanged: (AndesEucalyptusQuebecBiome b) => selected = b,
      );

      await tester.tap(find.text('BUSZ & WIKTORIA'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        selected,
        AndesEucalyptusQuebecBiome.australianBushVictoriaCoast,
      );

      await tester.tap(find.text('Helikopter'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('+0.6s'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('stan disabled blokuje przełączanie biomu', (
      WidgetTester tester,
    ) async {
      AndesEucalyptusQuebecBiome? selected;
      await pumpAtSize(
        tester,
        const Size(1280, 800),
        enabled: false,
        onBiomeChanged: (AndesEucalyptusQuebecBiome b) => selected = b,
      );

      await tester.tap(find.text('QUÉBEC JESIEŃ'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(selected, isNull);
    });
  });
}
