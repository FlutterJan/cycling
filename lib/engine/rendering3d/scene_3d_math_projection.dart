// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

/// Precyzyjne koordynaty kolarza na trasie wyścigu kolarskiego (układ krzywoliniowy drogi).
///
/// Wykorzystywany do jednoznacznego określenia pozycji zawodnika wzdłuż trasy:
/// - [distanceMeters]: Dystans przebyty wzdłuż osi szosy od startu etapu [m].
/// - [lateralOffsetMeters]: Poprzeczne odchylenie od osi jezdni [m] (ujemne = lewa strona, dodatnie = prawa strona).
/// - [elevationMeters]: Wysokość n.p.m. nawierzchni szosy w danym punkcie trasy [m].
/// - [verticalOffsetMeters]: Pionowe przesunięcie nad asfaltem [m] (0.0 = styk opon, ~0.95m = tułów, ~1.35m = kask).
class CoursePosition {
  /// Dystans wzdłuż trasy od linii startu [m].
  final double distanceMeters;

  /// Pozycja poprzeczna na szosie: odchylenie od linii środkowej jezdni [m].
  /// Standardowa szerokość jezdni to 7.0 m (zakres od -3.5 m do +3.5 m).
  final double lateralOffsetMeters;

  /// Wysokość n.p.m. asfaltu w tym punkcie trasy [m].
  final double elevationMeters;

  /// Przesunięcie pionowe nad powierzchnię szosy [m] (np. środek ciężkości roweru, głowa kolarza).
  final double verticalOffsetMeters;

  const CoursePosition({
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.elevationMeters,
    this.verticalOffsetMeters = 0.0,
  });

  /// Kopia obiektu z opcjonalną modyfikacją wybranych pól.
  CoursePosition copyWith({
    double? distanceMeters,
    double? lateralOffsetMeters,
    double? elevationMeters,
    double? verticalOffsetMeters,
  }) {
    return CoursePosition(
      distanceMeters: distanceMeters ?? this.distanceMeters,
      lateralOffsetMeters: lateralOffsetMeters ?? this.lateralOffsetMeters,
      elevationMeters: elevationMeters ?? this.elevationMeters,
      verticalOffsetMeters: verticalOffsetMeters ?? this.verticalOffsetMeters,
    );
  }

  @override
  String toString() =>
      'CoursePosition(dist: ${distanceMeters.toStringAsFixed(1)}m, lat: ${lateralOffsetMeters.toStringAsFixed(2)}m, alt: ${elevationMeters.toStringAsFixed(1)}m)';
}

/// Parametry geometryczne wycinka drogi wyścigu kolarskiego.
///
/// Zawiera dane o promieniu łuku, nachyleniu podjazdu, azymucie i profilu poprzecznym jezdni.
class RoadGeometryParameters {
  /// Promień łuku poziomego skrętu drogi w metrach [m].
  ///
  /// Konwencja znakowa:
  /// - Wartość dodatnia ($R > 0$): Zakręt w prawo (zgodnie z ruchem wskazówek zegara).
  /// - Wartość ujemna ($R < 0$): Zakręt w lewo (przeciwnie do ruchu wskazówek zegara).
  /// - Bardzo duża wartość ($|R| \ge 100\,000$ lub [double.infinity]): Prosta szosa.
  /// - Typowy promień serpentyny alpejskiej: 12 m - 25 m.
  /// - Typowy łuk zjazdowy: 60 m - 200 m.
  final double turningRadiusMeters;

  /// Nachylenie podjazdu lub zjazdu w procentach [%].
  ///
  /// Wartość dodatnia oznacza wspinaczkę pod górę (np. +9.5% na Alpe d'Huez),
  /// wartość ujemna oznacza zjazd (np. -7.0% z Col du Galibier),
  /// 0.0% oznacza idealnie płaski odcinek.
  final double gradientPercent;

  /// Bazowy azymut odcinka drogi na płaszczyźnie poziomej X-Z [rad].
  ///
  /// $0$ oznacza kierunek wzdłuż osi $+Z$ (północ), $\pi/2$ oznacza $+X$ (wschód).
  final double roadBearingRadians;

  /// Całkowita szerokość nawierzchni szosy w metrach [m] (domyślnie 7.2 m).
  final double roadWidthMeters;

  /// Przechył poprzeczny jezdni w łuku (Superelevation / Banking) [rad].
  /// Dodatni kąt oznacza uniesienie zewnętrznej krawędzi łuku zapobiegające ześlizgowi kolarza.
  final double bankingAngleRadians;

  /// Bieżąca prędkość kolarza w m/s (używana do wyznaczenia dynamicznego pochylenia roweru w zakręcie).
  final double speedMs;

  const RoadGeometryParameters({
    this.turningRadiusMeters = double.infinity,
    this.gradientPercent = 0.0,
    this.roadBearingRadians = 0.0,
    this.roadWidthMeters = 7.2,
    this.bankingAngleRadians = 0.0,
    this.speedMs = 12.0,
  });

  /// Czy droga na tym odcinku jest prostoliniowa (promień skrętu dąży do nieskończoności).
  bool get isStraight => turningRadiusMeters.abs() >= 100000.0 || turningRadiusMeters.isInfinite;

  /// Krzywizna drogi $\kappa = \frac{1}{R}$ [$m^{-1}$].
  double get curvature => isStraight ? 0.0 : (1.0 / turningRadiusMeters);

  /// Kąt nachylenia podjazdu $\theta = \arctan(\text{gradient} / 100)$ [rad].
  double get slopeAngleRadians => math.atan(gradientPercent / 100.0);

  /// Kopia obiektu z nadpisaniem parametrów.
  RoadGeometryParameters copyWith({
    double? turningRadiusMeters,
    double? gradientPercent,
    double? roadBearingRadians,
    double? roadWidthMeters,
    double? bankingAngleRadians,
    double? speedMs,
  }) {
    return RoadGeometryParameters(
      turningRadiusMeters: turningRadiusMeters ?? this.turningRadiusMeters,
      gradientPercent: gradientPercent ?? this.gradientPercent,
      roadBearingRadians: roadBearingRadians ?? this.roadBearingRadians,
      roadWidthMeters: roadWidthMeters ?? this.roadWidthMeters,
      bankingAngleRadians: bankingAngleRadians ?? this.bankingAngleRadians,
      speedMs: speedMs ?? this.speedMs,
    );
  }
}

/// Pełna trójwymiarowa pozycja i orientacja przestrzenna kolarza wraz z rowerem (3D Pose).
///
/// Zawiera wektory bazy Freneta przystosowane do powierzchni drogi:
/// - [position]: Pozycja $(X, Y, Z)$ w układzie świata 3D.
/// - [tangent]: Jednostkowy wektor kierunku jazdy kolarza (przód roweru).
/// - [lateralRight]: Jednostkowy wektor skierowany w prawo od kolarza (równoległy do asfaltu).
/// - [surfaceNormal]: Jednostkowy wektor prostopadły do powierzchni jezdni (góra).
/// - [yaw], [pitch], [roll]: Kąty Eulera orientacji roweru.
/// - [orientation]: Kwaternion rotacji w przestrzeni 3D.
/// - [transformMatrix]: Pełna macierz transformacji afinicznej $4 \times 4$ (Model Matrix).
class Cyclist3DPose {
  /// Pozycja $(X, Y, Z)$ środka suportu / styku kolarza w układzie świata [m].
  final Vector3 position;

  /// Wektor kierunku jazdy (w przód wzdłuż nachylenia i łuku drogi).
  final Vector3 tangent;

  /// Wektor poprzeczny w prawo w płaszczyźnie jezdni.
  final Vector3 lateralRight;

  /// Wektor normalny powierzchni (prostopadły do szosy).
  final Vector3 surfaceNormal;

  /// Kąt odchylenia poziomego w płaszczyźnie X-Z (Yaw / Kurs) [rad].
  final double yaw;

  /// Kąt pochylenia wzdłużnego wynikający z nachylenia góry (Pitch / Wznios) [rad].
  final double pitch;

  /// Kąt pochylenia bocznego roweru w zakręcie (Roll / Złożenie w wiraż) [rad].
  final double roll;

  /// Macierz obrotu $3 \times 3$.
  final Matrix3 rotationMatrix;

  /// Macierz transformacji $4 \times 4$ (World Transform Matrix).
  final Matrix4 transformMatrix;

  /// Kwaternion obrotu.
  final Quaternion orientation;

  /// Pozycja styku przedniego koła z asfaltem w przestrzeni 3D.
  final Vector3 frontWheelContact;

  /// Pozycja styku tylnego koła z asfaltem w przestrzeni 3D.
  final Vector3 rearWheelContact;

  /// Pozycja głowy kolarza w przestrzeni 3D (dla umiejscowienia kasku / etykiety HUD).
  final Vector3 headPosition;

  Cyclist3DPose({
    required this.position,
    required this.tangent,
    required this.lateralRight,
    required this.surfaceNormal,
    required this.yaw,
    required this.pitch,
    required this.roll,
    required this.rotationMatrix,
    required this.transformMatrix,
    required this.orientation,
    required this.frontWheelContact,
    required this.rearWheelContact,
    required this.headPosition,
  });

  @override
  String toString() =>
      'Cyclist3DPose(pos: (${position.x.toStringAsFixed(2)}, ${position.y.toStringAsFixed(2)}, ${position.z.toStringAsFixed(2)}), '
      'yaw: ${(yaw * 180.0 / math.pi).toStringAsFixed(1)}°, pitch: ${(pitch * 180.0 / math.pi).toStringAsFixed(1)}°, roll: ${(roll * 180.0 / math.pi).toStringAsFixed(1)}°)';
}

/// Przekrój poprzeczny szosy w danym punkcie kilometrowym trasy.
class RoadCrossSection3D {
  /// Punkt na linii środkowej szosy $(X, Y, Z)$ [m].
  final Vector3 center;

  /// Lewa krawędź asfaltu / pobocze lewe [m].
  final Vector3 leftEdge;

  /// Prawa krawędź asfaltu / pobocze prawe [m].
  final Vector3 rightEdge;

  /// Wektor styczny do osi drogi (kierunek jazdy).
  final Vector3 tangent;

  /// Wektor poprzeczny w prawo wzdłuż profilu drogi.
  final Vector3 lateral;

  /// Wektor normalny nawierzchni szosy.
  final Vector3 normal;

  const RoadCrossSection3D({
    required this.center,
    required this.leftEdge,
    required this.rightEdge,
    required this.tangent,
    required this.lateral,
    required this.normal,
  });
}

/// Wynik rzutowania perspektywicznego punktu trójwymiarowego na ekran dwuwymiarowy (Screen Space).
class ProjectedPoint3D {
  /// Pozycja horyzontalna piksela na ekranie $[0, \text{viewportWidth}]$ (od lewej do prawej).
  final double screenX;

  /// Pozycja wertykalna piksela na ekranie $[0, \text{viewportHeight}]$ (od góry do dołu, zgodnie ze standardem Canvas).
  final double screenY;

  /// Znormalizowane koordynaty urządzenia (NDC) $X \in [-1, 1]$.
  final double ndcX;

  /// Znormalizowane koordynaty urządzenia (NDC) $Y \in [-1, 1]$.
  final double ndcY;

  /// Znormalizowana głębokość w przestrzeni obcinania (NDC Depth) $Z \in [-1, 1]$.
  final double ndcZ;

  /// Składowa jednorodna $W$ po transformacji rzutowania (Camera Clip W).
  ///
  /// Gdy $W > 0$, punkt znajduje się z przodu kamery (w stożku widzenia).
  /// Gdy $W \le 0$, punkt znajduje się za kamerą.
  final double clipW;

  /// Liniowa odległość punktu od obiektywu kamery wzdłuż osi widzenia [m] (Eye Space Z).
  final double depthEye;

  /// Czy rzutowany punkt znajduje się przed płaszczyzną kamery ($W > 0.001$).
  final bool isInFrontOfCamera;

  /// Czy rzutowany punkt mieści się w widocznych granicach ekranu (Viewport Bounds).
  final bool isInViewport;

  /// Skala perspektywiczna billboardu / etykiety HUD w stosunku do dystansu referencyjnego (np. 10m).
  ///
  /// Punkt w odległości 10m ma skalę 1.0; punkt w odległości 20m ma skalę 0.5; punkt w odległości 5m ma skalę 2.0.
  final double perspectiveScale;

  const ProjectedPoint3D({
    required this.screenX,
    required this.screenY,
    required this.ndcX,
    required this.ndcY,
    required this.ndcZ,
    required this.clipW,
    required this.depthEye,
    required this.isInFrontOfCamera,
    required this.isInViewport,
    required this.perspectiveScale,
  });

  @override
  String toString() =>
      'ProjectedPoint3D(screen: (${screenX.toStringAsFixed(1)}, ${screenY.toStringAsFixed(1)}), depth: ${depthEye.toStringAsFixed(1)}m, visible: $isInViewport, scale: ${perspectiveScale.toStringAsFixed(2)})';
}

/// Konfiguracja parametrów wirtualnej kamery 3D.
class Camera3DConfig {
  /// Pozycja kamery w przestrzeni świata $(X, Y, Z)$ [m].
  final Vector3 position;

  /// Punkt, na który patrzy obiektyw kamery (Look-At Target) [m].
  final Vector3 target;

  /// Wektor kierunku "góry" dla kamery (zazwyczaj $[0, 1, 0]$).
  final Vector3 up;

  /// Pionowy kąt widzenia obiektywu w stopniach (Vertical Field of View, np. 55° - 65°).
  final double fovYDegrees;

  /// Płaszczyzna bliskiego obcinania w metrach [m] (zNear).
  final double nearPlane;

  /// Płaszczyzna dalekiego obcinania w metrach [m] (zFar).
  final double farPlane;

  Camera3DConfig({
    required this.position,
    required this.target,
    Vector3? up,
    this.fovYDegrees = 58.0,
    this.nearPlane = 0.2,
    this.farPlane = 3500.0,
  }) : up = up ?? Vector3(0.0, 1.0, 0.0);

  /// Kąt widzenia kamery w radianach.
  double get fovYRadians => fovYDegrees * math.pi / 180.0;
}

/// Główny silnik matematyczny rzutowania perspektywicznego 3D oraz geometrii szosowej.
///
/// Implementuje kompletny potok obliczeniowy oparty o pakiet [vector_math_64]:
/// 1. Macierz Widoku (View Matrix): transformacja z układu świata do układu oka kamery.
/// 2. Macierz Projekcji (Projection Matrix): perspektywiczna kompresja stożka widzenia.
/// 3. Macierz View-Projection ($M_{vp} = M_{proj} \times M_{view}$) oraz jej odwrotność.
/// 4. Rzutowanie World-to-Screen (Piksele ekranu, NDC, bufor głębokości, Frustum Culling).
/// 5. Rzutowanie wsteczne Screen-to-World (Ray Casting / Picking kolarzy na ekranie dotykowym).
/// 6. Transformacja współrzędnych trasy wyścigu $(s, u, h)$ na przestrzeń 3D $(X, Y, Z)$
///    z uwzględnieniem promienia skrętu (analityczna całka łukowa) i nachylenia podjazdu.
class Scene3DMathProjection {
  // Macierze transformacji geometrycznej (64-bit precision)
  final Matrix4 _viewMatrix = Matrix4.identity();
  final Matrix4 _projectionMatrix = Matrix4.identity();
  final Matrix4 _viewProjectionMatrix = Matrix4.identity();
  final Matrix4 _invertedViewProjection = Matrix4.identity();
  final Matrix4 _invertedViewMatrix = Matrix4.identity();
  final Matrix4 _invertedProjectionMatrix = Matrix4.identity();

  // Bryła widzenia (Frustum Culling)
  final Frustum _frustum = Frustum();

  // Bieżące parametry widoku i rzutowania
  Vector3 _cameraPosition = Vector3(0.0, 2.0, -6.0);
  Vector3 _cameraTarget = Vector3(0.0, 1.0, 0.0);
  Vector3 _cameraUp = Vector3(0.0, 1.0, 0.0);

  double _viewportWidth = 1920.0;
  double _viewportHeight = 1080.0;
  double _fovYRadians = 58.0 * math.pi / 180.0;
  double _zNear = 0.2;
  double _zFar = 3500.0;

  bool _isMatricesDirty = true;

  Scene3DMathProjection({
    double viewportWidth = 1920.0,
    double viewportHeight = 1080.0,
    double fovYDegrees = 58.0,
    double zNear = 0.2,
    double zFar = 3500.0,
  })  : _viewportWidth = viewportWidth,
        _viewportHeight = viewportHeight,
        _fovYRadians = fovYDegrees * math.pi / 180.0,
        _zNear = zNear,
        _zFar = zFar {
    recomputeMatrices();
  }

  // ===========================================================================
  // GETTERY DLA MACIERZY I PARAMETRÓW SILNIKA
  // ===========================================================================

  /// Aktualna macierz widoku kamery $M_{view}$ ($4 \times 4$).
  Matrix4 get viewMatrix {
    _ensureMatricesClean();
    return _viewMatrix;
  }

  /// Aktualna macierz projekcji perspektywicznej $M_{proj}$ ($4 \times 4$).
  Matrix4 get projectionMatrix {
    _ensureMatricesClean();
    return _projectionMatrix;
  }

  /// Połączona macierz View-Projection $M_{vp} = M_{proj} \times M_{view}$.
  Matrix4 get viewProjectionMatrix {
    _ensureMatricesClean();
    return _viewProjectionMatrix;
  }

  /// Odwrócona macierz View-Projection $(M_{vp})^{-1}$ (do Screen-to-World Raycastingu).
  Matrix4 get invertedViewProjectionMatrix {
    _ensureMatricesClean();
    return _invertedViewProjection;
  }

  /// Aktualna bryła obcinania kamery (Frustum).
  Frustum get frustum {
    _ensureMatricesClean();
    return _frustum;
  }

  /// Pozycja kamery w przestrzeni świata.
  Vector3 get cameraPosition => _cameraPosition;

  /// Punkt ogniskowania kamery (Look-At).
  Vector3 get cameraTarget => _cameraTarget;

  /// Szerokość rzutni (Viewport Width w pikselach logicznych).
  double get viewportWidth => _viewportWidth;

  /// Wysokość rzutni (Viewport Height w pikselach logicznych).
  double get viewportHeight => _viewportHeight;

  /// Proporcje ekranu (Aspect Ratio = width / height).
  double get aspectRatio => (_viewportHeight > 0.0) ? (_viewportWidth / _viewportHeight) : 1.777778;

  /// Kąt widzenia w osi pionowej w radianach.
  double get fovYRadians => _fovYRadians;

  /// Kąt widzenia w osi pionowej w stopniach.
  double get fovYDegrees => _fovYRadians * 180.0 / math.pi;

  // ===========================================================================
  // AKTUALIZACJA PARAMETRÓW KAMERY I RZUTNI
  // ===========================================================================

  /// Aktualizuje macierz widoku kamery na podstawie pozycji oka, celu i wektora góry.
  void setView({
    required Vector3 eye,
    required Vector3 target,
    Vector3? up,
  }) {
    _cameraPosition = Vector3.copy(eye);
    _cameraTarget = Vector3.copy(target);
    _cameraUp = up != null ? Vector3.copy(up) : Vector3(0.0, 1.0, 0.0);
    _isMatricesDirty = true;
  }

  /// Aktualizuje parametry projekcji perspektywicznej.
  void setProjection({
    double? fovYRadians,
    double? fovYDegrees,
    double? zNear,
    double? zFar,
  }) {
    if (fovYRadians != null) {
      _fovYRadians = fovYRadians;
    } else if (fovYDegrees != null) {
      _fovYRadians = fovYDegrees * math.pi / 180.0;
    }
    if (zNear != null) _zNear = zNear;
    if (zFar != null) _zFar = zFar;
    _isMatricesDirty = true;
  }

  /// Aktualizuje wymiary rzutni ekranu (Viewport Dimensions).
  void setViewport({
    required double width,
    required double height,
  }) {
    if (width <= 0.0 || height <= 0.0) return;
    _viewportWidth = width;
    _viewportHeight = height;
    _isMatricesDirty = true;
  }

  /// Wygodna jednoczesna aktualizacja całej konfiguracji kamery i rzutni.
  void updateCamera(
    Camera3DConfig config, {
    required double viewportWidth,
    required double viewportHeight,
  }) {
    _cameraPosition = Vector3.copy(config.position);
    _cameraTarget = Vector3.copy(config.target);
    _cameraUp = Vector3.copy(config.up);
    _fovYRadians = config.fovYRadians;
    _zNear = config.nearPlane;
    _zFar = config.farPlane;
    _viewportWidth = viewportWidth > 0.0 ? viewportWidth : _viewportWidth;
    _viewportHeight = viewportHeight > 0.0 ? viewportHeight : _viewportHeight;
    recomputeMatrices();
  }

  /// Wymusza przeliczenie wszystkich macierzy transformacji i płaszczyzn Frustuma.
  void recomputeMatrices() {
    // 1. Obliczenie macierzy widoku (View Matrix - LookAt)
    setViewMatrix(_viewMatrix, _cameraPosition, _cameraTarget, _cameraUp);

    // 2. Obliczenie macierzy projekcji perspektywicznej (OpenGL Perspective Matrix)
    setPerspectiveMatrix(_projectionMatrix, _fovYRadians, aspectRatio, _zNear, _zFar);

    // 3. Obliczenie połączonej macierzy View-Projection: M_vp = M_proj * M_view
    _viewProjectionMatrix
      ..setFrom(_projectionMatrix)
      ..multiply(_viewMatrix);

    // 4. Inwersje macierzy dla raycastingu i transformacji zwrotnych
    _invertedViewProjection
      ..setFrom(_viewProjectionMatrix)
      ..invert();

    _invertedViewMatrix
      ..setFrom(_viewMatrix)
      ..invert();

    _invertedProjectionMatrix
      ..setFrom(_projectionMatrix)
      ..invert();

    // 5. Aktualizacja 6 płaszczyzn Frustuma obcinania
    _frustum.setFromMatrix(_viewProjectionMatrix);

    _isMatricesDirty = false;
  }

  void _ensureMatricesClean() {
    if (_isMatricesDirty) {
      recomputeMatrices();
    }
  }

  // ===========================================================================
  // RZUTOWANIE PERSPEKTYWICZNE 3D -> 2D SCREEN SPACE
  // ===========================================================================

  /// Rzutuje punkt ze współrzędnych świata 3D na piksele ekranu (World-to-Screen).
  ///
  /// Zwraca obiekt [ProjectedPoint3D] zawierający:
  /// - `screenX`, `screenY`: Pozycja w pikselach logicznych Canvas,
  /// - `depthEye`: Rzeczywisty dystans kolarza od obiektywu w metrach,
  /// - `isInFrontOfCamera`: Flaga informująca, czy obiekt nie znajduje się za plecami kamery,
  /// - `isInViewport`: Flaga widoczności w kadrze,
  /// - `perspectiveScale`: Skala perspektywiczna do skalowania 2D tagów/etykiet watów.
  ProjectedPoint3D worldToScreen(Vector3 worldPoint) {
    _ensureMatricesClean();

    // 1. Transformacja do jednorodnej przestrzeni obcinania (Clip Space)
    final clipVec = Vector4(worldPoint.x, worldPoint.y, worldPoint.z, 1.0);
    _viewProjectionMatrix.transform(clipVec);

    final double clipW = clipVec.w;
    final bool isInFront = clipW > 0.001;

    // Odległość w przestrzeni oka (Eye Space depth)
    // W rzucie OpenGL wiersz 3 to (0, 0, -1, 0), stąd clipW odpowiada -Z w przestrzeni widoku
    final double depthEye = clipW;

    if (!isInFront) {
      return ProjectedPoint3D(
        screenX: -9999.0,
        screenY: -9999.0,
        ndcX: 0.0,
        ndcY: 0.0,
        ndcZ: 1.0,
        clipW: clipW,
        depthEye: depthEye,
        isInFrontOfCamera: false,
        isInViewport: false,
        perspectiveScale: 0.0,
      );
    }

    // 2. Podział perspektywiczny do znormalizowanych koordynatów urządzenia (NDC) [-1, 1]
    final double invW = 1.0 / clipW;
    final double ndcX = clipVec.x * invW;
    final double ndcY = clipVec.y * invW;
    final double ndcZ = clipVec.z * invW;

    // 3. Mapowanie NDC na przestrzeń pikseli Viewportu
    // Uwaga: w Canvas standardowym Y=0 jest na górze ekranu, a Y=height na dole
    final double screenX = (ndcX + 1.0) * 0.5 * _viewportWidth;
    final double screenY = (1.0 - ndcY) * 0.5 * _viewportHeight;

    final bool inViewport = (screenX >= 0.0 &&
        screenX <= _viewportWidth &&
        screenY >= 0.0 &&
        screenY <= _viewportHeight &&
        ndcZ >= -1.0 &&
        ndcZ <= 1.0);

    // 4. Obliczenie współczynnika skali perspektywicznej
    // Odległość referencyjna: obiekt oddalony o 10 metrów ma skalę 1.0
    const double referenceDistance = 10.0;
    final double focalLengthFactor = 1.0 / math.tan(_fovYRadians * 0.5);
    final double scale = (referenceDistance / math.max(0.2, depthEye)) * (focalLengthFactor * 0.6);

    return ProjectedPoint3D(
      screenX: screenX,
      screenY: screenY,
      ndcX: ndcX,
      ndcY: ndcY,
      ndcZ: ndcZ,
      clipW: clipW,
      depthEye: depthEye,
      isInFrontOfCamera: true,
      isInViewport: inViewport,
      perspectiveScale: scale.clamp(0.05, 5.0),
    );
  }

  /// Rzutuje punkt ze świata 3D na Znormalizowane Koordynaty Urządzenia (NDC) $[-1, 1]^3$.
  Vector3 worldToNdc(Vector3 worldPoint) {
    _ensureMatricesClean();
    final v = Vector4(worldPoint.x, worldPoint.y, worldPoint.z, 1.0);
    _viewProjectionMatrix.transform(v);
    if (v.w.abs() < 1e-6) {
      return Vector3(0.0, 0.0, 1.0);
    }
    final invW = 1.0 / v.w;
    return Vector3(v.x * invW, v.y * invW, v.z * invW);
  }

  /// Przekształca współrzędne piksela na ekranie w promień w przestrzeni świata 3D (Ray Casting).
  ///
  /// Niezbędne do klikania / wybierania kolarzy palcem na ekranie dotykowym (Picking).
  Ray screenToWorldRay(double screenX, double screenY) {
    _ensureMatricesClean();

    // 1. Konwersja pikseli ekranu na koordynaty NDC
    final double ndcX = (2.0 * screenX / _viewportWidth) - 1.0;
    final double ndcY = 1.0 - (2.0 * screenY / _viewportHeight);

    // 2. Punkty na płaszczyźnie bliskiej (Z = -1) i dalekiej (Z = +1)
    final nearVec = Vector4(ndcX, ndcY, -1.0, 1.0);
    final farVec = Vector4(ndcX, ndcY, 1.0, 1.0);

    _invertedViewProjection.transform(nearVec);
    _invertedViewProjection.transform(farVec);

    if (nearVec.w.abs() > 1e-6) {
      nearVec.scale(1.0 / nearVec.w);
    }
    if (farVec.w.abs() > 1e-6) {
      farVec.scale(1.0 / farVec.w);
    }

    final pNear = Vector3(nearVec.x, nearVec.y, nearVec.z);
    final pFar = Vector3(farVec.x, farVec.y, farVec.z);

    final rayDirection = (pFar - pNear)..normalize();
    return Ray.originDirection(pNear, rayDirection);
  }

  /// Oblicza punkt przecięcia promienia z ekranu z poziomą płaszczyzną szosy $Y = \text{groundY}$.
  Vector3? screenToGroundPoint(double screenX, double screenY, {double groundElevationY = 0.0}) {
    final ray = screenToWorldRay(screenX, screenY);
    if (ray.direction.y.abs() < 1e-5) return null; // Promień jest równoległy do podłoża

    final double t = (groundElevationY - ray.origin.y) / ray.direction.y;
    if (t < 0.0) return null; // Przecięcie za kamerą

    return ray.origin + (ray.direction * t);
  }

  // ===========================================================================
  // SPRAWDZANIE WIDOCZNOŚCI (FRUSTUM CULLING)
  // ===========================================================================

  /// Sprawdza, czy pojedynczy punkt leży wewnątrz bryły widzenia kamery (Frustum).
  bool isPointInFrustum(Vector3 point) {
    _ensureMatricesClean();
    return _frustum.containsVector3(point);
  }

  /// Sprawdza, czy kula otaczająca model (Bounding Sphere) przecina pole widzenia kamery.
  bool isSphereInFrustum(Vector3 center, double radius) {
    _ensureMatricesClean();
    final sphere = Sphere.centerRadius(center, radius);
    return _frustum.intersectsWithSphere(sphere);
  }

  /// Sprawdza, czy prostopadłościan otaczający (AABB) przecina pole widzenia kamery.
  bool isAabbInFrustum(Aabb3 box) {
    _ensureMatricesClean();
    return _frustum.intersectsWithAabb3(box);
  }

  /// Oblicza współczynnik skali perspektywicznej w danym punkcie świata.
  double calculatePerspectiveScale(Vector3 worldPoint, {double referenceDistance = 10.0}) {
    _ensureMatricesClean();
    final eyePos = _viewMatrix.transform3(Vector3.copy(worldPoint));
    final double dist = -eyePos.z; // Dystans przed okiem kamery
    if (dist <= 0.1) return 0.0;
    return (referenceDistance / dist);
  }

  // ===========================================================================
  // TRANSFORMACJE WSPÓŁRZĘDNYCH KOLARZA NA TRASIE -> PRZESTRZEŃ 3D (X, Y, Z)
  // ===========================================================================

  /// Transformuje współrzędne trasy kolarza na precyzyjną pozycję 3D $(X, Y, Z)$ w świecie.
  ///
  /// Parametry wejściowe:
  /// - [distanceMeters]: Dystans przebyty wzdłuż łuku drogi [m].
  /// - [lateralOffsetMeters]: Pozycja poprzeczna na szosie względem osi [m] (np. -1.5m z lewej, +1.2m z prawej).
  /// - [elevationMeters]: Wysokość n.p.m. profilu szosy [m].
  /// - [turningRadiusMeters]: Promień skrętu drogi [m] (dodatni = w prawo, ujemny = w lewo, inf = prosta).
  /// - [gradientPercent]: Nachylenie podjazdu w procentach [%] (dodatnie = wspinaczka, ujemne = zjazd).
  /// - [baseBearingRadians]: Początkowy azymut drogi na wlocie w odcinek [rad].
  /// - [bankingAngleRadians]: Poprzeczny przechył nawierzchni szosy na łuku [rad].
  /// - [verticalOffsetMeters]: Przesunięcie pionowe nad powierzchnię szosy [m].
  /// - [segmentOriginWorld]: Współrzędne początku danego odcinka szosy w świecie 3D (domyślnie $[0, 0, 0]$).
  static Vector3 courseToWorld3D({
    required double distanceMeters,
    required double lateralOffsetMeters,
    required double elevationMeters,
    double turningRadiusMeters = double.infinity,
    double gradientPercent = 0.0,
    double baseBearingRadians = 0.0,
    double bankingAngleRadians = 0.0,
    double verticalOffsetMeters = 0.0,
    Vector3? segmentOriginWorld,
  }) {
    final origin = segmentOriginWorld ?? Vector3.zero();

    // 1. Obliczenie pozycji osi jezdni w płaszczyźnie poziomej X-Z (Analityczna całka łuku)
    final roadCenterline = computeArcHorizontalOffset(
      arcDistanceMeters: distanceMeters,
      turningRadiusMeters: turningRadiusMeters,
      initialBearingRadians: baseBearingRadians,
    );

    // 2. Bieżący kąt azymutu drogi po przebyciu dystansu 'distanceMeters'
    final double currentBearing = computeRoadHeading(
      arcDistanceMeters: distanceMeters,
      turningRadiusMeters: turningRadiusMeters,
      initialBearingRadians: baseBearingRadians,
    );

    // 3. Wektor poprzeczny jezdni (Lateral Right Vector) prostopadły do kierunku jazdy
    // Dla kierunku jazdy T = (sin(psi), cos(psi)), wektor w prawo to N = (cos(psi), -sin(psi))
    final double cosB = math.cos(currentBearing);
    final double sinB = math.sin(currentBearing);

    // Wpływ przechyłu drogi (Banking) na wysokość i pozycję boczną
    final double cosBank = math.cos(bankingAngleRadians);
    final double sinBank = math.sin(bankingAngleRadians);

    final double latX = lateralOffsetMeters * cosB * cosBank;
    final double latZ = -lateralOffsetMeters * sinB * cosBank;
    final double latY = lateralOffsetMeters * sinBank;

    // 4. Składanie pełnych koordynatów (X, Y, Z)
    final double worldX = origin.x + roadCenterline.x + latX;
    final double worldY = origin.y + elevationMeters + latY + verticalOffsetMeters;
    final double worldZ = origin.z + roadCenterline.y + latZ;

    return Vector3(worldX, worldY, worldZ);
  }

  /// Oblicza pełną postawę 3D kolarza (pozycję, wektory bazy Freneta, macierz modelu oraz kąty Eulera).
  ///
  /// Uwzględnia:
  /// - Wznios drogi wynikający z nachylenia podjazdu (Pitch: $\arctan(\text{gradient} / 100)$),
  /// - Skręt i azymut szosy (Yaw),
  /// - Dynamiczne pochylenie roweru w wirażu zależne od prędkości i promienia (Roll: $\arctan(v^2 / (g \cdot R))$),
  /// - Punkty styku kół z podłożem i wysokość głowy kolarza.
  static Cyclist3DPose courseToCyclistPose({
    required CoursePosition coursePosition,
    required RoadGeometryParameters roadGeometry,
    Vector3? segmentOriginWorld,
  }) {
    final double s = coursePosition.distanceMeters;
    final double u = coursePosition.lateralOffsetMeters;
    final double h = coursePosition.elevationMeters;
    final double w = coursePosition.verticalOffsetMeters;

    // 1. Pozycja środka suportu / styku kolarza
    final Vector3 pos = courseToWorld3D(
      distanceMeters: s,
      lateralOffsetMeters: u,
      elevationMeters: h,
      turningRadiusMeters: roadGeometry.turningRadiusMeters,
      gradientPercent: roadGeometry.gradientPercent,
      baseBearingRadians: roadGeometry.roadBearingRadians,
      bankingAngleRadians: roadGeometry.bankingAngleRadians,
      verticalOffsetMeters: w,
      segmentOriginWorld: segmentOriginWorld,
    );

    // 2. Kąty orientacji
    // Yaw: bieżący azymut osi szosy
    final double yaw = computeRoadHeading(
      arcDistanceMeters: s,
      turningRadiusMeters: roadGeometry.turningRadiusMeters,
      initialBearingRadians: roadGeometry.roadBearingRadians,
    );

    // Pitch: kąt wzniosu jezdni wynikający z gradientu podjazdu
    final double pitch = roadGeometry.slopeAngleRadians;

    // Roll: fizyczne pochylenie roweru w wirażu z uwzględnieniem przechyłu szosy
    final double physicalLean = computeCyclistLeanAngle(
      speedMs: roadGeometry.speedMs,
      turningRadiusMeters: roadGeometry.turningRadiusMeters,
    );
    final double roll = physicalLean + roadGeometry.bankingAngleRadians;

    // 3. Obliczenie ortonormalnej bazy wektorów Freneta przystosowanej do drogi
    final double cosY = math.cos(yaw);
    final double sinY = math.sin(yaw);
    final double cosP = math.cos(pitch);
    final double sinP = math.sin(pitch);
    final double cosR = math.cos(roll);
    final double sinR = math.sin(roll);

    // Wektor styczny (Tangent - kierunek w przód wzdłuż nachylenia trasy)
    final tangent = Vector3(cosP * sinY, sinP, cosP * cosY)..normalize();

    // Wektor poprzeczny w prawo (Lateral Right - równoległy do profilu szosy z uwzględnieniem roll)
    final rawRight = Vector3(
      cosR * cosY - sinR * sinP * sinY,
      sinR * cosP,
      -cosR * sinY - sinR * sinP * cosY,
    )..normalize();

    // Wektor normalny do podłoża (Surface Normal - skierowany do góry kolarza)
    final surfaceNormal = tangent.cross(rawRight)..normalize();
    // Ponowna ortogonalizacja prawej strony dla gwarancji ścisłej ortonormalności bazy
    final lateralRight = surfaceNormal.cross(tangent)..normalize();

    // 4. Budowa macierzy obrotu 3x3 i transformacji afinicznej 4x4
    final rotationMatrix = Matrix3.columns(lateralRight, surfaceNormal, tangent);
    final orientation = Quaternion.fromRotation(rotationMatrix);

    final transformMatrix = Matrix4.identity()
      ..setFromTranslationRotation(pos, orientation);

    // 5. Pozycje styku kół i głowy kolarza (rozstaw osi roweru = ~1.0 m)
    const double halfWheelBase = 0.50; // 50 cm w przód i w tył od środka ramy
    final frontWheel = pos + (tangent * halfWheelBase);
    final rearWheel = pos - (tangent * halfWheelBase);

    // Głowa kolarza (~1.35 m wzdłuż wektora normalnego z lekkim aerodynamicznym pochyleniem w przód)
    final head = pos + (surfaceNormal * 1.30) + (tangent * 0.22);

    return Cyclist3DPose(
      position: pos,
      tangent: tangent,
      lateralRight: lateralRight,
      surfaceNormal: surfaceNormal,
      yaw: yaw,
      pitch: pitch,
      roll: roll,
      rotationMatrix: rotationMatrix,
      transformMatrix: transformMatrix,
      orientation: orientation,
      frontWheelContact: frontWheel,
      rearWheelContact: rearWheel,
      headPosition: head,
    );
  }

  /// Oblicza przekrój poprzeczny szosy 3D (lewa krawędź, środek, prawa krawędź) na danym kilometrze.
  static RoadCrossSection3D computeRoadCrossSection({
    required double distanceMeters,
    required double elevationMeters,
    required double roadWidthMeters,
    double turningRadiusMeters = double.infinity,
    double gradientPercent = 0.0,
    double baseBearingRadians = 0.0,
    double bankingAngleRadians = 0.0,
    Vector3? segmentOriginWorld,
  }) {
    final double halfW = roadWidthMeters * 0.5;

    final center = courseToWorld3D(
      distanceMeters: distanceMeters,
      lateralOffsetMeters: 0.0,
      elevationMeters: elevationMeters,
      turningRadiusMeters: turningRadiusMeters,
      gradientPercent: gradientPercent,
      baseBearingRadians: baseBearingRadians,
      bankingAngleRadians: bankingAngleRadians,
      segmentOriginWorld: segmentOriginWorld,
    );

    final leftEdge = courseToWorld3D(
      distanceMeters: distanceMeters,
      lateralOffsetMeters: -halfW,
      elevationMeters: elevationMeters,
      turningRadiusMeters: turningRadiusMeters,
      gradientPercent: gradientPercent,
      baseBearingRadians: baseBearingRadians,
      bankingAngleRadians: bankingAngleRadians,
      segmentOriginWorld: segmentOriginWorld,
    );

    final rightEdge = courseToWorld3D(
      distanceMeters: distanceMeters,
      lateralOffsetMeters: halfW,
      elevationMeters: elevationMeters,
      turningRadiusMeters: turningRadiusMeters,
      gradientPercent: gradientPercent,
      baseBearingRadians: baseBearingRadians,
      bankingAngleRadians: bankingAngleRadians,
      segmentOriginWorld: segmentOriginWorld,
    );

    final lateral = (rightEdge - leftEdge)..normalize();

    // Wektor styczny
    final double heading = computeRoadHeading(
      arcDistanceMeters: distanceMeters,
      turningRadiusMeters: turningRadiusMeters,
      initialBearingRadians: baseBearingRadians,
    );
    final double slope = math.atan(gradientPercent / 100.0);
    final tangent = Vector3(
      math.cos(slope) * math.sin(heading),
      math.sin(slope),
      math.cos(slope) * math.cos(heading),
    )..normalize();

    final normal = lateral.cross(tangent)..normalize();

    return RoadCrossSection3D(
      center: center,
      leftEdge: leftEdge,
      rightEdge: rightEdge,
      tangent: tangent,
      lateral: lateral,
      normal: normal,
    );
  }

  // ===========================================================================
  // ANALITYCZNA GEOMETRIA ŁUKU I KRZYWIZNY SZOSY
  // ===========================================================================

  /// Analityczna całka łukowa przemieszczenia w płaszczyźnie poziomej X-Z po przebyciu dystansu [arcDistanceMeters].
  ///
  /// Zwraca wektor `Vector2(deltaX, deltaZ)` względem początku łuku:
  /// - Dla prostej szosy ($|R| \ge 100\,000$ lub $\infty$):
  ///   $$\Delta X = s \cdot \sin(\psi_0), \quad \Delta Z = s \cdot \cos(\psi_0)$$
  /// - Dla zakrętu o promieniu $R$ i krzywiźnie $\kappa = 1/R$:
  ///   $$\Delta X = R \cdot \left[ \cos(\psi_0) - \cos\left(\psi_0 + \frac{s}{R}\right) \right]$$
  ///   $$\Delta Z = R \cdot \left[ \sin\left(\psi_0 + \frac{s}{R}\right) - \sin(\psi_0) \right]$$
  ///
  /// Wzór ten jest w pełni ciągły i działa identycznie dla łuków w prawo ($R > 0$) i w lewo ($R < 0$).
  static Vector2 computeArcHorizontalOffset({
    required double arcDistanceMeters,
    required double turningRadiusMeters,
    double initialBearingRadians = 0.0,
  }) {
    final double s = arcDistanceMeters;
    final double r = turningRadiusMeters;
    final double psi0 = initialBearingRadians;

    // Przypadek prostoliniowy (lub promień dążący do nieskończoności)
    if (r.isInfinite || r.abs() >= 100000.0) {
      final double dx = s * math.sin(psi0);
      final double dz = s * math.cos(psi0);
      return Vector2(dx, dz);
    }

    // Zabezpieczenie przed dzieleniem przez zero dla zdegenerowanego promienia
    final double safeRadius = (r.abs() < 0.5) ? (r >= 0 ? 0.5 : -0.5) : r;
    final double angleDelta = s / safeRadius;
    final double currentAngle = psi0 + angleDelta;

    final double dx = safeRadius * (math.cos(psi0) - math.cos(currentAngle));
    final double dz = safeRadius * (math.sin(currentAngle) - math.sin(psi0));

    return Vector2(dx, dz);
  }

  /// Oblicza bieżący azymut/kurs drogi na płaszczyźnie poziomej po przebyciu zadanego dystansu łuku.
  ///
  /// $$\psi(s) = \psi_0 + \frac{s}{R}$$
  static double computeRoadHeading({
    required double arcDistanceMeters,
    required double turningRadiusMeters,
    double initialBearingRadians = 0.0,
  }) {
    if (turningRadiusMeters.isInfinite || turningRadiusMeters.abs() >= 100000.0) {
      return initialBearingRadians;
    }
    final double safeRadius = (turningRadiusMeters.abs() < 0.5)
        ? (turningRadiusMeters >= 0 ? 0.5 : -0.5)
        : turningRadiusMeters;

    final double heading = initialBearingRadians + (arcDistanceMeters / safeRadius);
    // Normalizacja do zakresu [0, 2π)
    const double twoPi = 2.0 * math.pi;
    final double normalized = heading % twoPi;
    return normalized < 0 ? normalized + twoPi : normalized;
  }

  /// Fizyczne obliczenie kąta pochylenia kolarza w zakręcie (Dynamic Lean Angle).
  ///
  /// Kolarz pokonujący łuk o promieniu $R$ z prędkością $v$ doświadcza przyspieszenia dośrodkowego:
  /// $$a_c = \frac{v^2}{R}$$
  /// Aby zrównoważyć moment wywracający, układ rower-kolarz musi złożyć się w wiraż pod kątem:
  /// $$\tan(\theta) = \frac{v^2}{g \cdot R} \implies \theta = \arctan\left(\frac{v^2}{g \cdot R}\right)$$
  ///
  /// Kąt jest bezpiecznie ograniczany do fizycznego limitu przyczepności opon (~43° = 0.75 rad).
  static double computeCyclistLeanAngle({
    required double speedMs,
    required double turningRadiusMeters,
    double maxLeanAngleRadians = 0.75, // ok. 43 stopnie
  }) {
    if (turningRadiusMeters.isInfinite || turningRadiusMeters.abs() >= 100000.0) {
      return 0.0;
    }

    const double g = 9.80665; // Przyspieszenie ziemskie [m/s^2]
    final double safeRadius = (turningRadiusMeters.abs() < 0.5)
        ? (turningRadiusMeters >= 0 ? 0.5 : -0.5)
        : turningRadiusMeters;

    final double speedSq = speedMs * speedMs;
    final double tanTheta = speedSq / (g * safeRadius.abs());
    final double angleMag = math.atan(tanTheta).clamp(0.0, maxLeanAngleRadians);

    // Znak pochylenia: w prawo dodatni, w lewo ujemny
    return turningRadiusMeters >= 0 ? angleMag : -angleMag;
  }

  // ===========================================================================
  // SPECJALISTYCZNE KAMERY KOLARSKIE (CHASE, DRONE, MOTO TV, FINISH LINE)
  // ===========================================================================

  /// Ustawia kamerę śledzącą zza pleców wybranego kolarza (Chase Cam w stylu Zwift/MyWhoosh).
  ///
  /// - [distanceBack]: Odległość kamery za plecami zawodnika w metrach (domyślnie 4.8m).
  /// - [heightAboveRider]: Wysokość obiektywu nad wysokością kolarza (domyślnie 0.55m).
  /// - [lookAheadDistance]: Punkt skupienia wzroku kamery przed kolarzem (domyślnie 6.5m).
  /// - [lateralOffset]: Przesunięcie kamery w bok (dla dynamicznego ujęcia z ukosa).
  void setupChaseCamera({
    required Cyclist3DPose riderPose,
    double distanceBack = 4.8,
    double heightAboveRider = 0.55,
    double lookAheadDistance = 6.5,
    double lateralOffset = 0.0,
  }) {
    final Vector3 pos = riderPose.position;
    final Vector3 tangent = riderPose.tangent;
    final Vector3 normal = riderPose.surfaceNormal;
    final Vector3 right = riderPose.lateralRight;

    final Vector3 eye = pos - (tangent * distanceBack) + (normal * (1.1 + heightAboveRider)) + (right * lateralOffset);
    final Vector3 target = pos + (tangent * lookAheadDistance) + (normal * 0.95);

    setView(eye: eye, target: target, up: normal);
  }

  /// Ustawia wysoką perspektywę z drona obserwującego formację peletonu (Overhead Drone).
  void setupDroneCamera({
    required Vector3 pelotonCenter,
    double altitude = 22.0,
    double distanceBack = 10.0,
    double lateralOffset = 3.5,
  }) {
    final Vector3 eye = Vector3(
      pelotonCenter.x + lateralOffset,
      pelotonCenter.y + altitude,
      pelotonCenter.z - distanceBack,
    );
    final Vector3 target = Vector3(
      pelotonCenter.x,
      pelotonCenter.y + 0.8,
      pelotonCenter.z + 4.0,
    );

    setView(eye: eye, target: target);
  }

  /// Ustawia dynamiczną kamerę telewizyjną na motocyklu jadącym przed czołem wyścigu (Moto TV Lead).
  ///
  /// Obiektyw skierowany jest do tyłu, filmując zbliżających się liderów i uciekinierów.
  void setupMotoTvCamera({
    required Cyclist3DPose leaderPose,
    double distanceAhead = 12.0,
    double height = 1.75,
    double lateralOffset = 1.4,
  }) {
    final Vector3 pos = leaderPose.position;
    final Vector3 tangent = leaderPose.tangent;
    final Vector3 normal = leaderPose.surfaceNormal;
    final Vector3 right = leaderPose.lateralRight;

    final Vector3 eye = pos + (tangent * distanceAhead) + (normal * height) + (right * lateralOffset);
    // Obiektyw skupiony na klatce piersiowej lidera
    final Vector3 target = pos + (normal * 1.15);

    setView(eye: eye, target: target, up: normal);
  }

  /// Ustawia statyczną kamerę finiszową na bramie mety (Finish Gantry Camera).
  void setupFinishGantryCamera({
    required Vector3 finishLinePosition,
    required Vector3 roadApproachDirection,
    double height = 5.6,
    double distanceBeforeLine = 14.0,
  }) {
    final approachNorm = Vector3.copy(roadApproachDirection)..normalize();
    final eye = finishLinePosition + Vector3(0.0, height, 0.0);
    // Spojrzenie w dół na zbliżających się z prostej finiszowej zawodników
    final target = finishLinePosition - (approachNorm * distanceBeforeLine) + Vector3(0.0, 0.8, 0.0);

    setView(eye: eye, target: target);
  }

  /// Ustawia panoramiczną kamerę helikoptera realizatora transmisji (Helicopter Cam).
  void setupHelicopterCamera({
    required Vector3 focalPoint,
    double altitude = 65.0,
    double orbitRadius = 85.0,
    double orbitAngleRadians = 0.0,
  }) {
    final double eyeX = focalPoint.x + math.sin(orbitAngleRadians) * orbitRadius;
    final double eyeZ = focalPoint.z + math.cos(orbitAngleRadians) * orbitRadius;
    final double eyeY = focalPoint.y + altitude;

    setView(
      eye: Vector3(eyeX, eyeY, eyeZ),
      target: Vector3(focalPoint.x, focalPoint.y + 1.0, focalPoint.z),
    );
  }
}
