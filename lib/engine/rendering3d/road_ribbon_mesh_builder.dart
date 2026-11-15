// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';

/// Właściwości cieniowania i parametry materiału PBR nawierzchni szosy.
class RoadSurfaceMaterialProperties {
  /// Typ nawierzchni (asfalt gładki, chropowaty, bruk 1-5 gwiazdek, szuter Strade Bianche).
  final SegmentSurfaceType surfaceType;

  /// Czy nawierzchnia jest mokra od deszczu (mokry asfalt z lustrzanymi odbiciami).
  final bool isWet;

  /// Współczynnik wilgotności nawierzchni $[0.0, 1.0]$.
  final double wetnessFactor;

  /// Kolor bazowy nawierzchni w formacie Hex (Albedo).
  final String baseColorHex;

  /// Chropowatość materiału (Roughness) $[0.0, 1.0]$.
  final double roughness;

  /// Metaliczność (Metallic) $[0.0, 1.0]$ (dla asfaltu zazwyczaj 0.0 - dielektryk).
  final double metallic;

  /// Poziom odbić zwierciadlanych (Specular / Reflectivity) $[0.0, 1.0]$.
  final double specular;

  /// Skala mapy wypukłości (Bump / Normal scale) $[0.0, 1.0]$.
  final double bumpScale;

  /// Częstotliwość powtarzania tekstury UV wzdłuż osi drogi (Tiling V).
  final double textureTilingV;

  /// Współczynnik powstawania kałuż i zastoisk wodnych $[0.0, 1.0]$.
  final double puddleFactor;

  const RoadSurfaceMaterialProperties({
    required this.surfaceType,
    this.isWet = false,
    this.wetnessFactor = 0.0,
    required this.baseColorHex,
    required this.roughness,
    this.metallic = 0.0,
    required this.specular,
    required this.bumpScale,
    required this.textureTilingV,
    this.puddleFactor = 0.0,
  });

  /// Fabryka tworząca parametry materiałowe dla zadanego typu nawierzchni i warunków pogodowych.
  factory RoadSurfaceMaterialProperties.fromSegment({
    required StageSegment segment,
    WeatherCondition weather = WeatherCondition.sunny,
  }) {
    final bool isRain = weather == WeatherCondition.lightRain || weather == WeatherCondition.heavyStorm;
    final double rainIntensity = (weather == WeatherCondition.heavyStorm) ? 1.0 : (isRain ? 0.65 : 0.0);

    switch (segment.surfaceType) {
      case SegmentSurfaceType.smoothAsphalt:
        return RoadSurfaceMaterialProperties(
          surfaceType: segment.surfaceType,
          isWet: isRain,
          wetnessFactor: rainIntensity,
          baseColorHex: isRain ? '#12161F' : '#1E2430',
          roughness: isRain ? 0.22 : 0.58,
          specular: isRain ? 0.85 : 0.28,
          bumpScale: isRain ? 0.12 : 0.25,
          textureTilingV: 0.25,
          puddleFactor: isRain ? rainIntensity * 0.8 : 0.0,
        );

      case SegmentSurfaceType.roughAsphalt:
        return RoadSurfaceMaterialProperties(
          surfaceType: segment.surfaceType,
          isWet: isRain,
          wetnessFactor: rainIntensity,
          baseColorHex: isRain ? '#1A1E26' : '#2A303C',
          roughness: isRain ? 0.35 : 0.78,
          specular: isRain ? 0.65 : 0.20,
          bumpScale: 0.45,
          textureTilingV: 0.35,
          puddleFactor: isRain ? rainIntensity * 0.5 : 0.0,
        );

      case SegmentSurfaceType.cobblestonesSector1:
      case SegmentSurfaceType.cobblestonesSector2:
      case SegmentSurfaceType.cobblestonesSector3:
      case SegmentSurfaceType.cobblestonesSector4:
      case SegmentSurfaceType.cobblestonesSector5:
        // Piekielne bruki Paris-Roubaix: wypukłe kamienie polne, błoto w deszczu
        return RoadSurfaceMaterialProperties(
          surfaceType: segment.surfaceType,
          isWet: isRain,
          wetnessFactor: rainIntensity,
          baseColorHex: isRain ? '#323438' : '#4E535E',
          roughness: isRain ? 0.42 : 0.88,
          specular: isRain ? 0.72 : 0.18,
          bumpScale: 0.92,
          textureTilingV: 0.85,
          puddleFactor: isRain ? rainIntensity * 0.95 : 0.0,
        );

      case SegmentSurfaceType.gravelStrade:
        // Szuter toskański Strade Bianche: jasna kreda, pył
        return RoadSurfaceMaterialProperties(
          surfaceType: segment.surfaceType,
          isWet: isRain,
          wetnessFactor: rainIntensity,
          baseColorHex: isRain ? '#8A7B68' : '#D1C4B2',
          roughness: isRain ? 0.65 : 0.94,
          specular: isRain ? 0.30 : 0.08,
          bumpScale: 0.75,
          textureTilingV: 0.50,
          puddleFactor: isRain ? rainIntensity * 0.4 : 0.0,
        );

      case SegmentSurfaceType.concrete:
        return RoadSurfaceMaterialProperties(
          surfaceType: segment.surfaceType,
          isWet: isRain,
          wetnessFactor: rainIntensity,
          baseColorHex: isRain ? '#3C4048' : '#5A606C',
          roughness: isRain ? 0.30 : 0.68,
          specular: isRain ? 0.55 : 0.22,
          bumpScale: 0.30,
          textureTilingV: 0.20,
          puddleFactor: isRain ? rainIntensity * 0.3 : 0.0,
        );
    }
  }
}

/// Model malowanego na asfalcie napisu kibiców w górach (Road Fan Graffiti Decal).
class RoadMarkingDecal {
  /// Wyświetlany tekst (np. "TADEJ", "JONAS", "REMSO", "POLSKA", "KOM 2026").
  final String text;

  /// Pozycja centralna napisu na asfalcie w przestrzeni świata $(X, Y, Z)$.
  final Vector3 positionWorld;

  /// Wektor kierunku napisu wzdłuż jezdni.
  final Vector3 forwardDirection;

  /// Wektor poprzeczny napisu w poprzek jezdni.
  final Vector3 rightDirection;

  /// Szerokość napisu na pasie ruchu [m].
  final double widthMeters;

  /// Długość napisu wzdłuż jezdni [m].
  final double lengthMeters;

  /// Kolor farby w formacie Hex (np. '#FFFFFF', '#FFD700', '#00E5FF').
  final String colorHex;

  /// Wierzchołki czworokąta kalkomanii (Decal Quad) lekko uniesione nad asfalt.
  final List<Vector3> quadVertices;

  /// Współrzędne tekstury UV dla kalkomanii.
  final List<Vector2> quadUvs;

  const RoadMarkingDecal({
    required this.text,
    required this.positionWorld,
    required this.forwardDirection,
    required this.rightDirection,
    required this.widthMeters,
    required this.lengthMeters,
    required this.colorHex,
    required this.quadVertices,
    required this.quadUvs,
  });
}

/// Pojedynczy wyliczony przekrój poprzeczny wstęgi szosy wzdłuż krzywej spline.
class RoadCrossSectionSlice {
  /// Dystans wzdłuż trasy od startu wycinka [m].
  final double distanceMeters;

  /// Punkt centralny osi szosy $(X, Y, Z)$ [m].
  final Vector3 center;

  /// Znormalizowany wektor styczny (kierunek jazdy w przód).
  final Vector3 tangent;

  /// Znormalizowany wektor normalny (góra nawierzchni).
  final Vector3 normal;

  /// Znormalizowany wektor boczny w prawo (w płaszczyźnie jezdni).
  final Vector3 lateralRight;

  /// Lewa skrajna krawędź pobocza / łąki [m].
  final Vector3 leftVerge;

  /// Lewa krawędź asfaltu (linia krawędziowa) [m].
  final Vector3 leftRoadEdge;

  /// Prawa krawędź asfaltu (linia krawędziowa) [m].
  final Vector3 rightRoadEdge;

  /// Prawa skrajna krawędź pobocza / łąki [m].
  final Vector3 rightVerge;

  /// Kąt przechyłu jezdni na zakręcie (Banking) [rad].
  final double bankingAngle;

  const RoadCrossSectionSlice({
    required this.distanceMeters,
    required this.center,
    required this.tangent,
    required this.normal,
    required this.lateralRight,
    required this.leftVerge,
    required this.leftRoadEdge,
    required this.rightRoadEdge,
    required this.rightVerge,
    required this.bankingAngle,
  });
}

/// Kompletna trójwymiarowa siatka geometrii wstęgi drogi (3D Road Ribbon Mesh).
class RoadRibbonMesh {
  /// Pozycje wierzchołków siatki w przestrzeni świata $(X, Y, Z)$ [m].
  final List<Vector3> vertices;

  /// Znormalizowane wektory normalne dla każdego wierzchołka.
  final List<Vector3> normals;

  /// Współrzędne mapowania tekstur UV dla każdego wierzchołka $(U, V)$.
  final List<Vector2> uvs;

  /// Indeksy trójkątów siatki (Triangle Indices: każde 3 wartości tworzą trójkąt).
  final List<int> indices;

  /// Wycinki przekrojów poprzecznych drogi (Road Slices).
  final List<RoadCrossSectionSlice> slices;

  /// Wygenerowane malowane napisy kibiców na asfalcie (Road Fan Decals).
  final List<RoadMarkingDecal> graffitiDecals;

  /// Właściwości materiałowe nawierzchni szosy (PBR properties).
  final RoadSurfaceMaterialProperties materialProperties;

  /// Prostopadłościan otaczający całą siatkę (Bounding Box AABB).
  final Aabb3 boundingBox;

  RoadRibbonMesh({
    required this.vertices,
    required this.normals,
    required this.uvs,
    required this.indices,
    required this.slices,
    required this.graffitiDecals,
    required this.materialProperties,
    required this.boundingBox,
  });

  /// Liczba trójkątów tworzących siatkę wstęgi drogi.
  int get triangleCount => indices.length ~/ 3;

  /// Liczba wierzchołków siatki.
  int get vertexCount => vertices.length;

  /// Długość całkowita wygenerowanego korytarza drogowego w metrach [m].
  double get totalLengthMeters => slices.isNotEmpty ? slices.last.distanceMeters : 0.0;
}

/// Konfiguracja parametrów generatora wstęgi drogi.
class RoadRibbonBuilderConfig {
  /// Szerokość asfaltowej jezdni w metrach (domyślnie 7.2 m).
  final double roadWidthMeters;

  /// Szerokość pobocza / krawężnika gruntowego w metrach [m] (domyślnie 1.8 m).
  final double vergeWidthMeters;

  /// Krok próbkowania wzdłużnego prostej drogi [m] (domyślnie 4.0 m).
  final double straightSamplingStepMeters;

  /// Zwiększony krok próbkowania w łukach i serpentynach [m] (domyślnie 1.2 m dla gładkości).
  final double curveSamplingStepMeters;

  /// Szerokość ciągłej linii krawędziowej jezdni [m] (domyślnie 0.16 m).
  final double edgeLineWidthMeters;

  /// Szerokość przerywanej linii osi jezdni [m] (domyślnie 0.14 m).
  final double centerLineWidthMeters;

  /// Długość kreski przerywanej linii osi [m] (domyślnie 3.0 m).
  final double centerLineDashLengthMeters;

  /// Długość przerwy między kreskami linii osi [m] (domyślnie 4.5 m).
  final double centerLineGapLengthMeters;

  /// Czy generować malowane napisy kibiców w partiach górskich.
  final bool enableMountainGraffiti;

  /// Warunki pogodowe wpływające na cieniowanie (deszcz, mokry asfalt).
  final WeatherCondition weather;

  const RoadRibbonBuilderConfig({
    this.roadWidthMeters = 7.2,
    this.vergeWidthMeters = 1.8,
    this.straightSamplingStepMeters = 4.0,
    this.curveSamplingStepMeters = 1.2,
    this.edgeLineWidthMeters = 0.16,
    this.centerLineWidthMeters = 0.14,
    this.centerLineDashLengthMeters = 3.0,
    this.centerLineGapLengthMeters = 4.5,
    this.enableMountainGraffiti = true,
    this.weather = WeatherCondition.sunny,
  });
}

/// Generator geometrii wstęgi drogi 3D w czasie rzeczywistym.
///
/// Funkcjonalności:
/// 1. Interpolacja punktów krzywej Centripetal Catmull-Rom dla gładkich zakrętów i serpentyn.
/// 2. Generowanie geometrii pasów ruchu, poboczy, linii krawędziowych i linii środkowych.
/// 3. Generowanie kultowych napisów kibiców ("TADEJ", "JONAS", "REMSO", "POLSKA", serca, grochy KOM).
/// 4. Dynamiczne cieniowanie nawierzchni: mokry asfalt z odbiciami, chropowaty bruk, szuter.
class RoadRibbonMeshBuilder {
  final RoadRibbonBuilderConfig config;

  const RoadRibbonMeshBuilder({
    this.config = const RoadRibbonBuilderConfig(),
  });

  // ===========================================================================
  // GŁÓWNA METODA GENEROWANIA SIATKI WSTĘGI DROGI 3D
  // ===========================================================================

  /// Buduje kompletną siatkę 3D wstęgi drogi na podstawie listy odcinków [segments].
  ///
  /// Opcjonalne okno widoczności:
  /// - [windowStartMeters]: Początek generowanego wycinka drogi (dla optymalizacji w czasie rzeczywistym).
  /// - [windowLengthMeters]: Długość generowanego korytarza w metrach (np. 600m wokół kamery).
  RoadRibbonMesh buildRoadRibbonMesh({
    required List<StageSegment> segments,
    double windowStartMeters = 0.0,
    double windowLengthMeters = 800.0,
    Vector3? originOffset,
  }) {
    if (segments.isEmpty) {
      return _createEmptyMesh();
    }

    // 1. Zbudowanie węzłów sterujących (Control Knots) w przestrzeni 3D z odcinków trasy
    final knots = _generateSpineKnots(segments: segments, origin: originOffset ?? Vector3.zero());

    // 2. Próbkowanie krzywej Catmull-Rom i wyznaczenie przekrojów poprzecznych (Slices)
    final slices = _sampleCatmullRomRibbon(
      knots: knots,
      windowStartMeters: windowStartMeters,
      windowLengthMeters: windowLengthMeters,
    );

    if (slices.length < 2) {
      return _createEmptyMesh();
    }

    // 3. Rozpoznanie dominującego materiału nawierzchni w danym oknie
    final activeMaterial = _resolveWindowMaterial(
      segments: segments,
      windowStartMeters: windowStartMeters,
    );

    // 4. Budowa buforów wierzchołków, normalnych, UV i indeksów trójkątów (Triangle Strips)
    final List<Vector3> vertices = [];
    final List<Vector3> normals = [];
    final List<Vector2> uvs = [];
    final List<int> indices = [];

    _buildRibbonGeometryBuffers(
      slices: slices,
      vertices: vertices,
      normals: normals,
      uvs: uvs,
      indices: indices,
    );

    // 5. Generowanie napisów kibiców na asfalcie w partiach górskich (Road Fan Decals)
    final List<RoadMarkingDecal> graffitiDecals = [];
    if (config.enableMountainGraffiti) {
      _generateMountainGraffitiDecals(
        slices: slices,
        segments: segments,
        windowStartMeters: windowStartMeters,
        outDecals: graffitiDecals,
      );
    }

    // 6. Obliczenie prostopadłościanu otaczającego AABB
    final aabb = _computeAabb(vertices);

    return RoadRibbonMesh(
      vertices: vertices,
      normals: normals,
      uvs: uvs,
      indices: indices,
      slices: slices,
      graffitiDecals: graffitiDecals,
      materialProperties: activeMaterial,
      boundingBox: aabb,
    );
  }

  // ===========================================================================
  // 1. GENEROWANIE WĘZŁÓW STERUJĄCYCH KRZYWEJ SPLINE
  // ===========================================================================

  List<_SpineKnot> _generateSpineKnots({
    required List<StageSegment> segments,
    required Vector3 origin,
  }) {
    final List<_SpineKnot> knots = [];

    double currentDist = 0.0;
    Vector3 currentPos = Vector3.copy(origin);
    double currentBearing = segments.first.roadBearingDegrees * math.pi / 180.0;

    for (int segIdx = 0; segIdx < segments.length; segIdx++) {
      final seg = segments[segIdx];
      final double lengthM = seg.lengthKm * 1000.0;
      final double startAlt = seg.startElevationM;
      final double endAlt = seg.endElevationM;
      final double segBearingRad = seg.roadBearingDegrees * math.pi / 180.0;
      final double gradient = seg.gradientPercent;

      // Wykrywanie serpentyn górskich na podstawie trudności technicznej i podjazdu
      final bool isSerpentineClimb = (seg.technicalDifficulty >= 55.0 && seg.isClimb);

      if (isSerpentineClimb) {
        // Generowanie węzłów serpentyny (naprzemienne łuki agrafkowe / hairpins)
        const double hairpinRadius = 16.0; // Promień agrafki 16m
        final int switchbackCount = math.max(2, (lengthM / 240.0).round());
        final double legLength = lengthM / switchbackCount;

        for (int sw = 0; sw < switchbackCount; sw++) {
          final double tStart = sw / switchbackCount;
          final double tEnd = (sw + 1) / switchbackCount;
          final double legAltStart = startAlt + (endAlt - startAlt) * tStart;
          final double legAltEnd = startAlt + (endAlt - startAlt) * tEnd;

          // Naprzemienny zwrot serpentyny: lewo / prawo
          final double turnSign = (sw % 2 == 0) ? 1.0 : -1.0;
          const double turnAngle = math.pi * 0.92; // Prawie 180 stopni zwrotu

          // Węzeł prostego odcinka
          knots.add(_SpineKnot(
            distanceMeters: currentDist,
            position: Vector3.copy(currentPos),
            bearingRadians: currentBearing,
            gradientPercent: gradient,
            bankingRadians: 0.0,
            segmentIndex: segIdx,
          ));

          // Przesunięcie wzdłuż nogi serpentyny
          final double legHeading = currentBearing;
          currentPos += Vector3(
            legLength * 0.65 * math.sin(legHeading),
            legAltEnd - legAltStart,
            legLength * 0.65 * math.cos(legHeading),
          );
          currentDist += legLength * 0.65;

          // Węzeł wierzchołka agrafki (Apex) z przechyłem poprzecznym (Banking)
          currentBearing += (turnAngle * turnSign);
          final double bankAngle = 0.085 * turnSign; // ok. 5 stopni przechyłu

          knots.add(_SpineKnot(
            distanceMeters: currentDist,
            position: Vector3.copy(currentPos),
            bearingRadians: currentBearing,
            gradientPercent: gradient * 1.25, // W zakręcie stromiej
            bankingRadians: bankAngle,
            segmentIndex: segIdx,
            isHairpinApex: true,
          ));

          currentDist += math.pi * hairpinRadius;
        }
      } else {
        // Standardowy odcinek drogi (płaski, pofałdowany lub zjazd)
        final double deltaAlt = endAlt - startAlt;
        final double knotStep = math.min(lengthM * 0.5, 150.0);
        final int knotCount = math.max(2, (lengthM / knotStep).round());

        for (int k = 0; k <= knotCount; k++) {
          final double t = k / knotCount;
          final double knotDist = currentDist + (lengthM * t);
          final double knotAlt = startAlt + (deltaAlt * t);

          // Płynne przejście kąta azymutu do następnego odcinka
          final double nextBearing = (segIdx + 1 < segments.length)
              ? (segments[segIdx + 1].roadBearingDegrees * math.pi / 180.0)
              : segBearingRad;
          final double knotBearing = segBearingRad + (nextBearing - segBearingRad) * t;

          // Przesunięcie w przestrzeni świata
          final double distFromSegStart = lengthM * t;
          final Vector3 knotPos = currentPos + Vector3(
            distFromSegStart * math.sin(knotBearing),
            knotAlt - startAlt,
            distFromSegStart * math.cos(knotBearing),
          );

          knots.add(_SpineKnot(
            distanceMeters: knotDist,
            position: knotPos,
            bearingRadians: knotBearing,
            gradientPercent: gradient,
            bankingRadians: 0.0,
            segmentIndex: segIdx,
          ));
        }

        currentDist += lengthM;
        currentPos = knots.last.position;
        currentBearing = segBearingRad;
      }
    }

    return knots;
  }

  // ===========================================================================
  // 2. PRÓBKOWANIE KRZYWEJ CENTRIPETAL CATMULL-ROM
  // ===========================================================================

  List<RoadCrossSectionSlice> _sampleCatmullRomRibbon({
    required List<_SpineKnot> knots,
    required double windowStartMeters,
    required double windowLengthMeters,
  }) {
    if (knots.length < 2) return [];

    final double windowEndMeters = windowStartMeters + windowLengthMeters;
    final List<RoadCrossSectionSlice> slices = [];

    final double roadHalfWidth = config.roadWidthMeters * 0.5;
    final double vergeWidth = config.vergeWidthMeters;

    // Przeszukiwanie przedziału węzłów w oknie widoczności
    for (int i = 0; i < knots.length - 1; i++) {
      final p0 = (i > 0) ? knots[i - 1].position : knots[i].position;
      final p1 = knots[i].position;
      final p2 = knots[i + 1].position;
      final p3 = (i + 2 < knots.length) ? knots[i + 2].position : p2;

      final double segStartDist = knots[i].distanceMeters;
      final double segEndDist = knots[i + 1].distanceMeters;
      final double segLength = segEndDist - segStartDist;

      if (segEndDist < windowStartMeters || segStartDist > windowEndMeters) {
        continue; // Poza oknem widoczności
      }

      // Dynamiczny krok próbkowania: w ostrych zakrętach i serpentynach gęściej
      final bool isCurved = knots[i].isHairpinApex || knots[i + 1].isHairpinApex ||
          (knots[i].bearingRadians - knots[i + 1].bearingRadians).abs() > 0.08;

      final double stepMeters = isCurved
          ? config.curveSamplingStepMeters
          : config.straightSamplingStepMeters;

      final int subSteps = math.max(2, (segLength / stepMeters).ceil());

      for (int s = 0; s < subSteps; s++) {
        final double t = s / subSteps;
        final double distAlong = segStartDist + (segLength * t);

        if (distAlong < windowStartMeters || distAlong > windowEndMeters) {
          continue;
        }

        // 1. Pozycja punktu centralnego na krzywej Centripetal Catmull-Rom
        final Vector3 center = _evaluateCentripetalCatmullRom(p0, p1, p2, p3, t);

        // 2. Wektor styczny (pochodna krzywej w punkcie t)
        final Vector3 tangent = _evaluateCatmullRomTangent(p0, p1, p2, p3, t)..normalize();

        // 3. Przechył poprzeczny (Banking)
        final double banking = knots[i].bankingRadians +
            (knots[i + 1].bankingRadians - knots[i].bankingRadians) * t;

        // 4. Baza ortonormalna: Up i Lateral Right
        final rawUp = Vector3(0.0, 1.0, 0.0);
        // Obrót wektora Up wokół osi stycznej o kąt banking
        final cosBank = math.cos(banking);
        final sinBank = math.sin(banking);

        final horizontalRight = tangent.cross(rawUp)..normalize();
        final surfaceNormal = (rawUp * cosBank + horizontalRight * sinBank)..normalize();
        final lateralRight = surfaceNormal.cross(tangent)..normalize();

        // 5. Wyznaczenie punktów krawędzi jezdni i pobocza
        final leftRoadEdge = center - (lateralRight * roadHalfWidth);
        final rightRoadEdge = center + (lateralRight * roadHalfWidth);
        final leftVerge = center - (lateralRight * (roadHalfWidth + vergeWidth)) - (surfaceNormal * 0.06);
        final rightVerge = center + (lateralRight * (roadHalfWidth + vergeWidth)) - (surfaceNormal * 0.06);

        slices.add(RoadCrossSectionSlice(
          distanceMeters: distAlong,
          center: center,
          tangent: tangent,
          normal: surfaceNormal,
          lateralRight: lateralRight,
          leftVerge: leftVerge,
          leftRoadEdge: leftRoadEdge,
          rightRoadEdge: rightRoadEdge,
          rightVerge: rightVerge,
          bankingAngle: banking,
        ));
      }
    }

    return slices;
  }

  // ===========================================================================
  // 3. BUDOWA BUFORÓW SIATKI 3D (TRIANGLE STRIPS DLA JEZDNI, LINII I POBOCZY)
  // ===========================================================================

  void _buildRibbonGeometryBuffers({
    required List<RoadCrossSectionSlice> slices,
    required List<Vector3> vertices,
    required List<Vector3> normals,
    required List<Vector2> uvs,
    required List<int> indices,
  }) {
    // Układ wierzchołków dla każdego przekroju (6 wierzchołków na profil):
    // 0: Left Verge (skrajne lewe pobocze)
    // 1: Left Road Edge (lewa krawędź asfaltu)
    // 2: Left Lane Center
    // 3: Centerline (oś jezdni)
    // 4: Right Road Edge (prawa krawędź asfaltu)
    // 5: Right Verge (skrajne prawe pobocze)

    final double uvScaleV = config.roadWidthMeters * 0.25;

    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final double vCoord = slice.distanceMeters / uvScaleV;

      final pLeftLaneCenter = (slice.leftRoadEdge + slice.center) * 0.5;

      // Dodanie 6 wierzchołków profilu poprzecznego
      vertices.add(slice.leftVerge);       // 0
      vertices.add(slice.leftRoadEdge);    // 1
      vertices.add(pLeftLaneCenter);       // 2
      vertices.add(slice.center);          // 3
      vertices.add(slice.rightRoadEdge);   // 4
      vertices.add(slice.rightVerge);      // 5

      // Wektory normalne
      normals.add(slice.normal);
      normals.add(slice.normal);
      normals.add(slice.normal);
      normals.add(slice.normal);
      normals.add(slice.normal);
      normals.add(slice.normal);

      // Współrzędne tekstur UV (U od 0.0 na lewym poboczu do 1.0 na prawym)
      uvs.add(Vector2(0.00, vCoord));
      uvs.add(Vector2(0.18, vCoord));
      uvs.add(Vector2(0.36, vCoord));
      uvs.add(Vector2(0.50, vCoord));
      uvs.add(Vector2(0.82, vCoord));
      uvs.add(Vector2(1.00, vCoord));
    }

    // Łączenie kolejnych przekrojów trójkątami (Quad Meshing: 5 pasów równoległych)
    const int vertsPerSlice = 6;
    for (int i = 0; i < slices.length - 1; i++) {
      final int row0 = i * vertsPerSlice;
      final int row1 = (i + 1) * vertsPerSlice;

      // 5 pasów czworokątów:
      // Pas 0: Lewe pobocze (Verge Left -> Road Left)
      // Pas 1: Lewy pas ruchu (Road Left -> Left Lane Center)
      // Pas 2: Lewy pas do osi (Left Lane Center -> Centerline)
      // Pas 3: Prawy pas ruchu (Centerline -> Right Road Edge)
      // Pas 4: Prawe pobocze (Road Right -> Verge Right)
      for (int c = 0; c < 5; c++) {
        final int bl = row0 + c;     // Bottom-Left
        final int br = row0 + c + 1; // Bottom-Right
        final int tl = row1 + c;     // Top-Left
        final int tr = row1 + c + 1; // Top-Right

        // Trójkąt 1: BL -> TL -> BR
        indices.add(bl);
        indices.add(tl);
        indices.add(br);

        // Trójkąt 2: BR -> TL -> TR
        indices.add(br);
        indices.add(tl);
        indices.add(tr);
      }
    }
  }

  // ===========================================================================
  // 4. GENEROWANIE NAPISÓW KIBICÓW NA ASFALCIE W GÓRACH (ROAD GRAFFITI)
  // ===========================================================================

  void _generateMountainGraffitiDecals({
    required List<RoadCrossSectionSlice> slices,
    required List<StageSegment> segments,
    required double windowStartMeters,
    required List<RoadMarkingDecal> outDecals,
  }) {
    if (slices.length < 10) return;

    // Baza kultowych haseł kibiców na alpejskich podjazdach
    final fanSlogans = [
      ('TADEJ', '#FFD700', 3.2, 1.4),     // Żółty Pogacar
      ('JONAS', '#EF4444', 3.2, 1.4),     // Czerwony Vingegaard
      ('REMSO', '#38BDF8', 3.0, 1.3),     // Błękitny Evenepoel
      ('POLSKA', '#FFFFFF', 3.4, 1.5),    // Biały napis kibiców z Polski
      ('GO GO GO!', '#10B981', 3.6, 1.4), // Zielony okrzyk
      ('KOM 2026', '#EF4444', 2.8, 1.3),  // Grochy górskie
      ('ATTACK!', '#F59E0B', 3.0, 1.4),   // Pomarańczowy atak
      ('♥ WOUT ♥', '#38BDF8', 3.2, 1.4),  // Serduszka dla Wouta
    ];

    // Rozmieszczanie napisów co ok. 35 - 55 metrów na podjazdach górskich
    const double decalIntervalMeters = 42.0;
    double nextDecalDist = ((windowStartMeters / decalIntervalMeters).floor() + 1) * decalIntervalMeters;

    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];

      if (slice.distanceMeters >= nextDecalDist) {
        // Sprawdzenie, czy ten fragment trasy leży w strefie górskiej lub podjazdu
        final matchingSeg = segments.firstWhere(
          (s) => s.endKm * 1000.0 >= slice.distanceMeters,
          orElse: () => segments.last,
        );

        final bool isMountainArea = matchingSeg.isClimb || matchingSeg.startElevationM > 650.0;
        if (!isMountainArea) {
          nextDecalDist += decalIntervalMeters;
          continue;
        }

        final int sloganIndex = ((nextDecalDist / decalIntervalMeters).round()) % fanSlogans.length;
        final slogan = fanSlogans[sloganIndex];

        // Losowe lekkie przesunięcie w poprzek jezdni (na lewy lub prawy pas)
        final double lateralShift = ((sloganIndex % 3) - 1.0) * 1.3;
        final Vector3 decalCenter = slice.center + (slice.lateralRight * lateralShift) + (slice.normal * 0.005); // +5mm ponad asfaltem

        final double w = slogan.$3;
        final double l = slogan.$4;
        final halfW = w * 0.5;
        final halfL = l * 0.5;

        final right = slice.lateralRight;
        final forward = slice.tangent;

        // 4 wierzchołki czworokąta kalkomanii
        final p0 = decalCenter - (right * halfW) - (forward * halfL);
        final p1 = decalCenter + (right * halfW) - (forward * halfL);
        final p2 = decalCenter + (right * halfW) + (forward * halfL);
        final p3 = decalCenter - (right * halfW) + (forward * halfL);

        outDecals.add(RoadMarkingDecal(
          text: slogan.$1,
          positionWorld: decalCenter,
          forwardDirection: forward,
          rightDirection: right,
          widthMeters: w,
          lengthMeters: l,
          colorHex: slogan.$2,
          quadVertices: [p0, p1, p2, p3],
          quadUvs: [
            Vector2(0.0, 0.0),
            Vector2(1.0, 0.0),
            Vector2(1.0, 1.0),
            Vector2(0.0, 1.0),
          ],
        ));

        nextDecalDist += decalIntervalMeters;
      }
    }
  }

  // ===========================================================================
  // 5. ANTY-CUSP CENTRIPETAL CATMULL-ROM MATH
  // ===========================================================================

  /// Analityczna ewaluacja krzywej Centripetal Catmull-Rom ($\alpha = 0.5$).
  ///
  /// Eliminuje samozapętlenia i załamania (cusps) w ostrych agrafkach górskich.
  static Vector3 _evaluateCentripetalCatmullRom(
    Vector3 p0,
    Vector3 p1,
    Vector3 p2,
    Vector3 p3,
    double t,
  ) {
    // Centripetal Catmull-Rom parametrization
    const double alpha = 0.5;

    const double t0 = 0.0;
    final double t1 = t0 + math.pow((p1 - p0).length, alpha).toDouble();
    final double t2 = t1 + math.pow((p2 - p1).length, alpha).toDouble();
    final double t3 = t2 + math.pow((p3 - p2).length, alpha).toDouble();

    // Normalizacja parametru t z zakresu [0, 1] do [t1, t2]
    final double actualT = t1 + (t2 - t1) * t;

    // Rekurencyjna interpolacja De Casteljau / Barry-Goldman
    final a1 = _knotLerp(p0, p1, t0, t1, actualT);
    final a2 = _knotLerp(p1, p2, t1, t2, actualT);
    final a3 = _knotLerp(p2, p3, t2, t3, actualT);

    final b1 = _knotLerp(a1, a2, t0, t2, actualT);
    final b2 = _knotLerp(a2, a3, t1, t3, actualT);

    return _knotLerp(b1, b2, t1, t2, actualT);
  }

  /// Wektor styczny do krzywej Catmull-Rom w punkcie [t].
  static Vector3 _evaluateCatmullRomTangent(
    Vector3 p0,
    Vector3 p1,
    Vector3 p2,
    Vector3 p3,
    double t,
  ) {
    const double dt = 0.005;
    final double tA = (t - dt).clamp(0.0, 1.0);
    final double tB = (t + dt).clamp(0.0, 1.0);

    final posA = _evaluateCentripetalCatmullRom(p0, p1, p2, p3, tA);
    final posB = _evaluateCentripetalCatmullRom(p0, p1, p2, p3, tB);

    final tangent = posB - posA;
    if (tangent.length2 < 1e-8) {
      return (p2 - p1)..normalize();
    }
    return tangent..normalize();
  }

  static Vector3 _knotLerp(Vector3 a, Vector3 b, double tA, double tB, double t) {
    if ((tB - tA).abs() < 1e-6) return Vector3.copy(a);
    final double factor = (t - tA) / (tB - tA);
    return a + (b - a) * factor;
  }

  RoadSurfaceMaterialProperties _resolveWindowMaterial({
    required List<StageSegment> segments,
    required double windowStartMeters,
  }) {
    final activeSegment = segments.firstWhere(
      (s) => s.endKm * 1000.0 >= windowStartMeters,
      orElse: () => segments.first,
    );

    return RoadSurfaceMaterialProperties.fromSegment(
      segment: activeSegment,
      weather: config.weather,
    );
  }

  Aabb3 _computeAabb(List<Vector3> verts) {
    if (verts.isEmpty) return Aabb3();
    final minV = Vector3.copy(verts.first);
    final maxV = Vector3.copy(verts.first);

    for (int i = 1; i < verts.length; i++) {
      final v = verts[i];
      if (v.x < minV.x) minV.x = v.x;
      if (v.y < minV.y) minV.y = v.y;
      if (v.z < minV.z) minV.z = v.z;

      if (v.x > maxV.x) maxV.x = v.x;
      if (v.y > maxV.y) maxV.y = v.y;
      if (v.z > maxV.z) maxV.z = v.z;
    }

    return Aabb3.minMax(minV, maxV);
  }

  RoadRibbonMesh _createEmptyMesh() {
    return RoadRibbonMesh(
      vertices: [],
      normals: [],
      uvs: [],
      indices: [],
      slices: [],
      graffitiDecals: [],
      materialProperties: const RoadSurfaceMaterialProperties(
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        baseColorHex: '#1E2430',
        roughness: 0.6,
        specular: 0.3,
        bumpScale: 0.2,
        textureTilingV: 0.25,
      ),
      boundingBox: Aabb3(),
    );
  }
}

/// Wewnętrzny węzeł szkieletu trasy 3D.
class _SpineKnot {
  final double distanceMeters;
  final Vector3 position;
  final double bearingRadians;
  final double gradientPercent;
  final double bankingRadians;
  final int segmentIndex;
  final bool isHairpinApex;

  const _SpineKnot({
    required this.distanceMeters,
    required this.position,
    required this.bearingRadians,
    required this.gradientPercent,
    required this.bankingRadians,
    required this.segmentIndex,
    this.isHairpinApex = false,
  });
}
