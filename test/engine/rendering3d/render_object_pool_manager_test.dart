// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/render_object_pool_manager.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  group('RenderObjectPoolManager', () {
    test('preallocates buffers for 176 riders, 352 wheels, and 890 weather particles', () {
      final RenderObjectPoolManager pool = RenderObjectPoolManager();
      final RenderPoolMemoryStats stats = pool.memoryStats;

      expect(stats.maxRiders, 176);
      expect(stats.maxWheels, 352);
      expect(stats.maxWeatherParticles, 890);
      expect(pool.riders.transformMatrices.length, 176 * 16);
      expect(pool.wheels.transformMatrices.length, 352 * 16);
      expect(pool.weatherParticles.transformMatrices.length, 890 * 16);
      expect(stats.totalPreallocatedBytes, greaterThan(0));
      expect(stats.zeroAllocationActive, isTrue);
    });

    test('RiderPoolBuffer stores 4x4 matrix and sorts visible riders back-to-front', () {
      final RenderObjectPoolManager pool = RenderObjectPoolManager();
      pool.beginFrame();

      pool.riders.setRiderState(
        slot: 0,
        posX: 1.0,
        posY: 2.0,
        posZ: 3.0,
        tangentX: 0.0,
        tangentY: 0.0,
        tangentZ: 1.0,
        rightX: 1.0,
        rightY: 0.0,
        rightZ: 0.0,
        upX: 0.0,
        upY: 1.0,
        upZ: 0.0,
        screenX: 100.0,
        screenY: 200.0,
        screenScale: 0.8,
        cameraDistance: 15.0,
        isVisible: true,
      );

      pool.riders.setRiderState(
        slot: 1,
        posX: 4.0,
        posY: 5.0,
        posZ: 6.0,
        tangentX: 0.0,
        tangentY: 0.0,
        tangentZ: 1.0,
        rightX: 1.0,
        rightY: 0.0,
        rightZ: 0.0,
        upX: 0.0,
        upY: 1.0,
        upZ: 0.0,
        screenX: 120.0,
        screenY: 180.0,
        screenScale: 0.4,
        cameraDistance: 85.0,
        isVisible: true,
      );

      pool.riders.setRiderState(
        slot: 2,
        posX: 0.0,
        posY: 0.0,
        posZ: -50.0,
        tangentX: 0.0,
        tangentY: 0.0,
        tangentZ: 1.0,
        rightX: 1.0,
        rightY: 0.0,
        rightZ: 0.0,
        upX: 0.0,
        upY: 1.0,
        upZ: 0.0,
        screenX: 0.0,
        screenY: 0.0,
        screenScale: 0.0,
        cameraDistance: 500.0,
        isVisible: false,
      );

      final int visibleCount = pool.riders.sortVisibleBackToFront();
      expect(visibleCount, 2);
      expect(pool.riders.sortedIndices[0], 1); // 85.0m (farther) first
      expect(pool.riders.sortedIndices[1], 0); // 15.0m (closer) second

      final Matrix4 target = pool.scratch.acquireIdentityMatrix4();
      pool.riders.copyMatrixIntoMatrix4(0, target);
      expect(target.storage[12], 1.0);
      expect(target.storage[13], 2.0);
      expect(target.storage[14], 3.0);
      expect(target.storage[15], 1.0);

      pool.endFrame();
      expect(pool.memoryStats.activeRiders, 3);
      expect(pool.memoryStats.visibleRiders, 2);
    });

    test('WheelPoolBuffer computes spoke endpoints in-place without allocations', () {
      final RenderObjectPoolManager pool = RenderObjectPoolManager();
      pool.beginFrame();

      pool.wheels.setWheelState(
        wheelSlot: 0,
        worldX: 2.5,
        worldY: 0.34,
        worldZ: 10.0,
        rotationRadians: 0.5,
        angularVelocityRadPerSec: 40.0,
        motionBlurFactor: 0.8,
        rimDepthMeters: 0.05,
        screenCenterX: 300.0,
        screenCenterY: 400.0,
        screenRadiusX: 20.0,
        screenRadiusY: 20.0,
      );

      final int spokes = pool.wheels.computeSpokeEndpointsInPlace(
        spokeCount: 8,
        centerX: 300.0,
        centerY: 400.0,
        radiusX: 20.0,
        radiusY: 20.0,
        baseAngleRadians: 0.0,
      );

      expect(spokes, 8);
      // First spoke at angle 0: inner x = 300 + 20 * 0.16 = 303.2, outer x = 320.0
      expect(pool.wheels.spokeScratchCoords[0], closeTo(303.2, 1e-6));
      expect(pool.wheels.spokeScratchCoords[1], closeTo(400.0, 1e-6));
      expect(pool.wheels.spokeScratchCoords[2], closeTo(320.0, 1e-6));
      expect(pool.wheels.spokeScratchCoords[3], closeTo(400.0, 1e-6));
      expect(pool.wheels.activeCount, 1);
    });

    test('WeatherParticlePoolBuffer spawns, steps, and expires particles in-place', () {
      final RenderObjectPoolManager pool = RenderObjectPoolManager(
        config: const RenderPoolConfig(
          maxRaindrops: 4,
          maxSprayParticles: 2,
          maxDustParticles: 2,
        ),
      );

      final int rainSlot = pool.weatherParticles.spawnParticle(
        kind: WeatherParticlePoolKind.raindrop,
        x: 10.0,
        y: 0.0,
        z: 0.0,
        vx: 0.0,
        vy: 100.0,
        vz: 0.0,
        maxLifetime: 0.5,
      );
      final int spraySlot = pool.weatherParticles.spawnParticle(
        kind: WeatherParticlePoolKind.waterSpray,
        x: 0.0,
        y: 1.0,
        z: 0.0,
        vx: 2.0,
        vy: 4.0,
        vz: -3.0,
        maxLifetime: 0.2,
      );

      expect(rainSlot, 0);
      expect(spraySlot, 1);
      expect(pool.weatherParticles.activeTotal, 2);

      pool.weatherParticles.stepParticles(dtSeconds: 0.1);
      expect(pool.weatherParticles.activeTotal, 2);
      expect(pool.weatherParticles.positions[1], closeTo(10.0, 1e-6)); // rain y = 0 + 100*0.1

      // After another 0.15s, spray (maxLifetime 0.2s) expires, rain (0.5s) remains.
      pool.weatherParticles.stepParticles(dtSeconds: 0.15);
      expect(pool.weatherParticles.activeTotal, 1);
      expect(pool.weatherParticles.activeRaindrops, 1);
      expect(pool.weatherParticles.activeSpray, 0);
    });

    test('ScratchMathPool multiplies 4x4 Float64List matrices and transforms Vector3', () {
      final ScratchMathPool scratch = ScratchMathPool(
        vector3Capacity: 8,
        matrix4Capacity: 4,
      );

      final Float64List a = Float64List(16);
      final Float64List b = Float64List(16);
      final Float64List out = Float64List(16);

      // Identity * translation(3, 4, 5)
      a[0] = 1.0;
      a[5] = 1.0;
      a[10] = 1.0;
      a[15] = 1.0;

      b[0] = 1.0;
      b[5] = 1.0;
      b[10] = 1.0;
      b[12] = 3.0;
      b[13] = 4.0;
      b[14] = 5.0;
      b[15] = 1.0;

      ScratchMathPool.multiplyMatrix4Into(a, 0, b, 0, out, 0);
      final Vector3 pt = scratch.acquireVector3();
      ScratchMathPool.transformPoint3Into(out, 0, 1.0, 2.0, 3.0, pt);

      expect(pt.x, closeTo(4.0, 1e-6));
      expect(pt.y, closeTo(6.0, 1e-6));
      expect(pt.z, closeTo(8.0, 1e-6));
      expect(scratch.vector3HighWaterMark, 1);
    });
  });

  group('RenderObjectPoolInspectorPanel', () {
    for (final Size viewport in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(viewport);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          final RenderObjectPoolManager pool = RenderObjectPoolManager();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                backgroundColor: const Color(0xFF0F1115),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: RenderObjectPoolInspectorPanel(poolManager: pool),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Pula Obiektów 3D (Zero-GC 120 FPS)'), findsOneWidget);
          expect(find.text('0 / 176'), findsOneWidget);

          await tester.tap(find.text('Symuluj Klatkę 176 Kolarzy'));
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('176 / 176'), findsOneWidget);
          expect(find.text('352 / 352'), findsOneWidget);

          await tester.tap(find.text('Wyczyść Pule'));
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('0 / 176'), findsOneWidget);
        },
      );
    }
  });
}
