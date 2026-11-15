// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/engine/rendering3d/road_ribbon_mesh_builder.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

void main() {
  group('RoadRibbonMeshBuilder - Mesh Generation & Geometry', () {
    test('generuje poprawną siatkę 3D wstęgi drogi z wierzchołkami, normalnymi i UV', () {
      const builder = RoadRibbonMeshBuilder();

      final segments = [
        const StageSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 1.0,
          startElevationM: 200.0,
          endElevationM: 210.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 20.0,
          windDirectionDegrees: 180.0,
          roadBearingDegrees: 0.0, // Jazda na północ
          sprintOrKomClassification: SegmentClassification.none,
        ),
      ];

      final mesh = builder.buildRoadRibbonMesh(
        segments: segments,
        windowStartMeters: 0.0,
        windowLengthMeters: 400.0,
      );

      // Siatka nie powinna być pusta
      expect(mesh.vertexCount, greaterThan(0));
      expect(mesh.triangleCount, greaterThan(0));
      expect(mesh.indices.length % 3, equals(0)); // Kompletne trójkąty

      // Liczba wierzchołków musi odpowiadać normalnym i UV
      expect(mesh.normals.length, equals(mesh.vertexCount));
      expect(mesh.uvs.length, equals(mesh.vertexCount));

      // Wektory normalne muszą być jednostkowe
      for (final norm in mesh.normals.take(20)) {
        expect(norm.length, closeTo(1.0, 1e-4));
      }

      // Prostopadłościan AABB musi być poprawny
      expect(mesh.boundingBox.min.y, lessThanOrEqualTo(mesh.boundingBox.max.y));
      expect(mesh.boundingBox.min.z, lessThan(mesh.boundingBox.max.z));
    });

    test('przekrój poprzeczny zachowuje zadaną szerokość jezdni i poboczy', () {
      const config = RoadRibbonBuilderConfig(
        roadWidthMeters: 7.0,
        vergeWidthMeters: 1.5,
      );
      const builder = RoadRibbonMeshBuilder(config: config);

      final segments = [
        const StageSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 0.5,
          startElevationM: 50.0,
          endElevationM: 50.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 10.0,
          windDirectionDegrees: 0.0,
          roadBearingDegrees: 0.0,
          sprintOrKomClassification: SegmentClassification.none,
        ),
      ];

      final mesh = builder.buildRoadRibbonMesh(
        segments: segments,
        windowStartMeters: 0.0,
        windowLengthMeters: 300.0,
      );

      expect(mesh.slices.length, greaterThan(2));

      // Sprawdzenie wymiarów pierwszego przekroju poprzecznego
      final slice = mesh.slices.first;
      final roadWidth = (slice.rightRoadEdge - slice.leftRoadEdge).length;
      expect(roadWidth, closeTo(7.0, 1e-2));

      final leftVergeWidth = (slice.leftRoadEdge - slice.leftVerge).length;
      expect(leftVergeWidth, closeTo(1.5, 0.1));

      final rightVergeWidth = (slice.rightVerge - slice.rightRoadEdge).length;
      expect(rightVergeWidth, closeTo(1.5, 0.1));
    });
  });

  group('RoadRibbonMeshBuilder - Mountain Serpentines & Catmull-Rom Splines', () {
    test('odcinek górski o wysokiej trudności generuje serpentyny z przechyłem poprzecznym', () {
      const builder = RoadRibbonMeshBuilder();

      final mountainSegments = [
        const StageSegment(
          index: 0,
          startKm: 12.0,
          lengthKm: 1.2,
          startElevationM: 1100.0,
          endElevationM: 1220.0, // 10% średniego nachylenia
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 75.0, // Bardzo trudna technicznie wspinaczka (Alpe d'Huez)
          windDirectionDegrees: 90.0,
          roadBearingDegrees: 45.0,
          sprintOrKomClassification: SegmentClassification.cat1,
        ),
      ];

      final mesh = builder.buildRoadRibbonMesh(
        segments: mountainSegments,
        windowStartMeters: 0.0,
        windowLengthMeters: 800.0,
      );

      // Siatka serpentyny powinna mieć gęstsze próbkowanie w łukach
      expect(mesh.slices.length, greaterThan(30));

      // Przynajmniej niektóre wycinki powinny mieć niezerowy przechył poprzeczny (Banking)
      final hasBanking = mesh.slices.any((s) => s.bankingAngle.abs() > 0.02);
      expect(hasBanking, isTrue);

      // Trasa powinna wznosić się w przestrzeni Y
      final firstY = mesh.slices.first.center.y;
      final lastY = mesh.slices.last.center.y;
      expect(lastY, greaterThan(firstY + 20.0));
    });
  });

  group('RoadRibbonMeshBuilder - Painted Mountain Fan Graffiti', () {
    test('na podjazdach górskich generowane są malowane napisy kibiców z hasłami kolarzy', () {
      const builder = RoadRibbonMeshBuilder(
        config: RoadRibbonBuilderConfig(enableMountainGraffiti: true),
      );

      final climbSegments = [
        const StageSegment(
          index: 0,
          startKm: 15.0,
          lengthKm: 2.0,
          startElevationM: 1400.0,
          endElevationM: 1600.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 60.0,
          windDirectionDegrees: 0.0,
          roadBearingDegrees: 0.0,
          sprintOrKomClassification: SegmentClassification.horsCategorie,
        ),
      ];

      final mesh = builder.buildRoadRibbonMesh(
        segments: climbSegments,
        windowStartMeters: 0.0,
        windowLengthMeters: 600.0,
      );

      // Na podjeździe HC powinno powstać co najmniej kilka napisów kibiców
      expect(mesh.graffitiDecals.length, greaterThan(3));

      // Napisy powinny zawierać znane hasła
      final texts = mesh.graffitiDecals.map((d) => d.text).toList();
      expect(texts.any((t) => t.contains('TADEJ') || t.contains('JONAS') || t.contains('POLSKA')), isTrue);

      // Każda kalkomania musi składać się z 4 wierzchołków czworokąta
      for (final decal in mesh.graffitiDecals) {
        expect(decal.quadVertices.length, equals(4));
        expect(decal.quadUvs.length, equals(4));
        // Pozycja kalkomanii lekko uniesiona nad asfalt (brak z-fightingu)
        expect(decal.positionWorld.y, greaterThanOrEqualTo(mesh.slices.first.center.y));
      }
    });

    test('na płaskich nizinnych etapach bez podjazdów napisy kibiców nie są generowane', () {
      const builder = RoadRibbonMeshBuilder(
        config: RoadRibbonBuilderConfig(enableMountainGraffiti: true),
      );

      final flatSegments = [
        const StageSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 2.0,
          startElevationM: 50.0,
          endElevationM: 52.0, // Płasko
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 10.0,
          windDirectionDegrees: 0.0,
          roadBearingDegrees: 0.0,
          sprintOrKomClassification: SegmentClassification.none,
        ),
      ];

      final mesh = builder.buildRoadRibbonMesh(
        segments: flatSegments,
        windowStartMeters: 0.0,
        windowLengthMeters: 500.0,
      );

      expect(mesh.graffitiDecals, isEmpty);
    });
  });

  group('RoadRibbonMeshBuilder - PBR Materials & Shading Properties', () {
    test('mokry asfalt w deszczu ma zredukowaną chropowatość, wysokie odbicia i ciemniejszy odcień', () {
      const segment = StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 1.0,
        startElevationM: 100.0,
        endElevationM: 100.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 15.0,
        windDirectionDegrees: 0.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.none,
      );

      final dryMat = RoadSurfaceMaterialProperties.fromSegment(
        segment: segment,
        weather: WeatherCondition.sunny,
      );

      final wetMat = RoadSurfaceMaterialProperties.fromSegment(
        segment: segment,
        weather: WeatherCondition.heavyStorm,
      );

      expect(dryMat.isWet, isFalse);
      expect(wetMat.isWet, isTrue);

      // Mokry asfalt ma znacznie niższą chropowatość (lustrzane odbicia)
      expect(wetMat.roughness, lessThan(dryMat.roughness));
      // Mokry asfalt ma wysokie odbicia zwierciadlane (specular)
      expect(wetMat.specular, greaterThan(dryMat.specular));
      // Mokry asfalt tworzy kałuże
      expect(wetMat.puddleFactor, greaterThan(0.5));
    });

    test('bruk Paris-Roubaix ma bardzo wysoką chropowatość i parametr wypukłości bump', () {
      const cobbleSegment = StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 2.4,
        startElevationM: 80.0,
        endElevationM: 80.0,
        surfaceType: SegmentSurfaceType.cobblestonesSector4,
        technicalDifficulty: 90.0,
        windDirectionDegrees: 0.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.none,
      );

      final cobbleMat = RoadSurfaceMaterialProperties.fromSegment(
        segment: cobbleSegment,
        weather: WeatherCondition.sunny,
      );

      expect(cobbleMat.bumpScale, greaterThan(0.85));
      expect(cobbleMat.roughness, greaterThan(0.80));
    });

    test('szuter toskański Strade Bianche ma jasny odcień kredy i wysoką chropowatość', () {
      const gravelSegment = StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 5.0,
        startElevationM: 250.0,
        endElevationM: 280.0,
        surfaceType: SegmentSurfaceType.gravelStrade,
        technicalDifficulty: 65.0,
        windDirectionDegrees: 0.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.none,
      );

      final gravelMat = RoadSurfaceMaterialProperties.fromSegment(
        segment: gravelSegment,
        weather: WeatherCondition.sunny,
      );

      // Jasny odcień kredowo-piaskowy
      expect(gravelMat.baseColorHex.toUpperCase(), contains('D1C4B2'));
      expect(gravelMat.roughness, greaterThan(0.90));
    });
  });
}
