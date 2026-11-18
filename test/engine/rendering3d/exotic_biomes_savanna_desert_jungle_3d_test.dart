// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/exotic_biomes_savanna_desert_jungle_3d.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  group('ExoticBiomesSavannaDesertJungleEngine', () {
    const ExoticBiomesSavannaDesertJungleEngine engine =
        ExoticBiomesSavannaDesertJungleEngine();

    test('generuje wszystkie 3 biomy egzotyczne z poprawną geometrią 3D', () {
      for (final Exotic3dBiome biome in Exotic3dBiome.values) {
        final ExoticBiomes3dFrameState frame = engine.buildFrame(
          config: ExoticBiomes3dConfig(biome: biome),
          cameraDistanceMeters: 120.0,
          elapsedSeconds: 2.5,
        );

        expect(frame.biome, biome);
        expect(frame.roadSlices.length, greaterThan(15));
        expect(frame.visibleProps, isNotEmpty);
        expect(frame.particles, isNotEmpty);
        expect(frame.pelotonMarkers.length, 9);
        expect(frame.effectiveCrrMultiplier, greaterThan(1.0));
        expect(frame.visibilityRangeMeters, greaterThan(100.0));
      }
    });

    test('Rwanda Mur de Kigali generuje czerwoną ziemię, akacje, kibiców i drgania bruku', () {
      final ExoticBiomes3dFrameState frame = engine.buildFrame(
        config: const ExoticBiomes3dConfig(
          biome: Exotic3dBiome.rwandaMurDeKigali,
          enableSurfaceVibration: true,
        ),
        cameraDistanceMeters: 100.0,
        elapsedSeconds: 0.7,
      );

      final Set<Exotic3dPropKind> kinds =
          frame.visibleProps.map((e) => e.kind).toSet();
      expect(kinds, contains(Exotic3dPropKind.lateriteEmbankment));
      expect(kinds, contains(Exotic3dPropKind.savannaAcaciaTree));
      expect(kinds, contains(Exotic3dPropKind.kigaliSpectatorCrowd));
      expect(kinds, contains(Exotic3dPropKind.rwandaFlagPole));
      expect(frame.biome.isCobblestone, isTrue);
      expect(frame.cameraVibrationOffsetPx.abs(), greaterThan(0.0));
    });

    test('AlUla generuje kaniony piaskowcowe, wydmy, łachy piasku i wzrost Crr', () {
      final ExoticBiomes3dFrameState calmFrame = engine.buildFrame(
        config: const ExoticBiomes3dConfig(
          biome: Exotic3dBiome.alulaDesertCanyons,
          weatherIntensity: 0.2,
        ),
        cameraDistanceMeters: 140.0,
        elapsedSeconds: 1.5,
      );
      final ExoticBiomes3dFrameState stormFrame = engine.buildFrame(
        config: const ExoticBiomes3dConfig(
          biome: Exotic3dBiome.alulaDesertCanyons,
          weatherIntensity: 1.4,
        ),
        cameraDistanceMeters: 140.0,
        elapsedSeconds: 1.5,
      );

      final Set<Exotic3dPropKind> kinds =
          stormFrame.visibleProps.map((e) => e.kind).toSet();
      expect(kinds, contains(Exotic3dPropKind.sandstoneCanyonWall));
      expect(kinds, contains(Exotic3dPropKind.desertSandDune));
      expect(kinds, contains(Exotic3dPropKind.sandDriftPatch));
      expect(
        stormFrame.effectiveCrrMultiplier,
        greaterThan(calmFrame.effectiveCrrMultiplier),
      );
      expect(
        stormFrame.visibilityRangeMeters,
        lessThan(calmFrame.visibilityRangeMeters),
      );
    });

    test('Malezja generuje palmy olejowe, bambus, paprocie i mgłę przy 95% RH', () {
      final ExoticBiomes3dFrameState frame = engine.buildFrame(
        config: const ExoticBiomes3dConfig(
          biome: Exotic3dBiome.malaysiaTropicalJungle,
          weatherIntensity: 1.0,
        ),
        cameraDistanceMeters: 180.0,
        elapsedSeconds: 3.0,
      );

      final Set<Exotic3dPropKind> kinds =
          frame.visibleProps.map((e) => e.kind).toSet();
      expect(kinds, contains(Exotic3dPropKind.tropicalOilPalm));
      expect(kinds, contains(Exotic3dPropKind.giantBambooCluster));
      expect(kinds, contains(Exotic3dPropKind.jungleFernUnderstory));
      expect(kinds, contains(Exotic3dPropKind.monsoonMistPillar));
      expect(frame.biome.humidityPercent, 95.0);
    });

    test('sortowanie głębi visibleProps zachowuje kolejność od najdalszych', () {
      final ExoticBiomes3dFrameState frame = engine.buildFrame(
        config: const ExoticBiomes3dConfig(
          biome: Exotic3dBiome.alulaDesertCanyons,
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
        cameraPos: Vector3(0.0, 2.6, 100.0),
        cameraYawRadians: 0.0,
        cameraPitchRadians: -0.05,
        fovDegrees: 58.0,
        viewportSize: const Size(800, 600),
      );
      expect(behind, isNull);

      final Offset? ahead = engine.projectWorldPoint(
        worldPoint: Vector3(0.0, 0.0, 140.0),
        cameraPos: Vector3(0.0, 2.6, 100.0),
        cameraYawRadians: 0.0,
        cameraPitchRadians: -0.05,
        fovDegrees: 58.0,
        viewportSize: const Size(800, 600),
      );
      expect(ahead, isNotNull);
      expect(ahead!.dx, closeTo(400.0, 1.0));
    });
  });

  group('ExoticBiomesSavannaDesertJunglePanel Widget', () {
    Future<void> pumpAtSize(
      WidgetTester tester,
      Size size, {
      bool autoPlay = false,
      ValueChanged<Exotic3dBiome>? onBiomeChanged,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExoticBiomesSavannaDesertJunglePanel(
              autoPlay: autoPlay,
              onBiomeChanged: onBiomeChanged,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renderuje się poprawnie bez przepełnień w 390x844 (mobile)', (
      WidgetTester tester,
    ) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(find.byType(ExoticBiomesSavannaDesertJunglePanel), findsOneWidget);
      expect(find.text('MUR DE KIGALI'), findsOneWidget);
      expect(find.text('ALULA KANIONY'), findsOneWidget);
      expect(find.text('MALEZJA DŻUNGLA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się poprawnie bez przepełnień w 1024x768 (tablet)', (
      WidgetTester tester,
    ) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.byType(ExoticBiomesSavannaDesertJunglePanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się poprawnie bez przepełnień w 1600x900 (desktop)', (
      WidgetTester tester,
    ) async {
      await pumpAtSize(tester, const Size(1600, 900));
      expect(find.byType(ExoticBiomesSavannaDesertJunglePanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('przełącza biom oraz presety kamery i obsługuje krok +0.6s', (
      WidgetTester tester,
    ) async {
      Exotic3dBiome? selected;
      await pumpAtSize(
        tester,
        const Size(1280, 800),
        autoPlay: false,
        onBiomeChanged: (Exotic3dBiome b) => selected = b,
      );

      await tester.tap(find.text('ALULA KANIONY'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(selected, Exotic3dBiome.alulaDesertCanyons);

      await tester.tap(find.text('Helikopter'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('+0.6s'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });
}
