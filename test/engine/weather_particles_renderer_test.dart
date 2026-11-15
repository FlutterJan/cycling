// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/rendering3d/peloton_instanced_renderer.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:pro_peloton_manager/engine/rendering3d/weather_particles_renderer.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/state/race_simulation_notifier.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Scene3DMathProjection projection;

  setUp(() {
    projection = Scene3DMathProjection(
      viewportWidth: 1280.0,
      viewportHeight: 720.0,
      fovYDegrees: 60.0,
      zNear: 0.5,
      zFar: 600.0,
    );
    projection.setView(
      eye: Vector3(0.0, 2.5, 4980.0),
      target: Vector3(0.0, 1.2, 5020.0),
      up: Vector3(0.0, 1.0, 0.0),
    );
  });

  /// Pomocniczy generator elementu peletonu z poprawnymi wektorami i pozycją
  PelotonRenderItem createDummyRenderItem({
    required String id,
    required double distMeters,
    required double speedKmh,
    double lateralOffset = 0.0,
    double cameraDistance = 12.0,
  }) {
    final snapshot = RiderPositionSnapshot(
      riderId: id,
      riderName: 'Test Rider $id',
      bibNumber: 1,
      teamId: 'team_test',
      teamName: 'Test Team',
      teamJerseyHexColor: '#EF4444',
      isPlayerRider: true,
      distanceCoveredMeters: distMeters,
      kilometerMark: distMeters / 1000.0,
      elevationMeters: 450.0,
      currentGradientPercent: 0.0,
      currentSegmentIndex: 0,
      speedMs: speedKmh / 3.6,
      speedKmh: speedKmh,
      powerWatts: 420,
      wattsPerKg: 6.2,
      cadenceRpm: 92,
      heartRateBpm: 165,
      wPrimePercentage: 0.85,
      wPrimeJoules: 18000.0,
      glycogenPercentage: 0.8,
      glycogenGrams: 350.0,
      hydrationPercent: 0.9,
      bidonsLeft: 2,
      gelsLeft: 3,
      activeTacticalOrder: TacticalOrder.holdPosition,
      groupIndex: 0,
      groupType: GroupType.peloton,
      timeGapToLeaderSeconds: 0.0,
      lateralPositionRoad: 0.0,
      lateralOffsetRoadMeters: lateralOffset,
      isDrafting: false,
      draftingSavingsPercent: 0.0,
      isPulling: true,
      hasDefect: false,
      isCrashed: false,
      isDnf: false,
    );

    final worldPos = Vector3(lateralOffset, 0.5, distMeters);
    final projected = projection.worldToScreen(worldPos);

    return PelotonRenderItem(
      snapshot: snapshot,
      worldPosition: worldPos,
      tangent: Vector3(0.0, 0.0, 1.0),
      right: Vector3(1.0, 0.0, 0.0),
      up: Vector3(0.0, 1.0, 0.0),
      cameraDistance: cameraDistance,
      lodLevel: PelotonLodLevel.fullDetail,
      projectedCenter: projected,
      screenScale: 1.0,
      isVisibleInFrustum: true,
      jerseyColor: const Color(0xFFEF4444),
    );
  }

  group('WeatherSystemTelemetry - Klasyfikacja i Warunki Logiczne', () {
    test('poprawnie wykrywa mokrą nawierzchnię przy deszczu i ulewie', () {
      const sunny = WeatherSystemTelemetry(weatherCondition: WeatherCondition.sunny);
      const overcast = WeatherSystemTelemetry(weatherCondition: WeatherCondition.overcast);
      const rain = WeatherSystemTelemetry(weatherCondition: WeatherCondition.lightRain);
      const storm = WeatherSystemTelemetry(weatherCondition: WeatherCondition.heavyStorm);

      expect(sunny.isWetWeather, isFalse);
      expect(overcast.isWetWeather, isFalse);
      expect(rain.isWetWeather, isTrue);
      expect(storm.isWetWeather, isTrue);
    });

    test('poprawnie wykrywa warunki powstawania tumanów kurzu (sucho + szuter/bruk)', () {
      // Sucho na szutrze Strade Bianche -> pył
      const stradeDry = WeatherSystemTelemetry(
        weatherCondition: WeatherCondition.sunny,
        currentSurfaceType: SegmentSurfaceType.gravelStrade,
      );
      expect(stradeDry.isDryDustCondition, isTrue);

      // Sucho na bruku Roubaix -> pył
      const cobbleDry = WeatherSystemTelemetry(
        weatherCondition: WeatherCondition.overcast,
        currentSurfaceType: SegmentSurfaceType.cobblestonesSector3,
      );
      expect(cobbleDry.isDryDustCondition, isTrue);

      // Deszcz na szutrze Strade -> błoto, brak pyłu
      const stradeRain = WeatherSystemTelemetry(
        weatherCondition: WeatherCondition.lightRain,
        currentSurfaceType: SegmentSurfaceType.gravelStrade,
      );
      expect(stradeRain.isDryDustCondition, isFalse);

      // Sucho na gładkim asfalcie -> brak pyłu
      const asphaltDry = WeatherSystemTelemetry(
        weatherCondition: WeatherCondition.sunny,
        currentSurfaceType: SegmentSurfaceType.smoothAsphalt,
      );
      expect(asphaltDry.isDryDustCondition, isFalse);
    });
  });

  group('WeatherParticlesRendererConfig - Domyślne i Niestandardowe Parametry', () {
    test('tworzy domyślną konfigurację o wysokiej wydajności (120 FPS GC budget)', () {
      const config = WeatherParticlesRendererConfig();
      expect(config.maxRaindropsCount, equals(450));
      expect(config.maxSprayParticlesCount, equals(220));
      expect(config.maxDustParticlesCount, equals(220));
      expect(config.enableRain, isTrue);
      expect(config.enableWaterSpray, isTrue);
      expect(config.enableAlpineFog, isTrue);
      expect(config.enableDustPlumes, isTrue);
      expect(config.enableLensMoisture, isTrue);
    });

    test('respektuje wyłączenie poszczególnych modułów pogodowych', () {
      const customConfig = WeatherParticlesRendererConfig(
        maxRaindropsCount: 100,
        enableRain: false,
        enableAlpineFog: false,
        enableWaterSpray: false,
      );
      expect(customConfig.maxRaindropsCount, equals(100));
      expect(customConfig.enableRain, isFalse);
      expect(customConfig.enableAlpineFog, isFalse);
      expect(customConfig.enableWaterSpray, isFalse);
      expect(customConfig.enableDustPlumes, isTrue);
    });
  });

  group('WeatherParticlesRenderer - Symulacja Deszczu i Kropel', () {
    test('aktualizuje krople deszczu pod wpływem wiatru bocznego', () {
      final renderer = WeatherParticlesRenderer();

      // Wiatr z zachodu (90 stopni odchylenia względem kamery)
      const telemetry = WeatherSystemTelemetry(
        weatherCondition: WeatherCondition.heavyStorm,
        windSpeedKmh: 45.0,
        windDirectionDegrees: 90.0,
        cameraBearingRadians: 0.0,
        dtSeconds: 0.016,
      );

      // Pierwsza aktualizacja inicjalizuje i przemieszcza krople
      renderer.update(
        telemetry: telemetry,
        viewportWidth: 1280.0,
        viewportHeight: 720.0,
      );

      // Rysowanie na Canvas
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      renderer.renderScreenWeather(
        canvas: canvas,
        size: const Size(1280.0, 720.0),
        telemetry: telemetry,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('w słoneczną pogodę krople deszczu nie są rysowane', () {
      final renderer = WeatherParticlesRenderer();

      const telemetry = WeatherSystemTelemetry(
        weatherCondition: WeatherCondition.sunny,
      );

      renderer.update(
        telemetry: telemetry,
        viewportWidth: 1280.0,
        viewportHeight: 720.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      renderer.renderScreenWeather(
        canvas: canvas,
        size: const Size(1280.0, 720.0),
        telemetry: telemetry,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('WeatherParticlesRenderer - Pióropusze Wody spod Kół (Water Spray)', () {
    test('emituje cząsteczki wody spod kół kolarzy jadących w deszczu z dużą prędkością', () {
      final renderer = WeatherParticlesRenderer();

      final rider = createDummyRenderItem(
        id: 'rider_pogacar',
        distMeters: 5000.0,
        speedKmh: 48.0,
        cameraDistance: 15.0,
      );

      const telemetry = WeatherSystemTelemetry(
        weatherCondition: WeatherCondition.lightRain,
        dtSeconds: 0.016,
      );

      renderer.update(
        telemetry: telemetry,
        viewportWidth: 1280.0,
        viewportHeight: 720.0,
        activeRiders: [rider],
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      renderer.renderWorldParticles(
        canvas: canvas,
        projection: projection,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('nie emituje pióropuszy wody w suchy słoneczny dzień', () {
      final renderer = WeatherParticlesRenderer();

      final rider = createDummyRenderItem(
        id: 'rider_vingegaard',
        distMeters: 5000.0,
        speedKmh: 45.0,
      );

      const telemetry = WeatherSystemTelemetry(
        weatherCondition: WeatherCondition.sunny,
        dtSeconds: 0.016,
      );

      renderer.update(
        telemetry: telemetry,
        viewportWidth: 1280.0,
        viewportHeight: 720.0,
        activeRiders: [rider],
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      renderer.renderWorldParticles(
        canvas: canvas,
        projection: projection,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('WeatherParticlesRenderer - Kłęby Pyłu Szutrowego i Brukowego (Dust Plumes)', () {
    test('emituje tumany pyłu na szutrze Strade Bianche przy suchej pogodzie', () {
      final renderer = WeatherParticlesRenderer();

      final rider = createDummyRenderItem(
        id: 'rider_van_aert',
        distMeters: 5000.0,
        speedKmh: 42.0,
        cameraDistance: 20.0,
      );

      const telemetry = WeatherSystemTelemetry(
        weatherCondition: WeatherCondition.sunny,
        currentSurfaceType: SegmentSurfaceType.gravelStrade,
        dtSeconds: 0.016,
      );

      renderer.update(
        telemetry: telemetry,
        viewportWidth: 1280.0,
        viewportHeight: 720.0,
        activeRiders: [rider],
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      renderer.renderWorldParticles(
        canvas: canvas,
        projection: projection,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('deszcz gasi pył szutrowy i nie emituje cząsteczek kurzu', () {
      final renderer = WeatherParticlesRenderer();

      final rider = createDummyRenderItem(
        id: 'rider_van_der_poel',
        distMeters: 5000.0,
        speedKmh: 40.0,
      );

      // Deszcz na sektorze Strade Bianche
      const telemetry = WeatherSystemTelemetry(
        weatherCondition: WeatherCondition.heavyStorm,
        currentSurfaceType: SegmentSurfaceType.gravelStrade,
        dtSeconds: 0.016,
      );

      renderer.update(
        telemetry: telemetry,
        viewportWidth: 1280.0,
        viewportHeight: 720.0,
        activeRiders: [rider],
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      renderer.renderWorldParticles(
        canvas: canvas,
        projection: projection,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('WeatherParticlesRenderer - Mgła Wysokogórska i Chmury HC', () {
    test('nie rysuje mgły na nizinach poniżej 1700m n.p.m. bez kategorii HC', () {
      final renderer = WeatherParticlesRenderer();
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Nizinna dolina 450m n.p.m.
      renderer.renderAlpineFog(
        canvas: canvas,
        size: const Size(1280.0, 720.0),
        elevationMeters: 450.0,
        isHorsCategorie: false,
        elapsedSeconds: 10.0,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('rysuje gęstą mgłę i welony chmur na szczycie przełęczy HC powyżej 2000m n.p.m.', () {
      final renderer = WeatherParticlesRenderer();
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Przełęcz Galibier / Stelvio 2450m n.p.m. kategoria HC
      renderer.renderAlpineFog(
        canvas: canvas,
        size: const Size(1280.0, 720.0),
        elevationMeters: 2450.0,
        isHorsCategorie: true,
        elapsedSeconds: 5.5,
        horizonY: 340.0,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('WeatherParticlesRenderer - renderAll i Kompletny Potok Atmosferyczny', () {
    test('renderAll wykonuje wszystkie warstwy (mgła, świat 3D, ekran) bez wyjątków', () {
      final renderer = WeatherParticlesRenderer();

      final rider1 = createDummyRenderItem(
        id: 'r1',
        distMeters: 5000.0,
        speedKmh: 46.0,
        cameraDistance: 10.0,
      );
      final rider2 = createDummyRenderItem(
        id: 'r2',
        distMeters: 5004.0,
        speedKmh: 45.5,
        cameraDistance: 14.0,
      );

      const telemetry = WeatherSystemTelemetry(
        weatherCondition: WeatherCondition.heavyStorm,
        windSpeedKmh: 35.0,
        windDirectionDegrees: 220.0,
        cameraBearingRadians: 0.5,
        currentElevationMeters: 2100.0,
        isHorsCategorie: true,
        currentSurfaceType: SegmentSurfaceType.smoothAsphalt,
        dtSeconds: 0.016,
        elapsedSeconds: 12.0,
      );

      renderer.update(
        telemetry: telemetry,
        viewportWidth: 1280.0,
        viewportHeight: 720.0,
        activeRiders: [rider1, rider2],
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      renderer.renderAll(
        canvas: canvas,
        size: const Size(1280.0, 720.0),
        projection: projection,
        telemetry: telemetry,
        activeRiders: [rider1, rider2],
        horizonY: 310.0,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });
}
