import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/asphalt_chalk_graffiti_renderer.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

RaceStage _buildMountainTestStage() {
  return const RaceStage(
    id: 'stage_alpe',
    stageNumber: 14,
    name: 'Saint-Jean-de-Maurienne - Alpe d\'Huez',
    stageType: StageType.summitFinish,
    baseTemperatureCelsius: 22.0,
    weatherCondition: WeatherCondition.sunny,
    windSpeedKmh: 12.0,
    segments: <StageSegment>[
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 20.0,
        startElevationM: 550.0,
        endElevationM: 600.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 15.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 1,
        startKm: 20.0,
        lengthKm: 5.0,
        startElevationM: 600.0,
        endElevationM: 900.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 45.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.cat2,
      ),
      StageSegment(
        index: 2,
        startKm: 25.0,
        lengthKm: 6.0,
        startElevationM: 900.0,
        endElevationM: 1410.0,
        surfaceType: SegmentSurfaceType.roughAsphalt,
        technicalDifficulty: 65.0,
        windDirectionDegrees: 210.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.cat1,
      ),
      StageSegment(
        index: 3,
        startKm: 31.0,
        lengthKm: 8.0,
        startElevationM: 1410.0,
        endElevationM: 2120.0,
        surfaceType: SegmentSurfaceType.roughAsphalt,
        technicalDifficulty: 80.0,
        windDirectionDegrees: 240.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      ),
    ],
  );
}

Scene3DMathProjection _buildTestProjection({
  required double cameraDistM,
  required double gradientPercent,
  Size viewport = const Size(1280.0, 720.0),
}) {
  final RoadGeometryParameters road = RoadGeometryParameters(
    gradientPercent: gradientPercent,
    roadWidthMeters: 7.2,
  );
  double elev(double d) => d * (gradientPercent / 100.0);

  final Cyclist3DPose anchor = Scene3DMathProjection.courseToCyclistPose(
    coursePosition: CoursePosition(
      distanceMeters: cameraDistM,
      lateralOffsetMeters: 0.0,
      elevationMeters: elev(cameraDistM),
    ),
    roadGeometry: road,
  );

  final Scene3DMathProjection proj = Scene3DMathProjection(
    viewportWidth: viewport.width,
    viewportHeight: viewport.height,
  );
  proj.setView(
    eye: anchor.position + anchor.surfaceNormal * 3.5 - anchor.tangent * 2.0,
    target: anchor.position + anchor.tangent * 30.0,
    up: Vector3(0.0, 1.0, 0.0),
  );
  return proj;
}

void main() {
  group('AsphaltChalkGraffitiRenderer', () {
    test('wykrywa wyłącznie strefy Cat 1 oraz HC z etapów górskich', () {
      final RaceStage stage = _buildMountainTestStage();
      final List<AsphaltGraffitiClimbZone> zones =
          AsphaltChalkGraffitiRenderer.detectMountainClimbZones(stage);

      expect(zones.length, 2);
      expect(zones[0].classification, SegmentClassification.cat1);
      expect(zones[0].startDistanceMeters, 25000.0);
      expect(zones[0].endDistanceMeters, 31000.0);
      expect(zones[1].classification, SegmentClassification.horsCategorie);
      expect(zones[1].startDistanceMeters, 31000.0);
      expect(zones[1].endDistanceMeters, 39000.0);
    });

    test('ekstrahuje poprawnie nazwiska wieloczłonowe i puste ciągi', () {
      expect(
        AsphaltChalkGraffitiRenderer.extractRiderSurname('Tadej Pogačar'),
        'POGAČAR',
      );
      expect(
        AsphaltChalkGraffitiRenderer.extractRiderSurname('Mathieu van der Poel'),
        'VAN DER POEL',
      );
      expect(
        AsphaltChalkGraffitiRenderer.extractRiderSurname('   '),
        '',
      );
    });

    test('generuje deterministycznie ALLEZ!, VAI!, GO! oraz nazwisko lidera GC i faworytów', () {
      const AsphaltChalkGraffitiRenderer renderer =
          AsphaltChalkGraffitiRenderer();
      const AsphaltGraffitiClimbZone hcZone = AsphaltGraffitiClimbZone(
        id: 'hc_alpe',
        name: 'Alpe d\'Huez HC',
        startDistanceMeters: 0.0,
        endDistanceMeters: 1200.0,
        classification: SegmentClassification.horsCategorie,
        averageGradientPercent: 9.2,
        maxGradientPercent: 13.0,
      );

      final List<AsphaltChalkGraffitiDecal> decalsA =
          renderer.generateDecalsForZone(
        zone: hcZone,
        elevationAtDistance: (double d) => d * 0.092,
        gcLeaderName: 'Tadej Pogačar',
        stageFavoriteNames: const <String>[
          'Jonas Vingegaard',
          'Remco Evenepoel',
        ],
      );
      final List<AsphaltChalkGraffitiDecal> decalsB =
          renderer.generateDecalsForZone(
        zone: hcZone,
        elevationAtDistance: (double d) => d * 0.092,
        gcLeaderName: 'Tadej Pogačar',
        stageFavoriteNames: const <String>[
          'Jonas Vingegaard',
          'Remco Evenepoel',
        ],
      );

      expect(decalsA.length, decalsB.length);
      expect(decalsA.length, greaterThan(20));

      final List<String> texts = decalsA.map((d) => d.text).toList();
      expect(texts, contains('ALLEZ!'));
      expect(texts, contains('VAI!'));
      expect(texts, contains('GO!'));
      expect(texts.any((t) => t.contains('POGAČAR')), isTrue);
      expect(
        texts.any((t) => t.contains('VINGEGAARD') || t.contains('EVENEPOEL')),
        isTrue,
      );
    });

    test('rzutuje napis w perspektywie 3D na powierzchnię asfaltu z poprawną homografią', () {
      const AsphaltChalkGraffitiRenderer renderer =
          AsphaltChalkGraffitiRenderer();
      const RoadGeometryParameters road = RoadGeometryParameters(
        gradientPercent: 9.5,
        roadWidthMeters: 7.2,
      );
      final Scene3DMathProjection projection = _buildTestProjection(
        cameraDistM: 100.0,
        gradientPercent: 9.5,
      );

      const AsphaltChalkGraffitiDecal decal = AsphaltChalkGraffitiDecal(
        id: 'test_decal',
        text: 'ALLEZ!',
        category: AsphaltGraffitiCategory.iconicSlogan,
        medium: AsphaltGraffitiMedium.latexPaint,
        distanceMeters: 122.0,
        lateralOffsetMeters: 0.0,
        elevationMeters: 122.0 * 0.095,
        widthMeters: 2.8,
        heightMeters: 1.0,
        yawAngleRadians: 0.05,
        primaryColor: Color(0xFFFACC15),
        outlineColor: Color(0xFF0F1115),
        weatheringOpacity: 0.95,
        tireWearSeed: 42,
        climbClassification: SegmentClassification.horsCategorie,
      );

      final ProjectedGraffitiDecal? projected = renderer.projectDecalToScreen(
        decal: decal,
        viewportSize: const Size(1280.0, 720.0),
        projection: projection,
        roadGeometry: road,
      );

      expect(projected, isNotNull);
      expect(projected!.depthEye, greaterThan(10.0));
      expect(projected.effectiveOpacity, greaterThan(0.3));
      expect(projected.homographyMatrix4.length, 16);
      // Rzutowane narożniki na górze napisu (dalej od kamery) mają mniejszą szerokość ekranową niż dół
      final double topWidth = (projected.topRight - projected.topLeft).distance;
      final double bottomWidth =
          (projected.bottomRight - projected.bottomLeft).distance;
      expect(topWidth, lessThan(bottomWidth));
    });

    test('renderuje napisy na Canvas i raportuje poprawną telemetrię', () {
      const AsphaltChalkGraffitiRenderer renderer =
          AsphaltChalkGraffitiRenderer();
      const RoadGeometryParameters road = RoadGeometryParameters(
        gradientPercent: 10.0,
        roadWidthMeters: 7.2,
      );
      final Scene3DMathProjection projection = _buildTestProjection(
        cameraDistM: 25000.0,
        gradientPercent: 10.0,
      );

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      final AsphaltChalkGraffitiTelemetry telemetry = renderer.paint(
        canvas: canvas,
        size: const Size(1280.0, 720.0),
        projection: projection,
        roadGeometry: road,
        cameraCourseDistanceMeters: 25000.0,
        elevationAtDistance: (double d) => d * 0.10,
        fallbackClassification: SegmentClassification.horsCategorie,
        gcLeaderName: 'Tadej Pogačar',
        stageFavoriteNames: const <String>['Jonas Vingegaard'],
      );

      recorder.endRecording();

      expect(telemetry.isActiveZone, isTrue);
      expect(
        telemetry.activeClimbClassification,
        SegmentClassification.horsCategorie,
      );
      expect(telemetry.renderedDecalsCount, greaterThan(0));
      expect(telemetry.averageDepthMeters, greaterThan(0.0));
    });

    test('nie generuje ani nie renderuje napisów gdy wyłączone lub poza Cat1/HC', () {
      const AsphaltChalkGraffitiRenderer disabledRenderer =
          AsphaltChalkGraffitiRenderer(
        config: AsphaltChalkGraffitiConfig(enabled: false),
      );
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      final AsphaltChalkGraffitiTelemetry telemetry = disabledRenderer.paint(
        canvas: canvas,
        size: const Size(1280.0, 720.0),
        projection: _buildTestProjection(cameraDistM: 0.0, gradientPercent: 9.0),
        roadGeometry: const RoadGeometryParameters(gradientPercent: 9.0),
        cameraCourseDistanceMeters: 0.0,
        elevationAtDistance: (double d) => d * 0.09,
        fallbackClassification: SegmentClassification.horsCategorie,
      );
      recorder.endRecording();

      expect(telemetry.isActiveZone, isFalse);
      expect(telemetry.renderedDecalsCount, 0);
    });
  });

  group('AsphaltChalkGraffitiControlPanel responsywność', () {
    for (final Size screenSize in const <Size>[
      Size(390.0, 844.0),
      Size(1024.0, 768.0),
      Size(1600.0, 900.0),
    ]) {
      testWidgets(
        'renderuje się bez przepełnień w ${screenSize.width.toInt()}x${screenSize.height.toInt()}',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(screenSize);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: AsphaltChalkGraffitiControlPanel(),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.textContaining('Napisy na Asfalcie 3D'), findsOneWidget);
          expect(find.text('POGAČAR'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('przełącza tryb aktywny oraz kategorię podjazdu Cat 1 / HC',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280.0, 800.0));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      AsphaltChalkGraffitiConfig? latestConfig;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AsphaltChalkGraffitiControlPanel(
                onConfigChanged: (AsphaltChalkGraffitiConfig cfg) {
                  latestConfig = cfg;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Kategoria 1 (Cat 1)'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.textContaining('CAT 1'), findsOneWidget);

      await tester.tap(find.text('Aktywne'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(latestConfig?.enabled, isFalse);
      expect(find.text('Wyłączone'), findsOneWidget);
    });
  });
}
