import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import 'package:pro_peloton_manager/engine/events/road_hazards_and_spectator_incidents.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:pro_peloton_manager/engine/rendering3d/traffic_islands_and_railway_3d_renderer.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

RaceStage _buildTestStage() {
  return const RaceStage(
    id: 'stage_test_337',
    stageNumber: 1,
    name: 'Roubaix - Lille',
    stageType: StageType.flat,
    baseTemperatureCelsius: 18.0,
    weatherCondition: WeatherCondition.overcast,
    windSpeedKmh: 16.0,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 20.0,
        startElevationM: 40.0,
        endElevationM: 45.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 45.0,
        windDirectionDegrees: 270.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.finishLine,
      ),
    ],
  );
}

void main() {
  group('TrafficIslandsAndRailway3dRenderer', () {
    test('spawnForStage builds islands, speed bumps, railways and marshal motos', () {
      final renderer = TrafficIslandsAndRailway3dRenderer();
      final stage = _buildTestStage();

      final pack = renderer.spawnForStage(stage);
      expect(pack.stageId, stage.id);
      expect(pack.isEmpty, isFalse);
      expect(pack.islands.length, greaterThanOrEqualTo(3));
      expect(pack.speedBumps.length, greaterThanOrEqualTo(2));
      expect(pack.railwayCrossings.length, greaterThanOrEqualTo(1));
      expect(pack.marshalMotos.length, greaterThanOrEqualTo(3));

      // Weryfikacja znaków nakazu jazdy z prawej/lewej strony
      expect(
        pack.islands.any(
          (i) => i.passDirection == TrafficIslandPassDirection.passRight,
        ),
        isTrue,
      );
      expect(
        pack.islands.any(
          (i) => i.passDirection == TrafficIslandPassDirection.passLeft,
        ),
        isTrue,
      );
    });

    test('spawnForStage maps RoadHazardZone islands and railway crossings', () {
      final renderer = TrafficIslandsAndRailway3dRenderer();
      final stage = _buildTestStage();

      final zones = [
        const RoadHazardZone(
          id: 'hz_island_1',
          type: RoadHazardType.trafficIslandBottleneck,
          kilometerMark: 16.5,
          distanceToFinishKm: 3.5,
          hasYellowCones: true,
          severity: HazardSeverityLevel.high,
          descriptionPl: 'Wysepka z pachołkami',
          radioWarningPl: 'Uwaga wysepka!',
        ),
        const RoadHazardZone(
          id: 'hz_rail_1',
          type: RoadHazardType.railwayLevelCrossing,
          kilometerMark: 10.2,
          distanceToFinishKm: 9.8,
          railwayBarrierState: RailwayBarrierState.closing,
          severity: HazardSeverityLevel.critical,
          descriptionPl: 'Przejazd kolejowy TGV',
          radioWarningPl: 'Szlaban się zamyka!',
        ),
      ];

      final pack = renderer.spawnForStage(stage, hazardZones: zones);
      expect(pack.islands.length, 1);
      expect(pack.railwayCrossings.length, 1);
      expect(pack.railwayCrossings.first.barrierState,
          RailwayBarrierState.closing);
      expect(pack.railwayCrossings.first.lightsActive, isTrue);
      expect(pack.marshalMotos.length, 2);
      expect(pack.marshalMotos.first.isWarningActive, isTrue);
    });

    test('render projects visible elements and reports accurate telemetry', () {
      final renderer = TrafficIslandsAndRailway3dRenderer();
      final projection = Scene3DMathProjection(
        viewportWidth: 1280.0,
        viewportHeight: 720.0,
      );
      projection.setView(
        eye: Vector3(0.0, 4.5, -18.0),
        target: Vector3(0.0, 1.0, 40.0),
      );

      final pack = StageTrafficIslandsAndRailwayPack(
        stageId: 'render_test',
        islands: [
          TrafficIsland3D(
            id: 'isl_right',
            worldPosition: Vector3(0.0, 0.0, 25.0),
            tangent: Vector3(0.0, 0.0, 1.0),
            lateralRight: Vector3(1.0, 0.0, 0.0),
            surfaceNormal: Vector3(0.0, 1.0, 0.0),
            distanceAlongCourseMeters: 25.0,
            passDirection: TrafficIslandPassDirection.passRight,
          ),
          TrafficIsland3D(
            id: 'isl_either',
            worldPosition: Vector3(0.0, 0.0, 80.0),
            tangent: Vector3(0.0, 0.0, 1.0),
            lateralRight: Vector3(1.0, 0.0, 0.0),
            surfaceNormal: Vector3(0.0, 1.0, 0.0),
            distanceAlongCourseMeters: 80.0,
            passDirection: TrafficIslandPassDirection.passEitherSide,
          ),
        ],
        speedBumps: [
          SpeedBump3D(
            id: 'bump_1',
            worldPosition: Vector3(0.0, 0.0, 14.0),
            tangent: Vector3(0.0, 0.0, 1.0),
            lateralRight: Vector3(1.0, 0.0, 0.0),
            surfaceNormal: Vector3(0.0, 1.0, 0.0),
            distanceAlongCourseMeters: 14.0,
          ),
        ],
        railwayCrossings: [
          RailwayCrossing3D(
            id: 'rail_1',
            worldPosition: Vector3(0.0, 0.0, 45.0),
            tangent: Vector3(0.0, 0.0, 1.0),
            lateralRight: Vector3(1.0, 0.0, 0.0),
            surfaceNormal: Vector3(0.0, 1.0, 0.0),
            distanceAlongCourseMeters: 45.0,
            barrierState: RailwayBarrierState.warningLightsFlashing,
            barrierClosureProgress: 0.45,
            lightsActive: true,
          ),
        ],
        marshalMotos: [
          CommissaireMarshalMoto3D(
            id: 'moto_1',
            worldPosition: Vector3(2.0, 0.0, 18.0),
            tangent: Vector3(0.0, 0.0, 1.0),
            lateralRight: Vector3(1.0, 0.0, 0.0),
            surfaceNormal: Vector3(0.0, 1.0, 0.0),
            distanceAlongCourseMeters: 18.0,
            isWarningActive: true,
          ),
        ],
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      renderer.stepAnimation(0.25);

      final telemetry = renderer.render(
        canvas: canvas,
        viewportSize: const Size(1280.0, 720.0),
        projection: projection,
        pack: pack,
        cameraDistanceMeters: 0.0,
      );
      recorder.endRecording();

      expect(telemetry.visibleIslandsCount, 2);
      expect(telemetry.visibleSpeedBumpsCount, 1);
      expect(telemetry.visibleRailwaysCount, 1);
      expect(telemetry.visibleMarshalMotosCount, 1);
      expect(telemetry.activeRedLightsCount, 1);
      expect(telemetry.activeWhistleAlertsCount, 1);
      expect(telemetry.nearestHazardDistanceMeters, 14.0);

      // Wyłączenie warstwy zeruje liczniki
      renderer.config = renderer.config.copyWith(enabled: false);
      final rec2 = ui.PictureRecorder();
      final telDisabled = renderer.render(
        canvas: Canvas(rec2),
        viewportSize: const Size(1280.0, 720.0),
        projection: projection,
        pack: pack,
        cameraDistanceMeters: 0.0,
      );
      rec2.endRecording();
      expect(telDisabled.visibleIslandsCount, 0);
      expect(telDisabled.visibleMarshalMotosCount, 0);
    });
  });

  group('TrafficIslandsAndRailwayControlPanel & Painter UI', () {
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

          TrafficIslandsAndRailwayConfig config =
              const TrafficIslandsAndRailwayConfig();
          RailwayBarrierState railState =
              RailwayBarrierState.warningLightsFlashing;

          final renderer = TrafficIslandsAndRailway3dRenderer();
          final projection = Scene3DMathProjection(
            viewportWidth: viewport.width,
            viewportHeight: 240.0,
          );
          projection.setView(
            eye: Vector3(0.0, 4.0, -15.0),
            target: Vector3(0.0, 1.0, 30.0),
          );
          final pack = renderer.spawnForStage(_buildTestStage());

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                backgroundColor: const Color(0xFF0F1115),
                body: StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      children: [
                        SizedBox(
                          width: viewport.width,
                          height: 220.0,
                          child: CustomPaint(
                            painter: TrafficIslandsAndRailway3dPainter(
                              renderer: renderer,
                              projection: projection,
                              pack: pack,
                              cameraDistanceMeters: 16300.0,
                              elapsedTimeSeconds: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: TrafficIslandsAndRailwayControlPanel(
                              config: config,
                              railwayState: railState,
                              telemetry: const TrafficIslandsAndRailwayTelemetry(
                                visibleIslandsCount: 2,
                                visibleSpeedBumpsCount: 1,
                                visibleRailwaysCount: 1,
                                visibleMarshalMotosCount: 2,
                                activeRedLightsCount: 1,
                                activeWhistleAlertsCount: 2,
                                nearestHazardDistanceMeters: 42.0,
                              ),
                              onConfigChanged: (next) =>
                                  setState(() => config = next),
                              onRailwayStateChanged: (next) =>
                                  setState(() => railState = next),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Wysepki, Tory i Moto Sędziowie 3D'), findsOneWidget);
          expect(find.text('42 m'), findsOneWidget);

          // Przełączenie stanu szlabanu
          await tester.tap(find.text('Szlaban zamknięty'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(railState, RailwayBarrierState.closed);

          // Przełączenie warstwy
          await tester.tap(find.text('Moto: gwizdek + flaga'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(config.showMarshalMotos, isFalse);
        },
      );
    }
  });
}
