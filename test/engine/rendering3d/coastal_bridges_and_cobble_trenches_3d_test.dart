// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/coastal_bridges_and_cobble_trenches_3d.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  group('CoastalBridgesAndCobbleTrenchesEngine', () {
    const CoastalBridgesAndCobbleTrenchesEngine engine =
        CoastalBridgesAndCobbleTrenchesEngine();

    test('generuje wszystkie 4 ikoniczne biomy z poprawną geometrią 3D', () {
      for (final Iconic3dSceneryBiome biome in Iconic3dSceneryBiome.values) {
        final Scenery3dFrameState frame = engine.buildFrame(
          config: CoastalBridgesAndCobbleConfig(biome: biome),
          cameraDistanceMeters: 150.0,
          elapsedSeconds: 3.5,
        );

        expect(frame.biome, biome);
        expect(frame.roadSlices.length, greaterThan(10));
        expect(frame.visibleProps, isNotEmpty);
        expect(frame.particles, isNotEmpty);
        expect(frame.pelotonMarkers.length, 9);
        expect(frame.effectiveCrosswindMps, greaterThanOrEqualTo(0.0));
      }
    });

    test('Wielki Bełt generuje pylony, wieszaki linowe i statki morskie', () {
      final Scenery3dFrameState frame = engine.buildFrame(
        config: const CoastalBridgesAndCobbleConfig(
          biome: Iconic3dSceneryBiome.greatBeltSeaBridge,
        ),
        cameraDistanceMeters: 100.0,
        elapsedSeconds: 2.0,
      );

      final Set<SceneryPropKind> kinds =
          frame.visibleProps.map((e) => e.kind).toSet();
      expect(kinds, contains(SceneryPropKind.bridgePylon));
      expect(kinds, contains(SceneryPropKind.bridgeSuspender));
      expect(kinds, contains(SceneryPropKind.seaVessel));
      expect(frame.effectiveCrosswindMps, greaterThan(8.0));
    });

    test('Przekop Arenberg generuje drzewa sklepienia, barierki i drgania bruku', () {
      final Scenery3dFrameState frame = engine.buildFrame(
        config: const CoastalBridgesAndCobbleConfig(
          biome: Iconic3dSceneryBiome.arenbergForestTrench,
          enableSurfaceVibration: true,
        ),
        cameraDistanceMeters: 120.0,
        elapsedSeconds: 0.7,
      );

      final Set<SceneryPropKind> kinds =
          frame.visibleProps.map((e) => e.kind).toSet();
      expect(kinds, contains(SceneryPropKind.trenchCanopyTree));
      expect(kinds, contains(SceneryPropKind.trenchSpectatorBarrier));
      expect(frame.biome.rollingResistanceMultiplier, greaterThan(1.5));
      expect(frame.cameraVibrationOffsetPx.abs(), greaterThan(0.0));
    });

    test('Toskania generuje cyprysy, wychodnie kredowe i wille', () {
      final Scenery3dFrameState frame = engine.buildFrame(
        config: const CoastalBridgesAndCobbleConfig(
          biome: Iconic3dSceneryBiome.tuscanyChalkHills,
        ),
        cameraDistanceMeters: 140.0,
        elapsedSeconds: 1.5,
      );

      final Set<SceneryPropKind> kinds =
          frame.visibleProps.map((e) => e.kind).toSet();
      expect(kinds, contains(SceneryPropKind.tuscanCypress));
      expect(kinds, contains(SceneryPropKind.tuscanChalkOutcrop));
      expect(kinds, contains(SceneryPropKind.tuscanFarmhouse));
    });

    test('Mont Ventoux generuje wieżę obserwatorium, słupki, głazy i pomnik', () {
      final Scenery3dFrameState frame = engine.buildFrame(
        config: const CoastalBridgesAndCobbleConfig(
          biome: Iconic3dSceneryBiome.montVentouxLunarSummit,
        ),
        cameraDistanceMeters: 200.0,
        elapsedSeconds: 4.0,
      );

      final Set<SceneryPropKind> kinds =
          frame.visibleProps.map((e) => e.kind).toSet();
      expect(kinds, contains(SceneryPropKind.ventouxSummitTower));
      expect(kinds, contains(SceneryPropKind.ventouxSnowPole));
      expect(kinds, contains(SceneryPropKind.ventouxLimestoneBoulder));
      expect(kinds, contains(SceneryPropKind.ventouxMemorialStele));
      expect(frame.biome.altitudeMeters, 1909.0);
    });

    test('sortowanie głębi visibleProps zachowuje kolejność od najdalszych', () {
      final Scenery3dFrameState frame = engine.buildFrame(
        config: const CoastalBridgesAndCobbleConfig(
          biome: Iconic3dSceneryBiome.arenbergForestTrench,
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

    test('projectWorldToScreen odrzuca punkty za kamerą i rzutuje punkty przed kamerą', () {
      final Vector3 cam = Vector3(0.0, 68.0, 100.0);
      const Size viewport = Size(800, 600);

      final Offset? behind = CoastalBridgesAndCobbleTrenchesEngine
          .projectWorldToScreen(
            worldPoint: Vector3(0.0, 65.0, 90.0),
            cameraPos: cam,
            fovDegrees: 58.0,
            viewportSize: viewport,
          );
      expect(behind, isNull);

      final Offset? ahead = CoastalBridgesAndCobbleTrenchesEngine
          .projectWorldToScreen(
            worldPoint: Vector3(0.0, 65.0, 150.0),
            cameraPos: cam,
            fovDegrees: 58.0,
            viewportSize: viewport,
          );
      expect(ahead, isNotNull);
      expect(ahead!.dx, closeTo(400.0, 1.0));
    });
  });

  group('CoastalBridgesAndCobbleTrenchesPanel UI', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size surfaceSize, {
      ValueChanged<Iconic3dSceneryBiome>? onBiomeChanged,
    }) async {
      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoastalBridgesAndCobbleTrenchesPanel(
              autoPlay: false,
              onBiomeChanged: onBiomeChanged,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renderuje się poprawnie bez przepełnień na 390x844 (mobile)', (
      WidgetTester tester,
    ) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.text('WIELKI BEŁT'), findsOneWidget);
      expect(find.text('ARENBERG'), findsOneWidget);
      expect(find.text('TOSKANIA'), findsOneWidget);
      expect(find.text('MONT VENTOUX'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się poprawnie bez przepełnień na 1024x768 (tablet)', (
      WidgetTester tester,
    ) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('SCENERIA 3D — IKONICZNE SEKTORY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się poprawnie bez przepełnień na 1600x900 (desktop)', (
      WidgetTester tester,
    ) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(find.text('Morski Most — Wielki Bełt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('przełączanie biomów i sterowanie odtwarzaniem działa poprawnie', (
      WidgetTester tester,
    ) async {
      Iconic3dSceneryBiome? selected;
      await pumpPanelAtSize(
        tester,
        const Size(1280, 800),
        onBiomeChanged: (b) => selected = b,
      );

      await tester.tap(find.text('ARENBERG'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(selected, Iconic3dSceneryBiome.arenbergForestTrench);
      expect(find.text("Przekop Leśny — Trouée d'Arenberg"), findsOneWidget);

      await tester.tap(find.text('MONT VENTOUX'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(selected, Iconic3dSceneryBiome.montVentouxLunarSummit);
      expect(find.text('Księżycowy Szczyt — Mont Ventoux'), findsOneWidget);

      await tester.tap(find.text('Krok +6 m'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('0.13 km'), findsOneWidget);
    });
  });
}
