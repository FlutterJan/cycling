// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../models/race/race_stage.dart';
import 'dynamic_skybox_and_lighting_painter.dart';
import 'peloton_3d_canvas_engine.dart';
import 'scene_3d_math_projection.dart';

/// Poziom jakości miękkich cieni planarnych rzutowanych na powierzchnię asfaltu.
enum PlanarShadowQuality {
  /// Pełne cienie z dwustopniowym rozmyciem półcienia (penumbra) i miękkim blurem dla bliskich obiektów.
  high,

  /// Zrównoważone cienie wielowarstwowe (umbra + penumbra + AO) bez kosztownych filtrów rozmycia.
  balanced,

  /// Tryb wydajnościowy 120 FPS: szybkie cienie kontaktowe i główne wielokąty bez dodatkowych warstw.
  performance,
}

/// Rodzaj bramy lub konstrukcji nadjezdniowej rzucającej cień na asfalt.
enum PlanarGateKind {
  kilometerGate,
  flammeRougeGate,
  finishGantry,
}

/// Gatunek drzewa przydrożnego determinujący kształt rzutowanego cienia korony.
enum PlanarTreeSpecies {
  pine,
  deciduous,
  cypress,
}

/// Parametry ekspozycji zbocza i lokalnej geometrii płaszczyzny asfaltu.
///
/// Umożliwia precyzyjne obliczenie wydłużenia oraz zmiękczenia cienia w zależności
/// od nachylenia podłużnego drogi (`gradientPercent`), przechyłu poprzecznego
/// (`crossSlopePercent`) oraz ekspozycji stoku względem stron świata (`slopeAspectRadians`).
class SlopeExposureProfile {
  /// Nachylenie podłużne drogi w procentach [%] (+ podjazd, - zjazd).
  final double gradientPercent;

  /// Przechył poprzeczny asfaltu / zbocza w procentach [%] (+ w prawo, - w lewo).
  final double crossSlopePercent;

  /// Azymut ekspozycji zbocza w płaszczyźnie poziomej X-Z [rad] (0 = N, pi/2 = E, pi = S, 3pi/2 = W).
  /// Określa, w którą stronę zwrócone jest zbocze doliny/góry.
  final double slopeAspectRadians;

  /// Współczynnik zacienienia terenowego (np. północna ściana doliny = 0.0..0.4, słoneczny grzbiet = 1.0).
  final double terrainExposureFactor;

  const SlopeExposureProfile({
    this.gradientPercent = 0.0,
    this.crossSlopePercent = 0.0,
    this.slopeAspectRadians = math.pi,
    this.terrainExposureFactor = 1.0,
  });

  /// Ekspozycja słoneczna południowego stoku alpejskiego (pełne ostre słońce).
  const SlopeExposureProfile.sunnySouthAspect({
    this.gradientPercent = 0.0,
    this.crossSlopePercent = 0.0,
  })  : slopeAspectRadians = math.pi,
        terrainExposureFactor = 1.0;

  /// Ekspozycja zacienionego północnego stoku doliny (miękkie, rozproszone cienie).
  const SlopeExposureProfile.shadedNorthAspect({
    this.gradientPercent = 0.0,
    this.crossSlopePercent = 0.0,
  })  : slopeAspectRadians = 0.0,
        terrainExposureFactor = 0.42;

  SlopeExposureProfile copyWith({
    double? gradientPercent,
    double? crossSlopePercent,
    double? slopeAspectRadians,
    double? terrainExposureFactor,
  }) {
    return SlopeExposureProfile(
      gradientPercent: gradientPercent ?? this.gradientPercent,
      crossSlopePercent: crossSlopePercent ?? this.crossSlopePercent,
      slopeAspectRadians: slopeAspectRadians ?? this.slopeAspectRadians,
      terrainExposureFactor: terrainExposureFactor ?? this.terrainExposureFactor,
    );
  }
}

/// Konfiguracja renderera miękkich cieni planarnych [ProjectedPlanarShadowsPainter].
class PlanarShadowsConfig {
  final bool enableRiderAndBikeShadows;
  final bool enableTreeShadows;
  final bool enableGateShadows;
  final PlanarShadowQuality quality;
  final double maxShadowDistanceMeters;
  final double maxShadowStretchMultiplier;
  final double penumbraSoftnessScale;

  const PlanarShadowsConfig({
    this.enableRiderAndBikeShadows = true,
    this.enableTreeShadows = true,
    this.enableGateShadows = true,
    this.quality = PlanarShadowQuality.high,
    this.maxShadowDistanceMeters = 185.0,
    this.maxShadowStretchMultiplier = 4.5,
    this.penumbraSoftnessScale = 1.0,
  });
}

/// Wyliczony stan słońca i miękkości cienia dla godziny etapu (11:00–17:30) i ekspozycji zbocza.
class PlanarSunProjectionState {
  /// Jednostkowy wektor wskazujący DO źródła światła słonecznego w przestrzeni 3D świata.
  final Vector3 sunDirectionWorld;

  /// Kąt elewacji słońca nad horyzontem [rad].
  final double sunElevationRadians;

  /// Kąt azymutu słońca [rad] (0 = N, pi/2 = E, pi = S, 3pi/2 = W).
  final double sunAzimuthRadians;

  /// Bazowe krycie rdzenia cienia (umbra) [0.0..1.0].
  final double umbraOpacity;

  /// Bazowe krycie półcienia (penumbra) [0.0..1.0].
  final double penumbraOpacity;

  /// Rozszerzenie półcienia w metrach na każdy metr wysokości obiektu.
  final double penumbraSpreadPerMeter;

  /// Współczynnik ekspozycji zbocza [0.15..1.0] uwzględniający kąt padania na stok.
  final double slopeIncidenceFactor;

  /// Kolor rdzenia cienia na asfalcie (lekko ocieplony lub ochłodzony zależnie od pory dnia).
  final Color shadowCoreColor;

  const PlanarSunProjectionState({
    required this.sunDirectionWorld,
    required this.sunElevationRadians,
    required this.sunAzimuthRadians,
    required this.umbraOpacity,
    required this.penumbraOpacity,
    required this.penumbraSpreadPerMeter,
    required this.slopeIncidenceFactor,
    required this.shadowCoreColor,
  });
}

/// Dane wejściowe pojedynczego kolarza i jego roweru do rzutowania cienia planarnego.
class PlanarShadowRiderInput {
  final String riderId;
  final Vector3 baseWorldPosition;
  final Vector3 roadTangent;
  final Vector3 roadRight;
  final Vector3 roadNormal;
  final double leanAngleRadians;
  final double riderHeightMeters;
  final double wheelbaseMeters;
  final bool isStanding;
  final bool isAeroTuck;
  final bool isCrashed;
  final bool isSelected;
  final double roadGradientPercent;

  const PlanarShadowRiderInput({
    required this.riderId,
    required this.baseWorldPosition,
    required this.roadTangent,
    required this.roadRight,
    required this.roadNormal,
    this.leanAngleRadians = 0.0,
    this.riderHeightMeters = 1.48,
    this.wheelbaseMeters = 1.02,
    this.isStanding = false,
    this.isAeroTuck = false,
    this.isCrashed = false,
    this.isSelected = false,
    this.roadGradientPercent = 0.0,
  });

  /// Buduje dane cienia z modelu silnika [Peloton3dRiderRenderData] i próbki drogi [Peloton3dRoadNode].
  factory PlanarShadowRiderInput.fromPeloton3d({
    required Peloton3dRiderRenderData rider,
    required Peloton3dRoadNode roadNode,
    bool isSelected = false,
  }) {
    final Vector3 basePos = roadNode.center + (roadNode.right * rider.lateralOffsetMeters);
    final bool isAero = !rider.isStanding && (rider.isSprinting || rider.speedMs > 14.5);
    final double height = rider.isCrashed
        ? 0.42
        : (rider.isStanding ? 1.66 : (isAero ? 1.24 : 1.48));

    return PlanarShadowRiderInput(
      riderId: rider.riderId,
      baseWorldPosition: basePos,
      roadTangent: roadNode.tangent,
      roadRight: roadNode.right,
      roadNormal: roadNode.normal,
      leanAngleRadians: rider.leanAngleRad,
      riderHeightMeters: height,
      wheelbaseMeters: 1.02,
      isStanding: rider.isStanding,
      isAeroTuck: isAero,
      isCrashed: rider.isCrashed,
      isSelected: isSelected,
      roadGradientPercent: roadNode.gradientPercent,
    );
  }
}

/// Dane wejściowe drzewa przydrożnego do rzutowania miękkiego cienia na powierzchnię asfaltu.
class PlanarShadowTreeInput {
  final String id;
  final PlanarTreeSpecies species;
  final Vector3 baseWorldPosition;
  final Vector3 roadPlaneOrigin;
  final Vector3 roadNormal;
  final Vector3 roadTangent;
  final Vector3 roadRight;
  final double heightMeters;
  final double canopyRadiusMeters;

  const PlanarShadowTreeInput({
    required this.id,
    required this.species,
    required this.baseWorldPosition,
    required this.roadPlaneOrigin,
    required this.roadNormal,
    required this.roadTangent,
    required this.roadRight,
    this.heightMeters = 9.0,
    this.canopyRadiusMeters = 2.6,
  });

  /// Buduje dane cienia drzewa z obiektu sceny [Peloton3dSceneryProp].
  factory PlanarShadowTreeInput.fromSceneryProp({
    required Peloton3dSceneryProp prop,
    Vector3? roadPlaneOrigin,
  }) {
    final PlanarTreeSpecies species;
    final double baseHeight;
    final double baseRadius;

    switch (prop.type) {
      case Peloton3dPropType.pineTree:
        species = PlanarTreeSpecies.pine;
        baseHeight = 9.5;
        baseRadius = 2.3;
      case Peloton3dPropType.cypressTree:
        species = PlanarTreeSpecies.cypress;
        baseHeight = 11.2;
        baseRadius = 1.25;
      case Peloton3dPropType.deciduousTree:
      default:
        species = PlanarTreeSpecies.deciduous;
        baseHeight = 8.4;
        baseRadius = 3.1;
    }

    return PlanarShadowTreeInput(
      id: prop.id,
      species: species,
      baseWorldPosition: prop.position,
      roadPlaneOrigin: roadPlaneOrigin ?? prop.position,
      roadNormal: prop.normal,
      roadTangent: prop.tangent,
      roadRight: prop.right,
      heightMeters: baseHeight * prop.scale,
      canopyRadiusMeters: baseRadius * prop.scale,
    );
  }
}

/// Dane wejściowe bramy (KM, Flamme Rouge, Meta) do rzutowania cienia na asfalt.
class PlanarShadowGateInput {
  final String id;
  final PlanarGateKind kind;
  final Vector3 centerWorldPosition;
  final Vector3 roadTangent;
  final Vector3 roadRight;
  final Vector3 roadNormal;
  final double spanWidthMeters;
  final double archHeightMeters;
  final double bannerDepthMeters;
  final double bannerHeightMeters;

  const PlanarShadowGateInput({
    required this.id,
    required this.kind,
    required this.centerWorldPosition,
    required this.roadTangent,
    required this.roadRight,
    required this.roadNormal,
    this.spanWidthMeters = 8.6,
    this.archHeightMeters = 5.4,
    this.bannerDepthMeters = 0.85,
    this.bannerHeightMeters = 1.25,
  });

  /// Buduje dane cienia bramy z obiektu sceny [Peloton3dSceneryProp].
  factory PlanarShadowGateInput.fromSceneryProp(Peloton3dSceneryProp prop) {
    final PlanarGateKind kind;
    final double span;
    final double height;
    final double bannerH;

    switch (prop.type) {
      case Peloton3dPropType.finishGantry:
        kind = PlanarGateKind.finishGantry;
        span = 9.2 * prop.scale;
        height = 5.9 * prop.scale;
        bannerH = 1.45 * prop.scale;
      case Peloton3dPropType.flammeRougeGate:
        kind = PlanarGateKind.flammeRougeGate;
        span = 8.4 * prop.scale;
        height = 5.3 * prop.scale;
        bannerH = 1.25 * prop.scale;
      case Peloton3dPropType.kilometerGate:
      default:
        kind = PlanarGateKind.kilometerGate;
        span = 8.2 * prop.scale;
        height = 5.0 * prop.scale;
        bannerH = 1.05 * prop.scale;
    }

    return PlanarShadowGateInput(
      id: prop.id,
      kind: kind,
      centerWorldPosition: prop.position,
      roadTangent: prop.tangent,
      roadRight: prop.right,
      roadNormal: prop.normal,
      spanWidthMeters: span,
      archHeightMeters: height,
      bannerDepthMeters: 0.85 * prop.scale,
      bannerHeightMeters: bannerH,
    );
  }
}

/// Renderer rzutowanych miękkich cieni planarnych na powierzchnię asfaltu dla kolarzy,
/// rowerów, drzew oraz bram (KM / Flamme Rouge / Meta).
///
/// Uwzględnia rzeczywisty kąt słońca w przedziale godzin etapu $11:00–17:30$ (oraz
/// płynny fallback dla innych godzin), pogodę, lokalne nachylenie drogi oraz ekspozycję zbocza.
class ProjectedPlanarShadowsPainter extends CustomPainter {
  final Scene3DMathProjection? projection;
  final StageTimeOfDay timeOfDay;
  final WeatherCondition weatherCondition;
  final SlopeExposureProfile slopeExposure;
  final PlanarShadowsConfig config;
  final List<PlanarShadowRiderInput> riders;
  final List<PlanarShadowTreeInput> trees;
  final List<PlanarShadowGateInput> gates;
  final double elapsedSeconds;

  // Zbuforowane obiekty Paint w celu eliminacji alokacji podczas renderowania 60/120 FPS.
  static final Paint _penumbraFillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _umbraFillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _contactAoPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _bikeLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final Paint _bikePenumbraLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  const ProjectedPlanarShadowsPainter({
    this.projection,
    this.timeOfDay = const StageTimeOfDay.morningStart(),
    this.weatherCondition = WeatherCondition.sunny,
    this.slopeExposure = const SlopeExposureProfile(),
    this.config = const PlanarShadowsConfig(),
    this.riders = const [],
    this.trees = const [],
    this.gates = const [],
    this.elapsedSeconds = 0.0,
  });

  /// Wylicza precyzyjny stan kąta słońca i miękkości cieni dla godziny etapu ($11:00–17:30$)
  /// oraz ekspozycji zbocza [slopeExposure].
  static PlanarSunProjectionState computeSunProjectionState({
    required StageTimeOfDay timeOfDay,
    required WeatherCondition weatherCondition,
    SlopeExposureProfile slopeExposure = const SlopeExposureProfile(),
    double elapsedSeconds = 0.0,
  }) {
    final double hours = timeOfDay.decimalHours;
    // Normalizacja okna etapowego 11:00 (11.0) -> 17:30 (17.5).
    final double stageWindowT = ((hours - 11.0) / 6.5).clamp(0.0, 1.0);

    // Elewacja słońca w oknie 11:00–17:30:
    // ~54° o 11:00, szczyt ~63° o 13:15, łagodne opadanie do ~13.5° o 17:30 (Golden Hour).
    final double sunElevationDeg;
    if (hours >= 11.0 && hours <= 17.5) {
      final double noonOffset = (hours - 13.25) / 4.25;
      sunElevationDeg = (63.0 - 49.5 * (noonOffset * noonOffset)).clamp(13.5, 63.0);
    } else {
      final SunLightState fallbackState = DynamicSkyboxAndLightingPainter.computeSunLightState(
        timeOfDay: timeOfDay,
        weatherCondition: weatherCondition,
        elapsedSeconds: elapsedSeconds,
      );
      sunElevationDeg = (fallbackState.sunElevationRadians * (180.0 / math.pi)).clamp(11.0, 65.0);
    }

    // Azymut słońca w oknie 11:00–17:30 przesuwa się z południowego wschodu (~142°)
    // przez południe (~180° o 13:15) na zachód-południowy zachód (~262° o 17:30).
    final double sunAzimuthDeg = hours >= 11.0 && hours <= 17.5
        ? 142.0 + stageWindowT * 120.0
        : (75.0 + ((hours - 6.0).clamp(0.0, 16.0) / 16.0) * 205.0);

    final double elevRad = sunElevationDeg * (math.pi / 180.0);
    final double azimRad = sunAzimuthDeg * (math.pi / 180.0);

    final double cosElev = math.cos(elevRad);
    final Vector3 sunDir = Vector3(
      math.sin(azimRad) * cosElev,
      math.sin(elevRad),
      math.cos(azimRad) * cosElev,
    )..normalize();

    // Wpływ ekspozycji zbocza: wyznaczamy przybliżony wektor normalny zbocza z gradientu,
    // przechyłu oraz azymutu ekspozycji i liczymy cosinus kąta padania słońca na stok.
    final double slopeTiltRad = math.atan(
      math.sqrt(
        (slopeExposure.gradientPercent * slopeExposure.gradientPercent +
                slopeExposure.crossSlopePercent * slopeExposure.crossSlopePercent) /
            10000.0,
      ),
    );
    final Vector3 aspectDir = Vector3(
      math.sin(slopeExposure.slopeAspectRadians),
      0.0,
      math.cos(slopeExposure.slopeAspectRadians),
    );
    final Vector3 hillsideNormal = Vector3(
      aspectDir.x * math.sin(slopeTiltRad),
      math.cos(slopeTiltRad),
      aspectDir.z * math.sin(slopeTiltRad),
    )..normalize();

    final double rawHillIncidence = sunDir.dot(hillsideNormal);
    final double slopeIncidenceFactor =
        ((rawHillIncidence.clamp(0.15, 1.0)) * slopeExposure.terrainExposureFactor.clamp(0.2, 1.0))
            .clamp(0.18, 1.0);

    // Krycie i miękkość zależna od pogody oraz kąta słońca (im niżej słońce i słabsza ekspozycja,
    // tym bardziej rozmyty półcień penumbry).
    double baseUmbra;
    double weatherSoftnessBoost;
    switch (weatherCondition) {
      case WeatherCondition.sunny:
        baseUmbra = 0.44 + (1.0 - stageWindowT) * 0.06;
        weatherSoftnessBoost = 1.0;
      case WeatherCondition.extremeHeat:
        baseUmbra = 0.48 + (1.0 - stageWindowT) * 0.06;
        weatherSoftnessBoost = 0.88;
      case WeatherCondition.overcast:
        baseUmbra = 0.22;
        weatherSoftnessBoost = 2.15;
      case WeatherCondition.crosswindGale:
        baseUmbra = 0.28;
        weatherSoftnessBoost = 1.65;
      case WeatherCondition.lightRain:
        baseUmbra = 0.16;
        weatherSoftnessBoost = 2.45;
      case WeatherCondition.heavyStorm:
        baseUmbra = 0.13;
        weatherSoftnessBoost = 2.75;
    }

    // Zbocze w głębokim cieniu zmiękcza kontrast umbry i zwiększa udział półcienia.
    final double effectiveUmbra =
        (baseUmbra * (0.45 + 0.55 * slopeIncidenceFactor)).clamp(0.08, 0.54);
    final double effectivePenumbra = (effectiveUmbra * 0.48).clamp(0.04, 0.28);

    // Rozszerzenie półcienia rośnie przy niższym słońcu (Golden Hour 17:00–17:30) i na zacienionym zboczu.
    final double lowSunSpread = (1.0 / math.sin(elevRad).clamp(0.22, 1.0)) * 0.085;
    final double penumbraSpreadPerMeter =
        (lowSunSpread * weatherSoftnessBoost * (1.25 - 0.35 * slopeIncidenceFactor))
            .clamp(0.06, 0.45);

    // Subtelny odcień cienia: chłodny granatowo-grafitowy w pełnym słońcu, nieco głębszy w Golden Hour.
    final Color shadowCoreColor = Color.lerp(
      const Color(0xFF060912),
      const Color(0xFF0B0A16),
      stageWindowT * 0.65,
    )!;

    return PlanarSunProjectionState(
      sunDirectionWorld: sunDir,
      sunElevationRadians: elevRad,
      sunAzimuthRadians: azimRad,
      umbraOpacity: effectiveUmbra,
      penumbraOpacity: effectivePenumbra,
      penumbraSpreadPerMeter: penumbraSpreadPerMeter,
      slopeIncidenceFactor: slopeIncidenceFactor,
      shadowCoreColor: shadowCoreColor,
    );
  }

  /// Wyznacza rzeczywistą normalną płaszczyzny asfaltu z uwzględnieniem nachylenia drogi
  /// oraz przechyłu poprzecznego zbocza.
  static Vector3 resolveAsphaltPlaneNormal({
    required Vector3 roadTangent,
    required Vector3 roadNormal,
    double roadGradientPercent = 0.0,
    SlopeExposureProfile? slopeExposure,
  }) {
    Vector3 normal = roadNormal.length2 > 1e-6 ? roadNormal.normalized() : Vector3(0.0, 1.0, 0.0);
    final Vector3 tangent =
        roadTangent.length2 > 1e-6 ? roadTangent.normalized() : Vector3(0.0, 0.0, 1.0);

    if (roadGradientPercent.abs() > 0.01) {
      final double slopeRad = math.atan(roadGradientPercent / 100.0);
      final Vector3 horizDir = Vector3(tangent.x, 0.0, tangent.z);
      if (horizDir.length2 > 1e-6) {
        horizDir.normalize();
        normal = Vector3(
          -horizDir.x * math.sin(slopeRad),
          math.cos(slopeRad),
          -horizDir.z * math.sin(slopeRad),
        )..normalize();
      }
    }

    if (slopeExposure != null && slopeExposure.crossSlopePercent.abs() > 0.01) {
      final double crossRad = math.atan(slopeExposure.crossSlopePercent / 100.0);
      final Vector3 right = tangent.cross(normal);
      if (right.length2 > 1e-6) {
        right.normalize();
        normal = (normal * math.cos(crossRad) - right * math.sin(crossRad))..normalize();
      }
    }

    return normal;
  }

  /// Rzutuje dowolny punkt 3D [worldPoint] wzdłuż promienia słonecznego `-sunDirectionWorld`
  /// na płaszczyznę asfaltu zdefiniowaną przez [planeOrigin] i [planeNormal].
  ///
  /// Długość rzutu jest ograniczona przez [maxStretchMultiplier], co zabezpiecza przed
  /// nienaturalnym rozciąganiem cieni na ekstremalnych stokach o zmierzchu.
  static Vector3 projectWorldPointOntoAsphaltPlane({
    required Vector3 worldPoint,
    required Vector3 planeOrigin,
    required Vector3 planeNormal,
    required Vector3 sunDirectionWorld,
    double maxStretchMultiplier = 4.5,
  }) {
    final Vector3 n = planeNormal.normalized();
    final Vector3 l = sunDirectionWorld.normalized();
    final double heightAbovePlane = (worldPoint - planeOrigin).dot(n);

    if (heightAbovePlane <= 0.001) {
      // Punkt leży na lub pod płaszczyzną asfaltu — sprowadzamy go bezpośrednio na powierzchnię.
      return worldPoint - (n * heightAbovePlane) + (n * 0.006);
    }

    final double lDotN = l.dot(n).clamp(0.18, 1.0);
    final double rayT =
        (heightAbovePlane / lDotN).clamp(0.0, heightAbovePlane * maxStretchMultiplier);

    final Vector3 rawProjected = worldPoint - (l * rayT);
    // Rzutowanie ortogonalne na płaszczyznę asfaltu eliminuje błąd numeryczny i zapobiega z-fightingowi.
    final double residual = (rawProjected - planeOrigin).dot(n);
    return rawProjected - (n * residual) + (n * 0.006);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Scene3DMathProjection? activeProj = projection;
    if (activeProj == null) return;

    paintAllShadows(
      canvas: canvas,
      size: size,
      projection: activeProj,
    );
  }

  /// Główna metoda renderująca wszystkie włączone warstwy miękkich cieni planarnych:
  /// bramy, drzewa oraz kolarzy wraz z rowerami.
  void paintAllShadows({
    required Canvas canvas,
    required Size size,
    required Scene3DMathProjection projection,
  }) {
    final PlanarSunProjectionState sunState = computeSunProjectionState(
      timeOfDay: timeOfDay,
      weatherCondition: weatherCondition,
      slopeExposure: slopeExposure,
      elapsedSeconds: elapsedSeconds,
    );

    if (config.enableGateShadows && gates.isNotEmpty) {
      for (final gate in gates) {
        paintGatePlanarShadow(
          canvas: canvas,
          projection: projection,
          gate: gate,
          sunState: sunState,
        );
      }
    }

    if (config.enableTreeShadows && trees.isNotEmpty) {
      for (final tree in trees) {
        paintTreePlanarShadow(
          canvas: canvas,
          projection: projection,
          tree: tree,
          sunState: sunState,
        );
      }
    }

    if (config.enableRiderAndBikeShadows && riders.isNotEmpty) {
      for (final rider in riders) {
        paintRiderAndBikePlanarShadow(
          canvas: canvas,
          projection: projection,
          rider: rider,
          sunState: sunState,
        );
      }
    }
  }

  /// Renderuje miękki cień planarny pojedynczego kolarza i jego roweru na powierzchni asfaltu.
  void paintRiderAndBikePlanarShadow({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required PlanarShadowRiderInput rider,
    required PlanarSunProjectionState sunState,
  }) {
    final ProjectedPoint3D pCenter = projection.worldToScreen(rider.baseWorldPosition);
    if (!pCenter.isInFrontOfCamera) return;
    if (pCenter.depthEye > config.maxShadowDistanceMeters) return;

    final double distFade =
        (1.0 - (pCenter.depthEye / config.maxShadowDistanceMeters)).clamp(0.0, 1.0);
    final double umbraAlpha = (sunState.umbraOpacity * distFade).clamp(0.03, 0.56);
    final double penumbraAlpha = (sunState.penumbraOpacity * distFade).clamp(0.015, 0.28);

    final Vector3 tangent =
        rider.roadTangent.length2 > 1e-6 ? rider.roadTangent.normalized() : Vector3(0.0, 0.0, 1.0);
    final Vector3 right =
        rider.roadRight.length2 > 1e-6 ? rider.roadRight.normalized() : Vector3(1.0, 0.0, 0.0);
    final Vector3 planeNormal = resolveAsphaltPlaneNormal(
      roadTangent: tangent,
      roadNormal: rider.roadNormal,
      roadGradientPercent: rider.roadGradientPercent,
      slopeExposure: slopeExposure,
    );

    // Pochylenie roweru w zakręcie odchyla górne punkty sylwetki i ramy w bok.
    final double leanSin = math.sin(rider.leanAngleRadians);
    final double leanCos = math.cos(rider.leanAngleRadians).clamp(0.45, 1.0);
    Vector3 bikeUp(double height) =>
        (planeNormal * (height * leanCos)) + (right * (height * leanSin));

    final double halfWb = rider.wheelbaseMeters * 0.5;
    final Vector3 rearContact = rider.baseWorldPosition - (tangent * halfWb);
    final Vector3 frontContact = rider.baseWorldPosition + (tangent * halfWb);

    // Kluczowe punkty roweru w 3D (rama, koła, siodełko, kierownica).
    final Vector3 rearWheelTop = rearContact + bikeUp(0.67);
    final Vector3 frontWheelTop = frontContact + bikeUp(0.67);
    final Vector3 saddleWorld = rider.baseWorldPosition - (tangent * 0.14) + bikeUp(0.95);
    final Vector3 handlebarWorld = rider.baseWorldPosition + (tangent * 0.36) + bikeUp(0.89);

    // Kluczowe punkty kolarza w 3D (tułów, ramiona, głowa w kasku).
    final double torsoFwd = rider.isStanding ? 0.16 : (rider.isAeroTuck ? 0.34 : 0.20);
    final double headFwd = rider.isStanding ? 0.28 : (rider.isAeroTuck ? 0.48 : 0.32);
    final double shoulderHeight = rider.riderHeightMeters * 0.80;
    final double shoulderHalfSpan = rider.isAeroTuck ? 0.17 : 0.22;

    final Vector3 shoulderCenter =
        rider.baseWorldPosition + (tangent * torsoFwd) + bikeUp(shoulderHeight);
    final Vector3 shoulderLeft = shoulderCenter - (right * shoulderHalfSpan);
    final Vector3 shoulderRight = shoulderCenter + (right * shoulderHalfSpan);
    final Vector3 headTop =
        rider.baseWorldPosition + (tangent * headFwd) + bikeUp(rider.riderHeightMeters);

    // Rzutowanie planarne wszystkich punktów roweru i kolarza na płaszczyznę asfaltu.
    Vector3 projPlane(Vector3 pt) => projectWorldPointOntoAsphaltPlane(
          worldPoint: pt,
          planeOrigin: rider.baseWorldPosition,
          planeNormal: planeNormal,
          sunDirectionWorld: sunState.sunDirectionWorld,
          maxStretchMultiplier: config.maxShadowStretchMultiplier,
        );

    final ProjectedPoint3D sRear = projection.worldToScreen(projPlane(rearContact));
    final ProjectedPoint3D sFront = projection.worldToScreen(projPlane(frontContact));
    final ProjectedPoint3D sRearTop = projection.worldToScreen(projPlane(rearWheelTop));
    final ProjectedPoint3D sFrontTop = projection.worldToScreen(projPlane(frontWheelTop));
    final ProjectedPoint3D sSaddle = projection.worldToScreen(projPlane(saddleWorld));
    final ProjectedPoint3D sBar = projection.worldToScreen(projPlane(handlebarWorld));
    final ProjectedPoint3D sShoulderL = projection.worldToScreen(projPlane(shoulderLeft));
    final ProjectedPoint3D sShoulderR = projection.worldToScreen(projPlane(shoulderRight));
    final ProjectedPoint3D sHead = projection.worldToScreen(projPlane(headTop));

    if (!sRear.isInFrontOfCamera || !sFront.isInFrontOfCamera || !sHead.isInFrontOfCamera) {
      return;
    }

    final Offset rearPt = Offset(sRear.screenX, sRear.screenY);
    final Offset frontPt = Offset(sFront.screenX, sFront.screenY);
    final Offset rearTopPt = Offset(sRearTop.screenX, sRearTop.screenY);
    final Offset frontTopPt = Offset(sFrontTop.screenX, sFrontTop.screenY);
    final Offset saddlePt = Offset(sSaddle.screenX, sSaddle.screenY);
    final Offset barPt = Offset(sBar.screenX, sBar.screenY);
    final Offset shoulderLPt = Offset(sShoulderL.screenX, sShoulderL.screenY);
    final Offset shoulderRPt = Offset(sShoulderR.screenX, sShoulderR.screenY);
    final Offset headPt = Offset(sHead.screenX, sHead.screenY);

    final bool highQualityNear =
        config.quality == PlanarShadowQuality.high && pCenter.depthEye < 38.0;

    // 1. Miękki półcień (penumbra) sylwetki kolarza i roweru.
    if (config.quality != PlanarShadowQuality.performance) {
      final double spreadPx = (pCenter.perspectiveScale *
              sunState.penumbraSpreadPerMeter *
              14.0 *
              config.penumbraSoftnessScale)
          .clamp(1.2, 16.0);

      final Path penumbraPath = _buildExpandedRiderPolygon(
        rearPt: rearPt,
        frontPt: frontPt,
        shoulderLPt: shoulderLPt,
        shoulderRPt: shoulderRPt,
        headPt: headPt,
        expandPx: spreadPx,
      );

      _penumbraFillPaint
        ..color = sunState.shadowCoreColor.withValues(alpha: penumbraAlpha)
        ..maskFilter = highQualityNear
            ? MaskFilter.blur(BlurStyle.normal, (spreadPx * 0.45).clamp(1.0, 6.0))
            : null;
      canvas.drawPath(penumbraPath, _penumbraFillPaint);
      _penumbraFillPaint.maskFilter = null;
    }

    // 2. Rdzeń cienia (umbra) sylwetki kolarza.
    final Path riderUmbraPath = _buildRiderPolygon(
      rearPt: rearPt,
      frontPt: frontPt,
      shoulderLPt: shoulderLPt,
      shoulderRPt: shoulderRPt,
      headPt: headPt,
    );
    _umbraFillPaint.color = sunState.shadowCoreColor.withValues(alpha: umbraAlpha * 0.78);
    canvas.drawPath(riderUmbraPath, _umbraFillPaint);

    // 3. Planarne rzutowanie geometrii roweru (koła + trójkąt ramy + widelec).
    final double bikeStrokePx = (pCenter.perspectiveScale * 1.9).clamp(1.0, 5.5);
    if (config.quality != PlanarShadowQuality.performance) {
      _bikePenumbraLinePaint
        ..color = sunState.shadowCoreColor.withValues(alpha: penumbraAlpha * 0.95)
        ..strokeWidth = bikeStrokePx * 2.1;
      canvas.drawLine(rearPt, rearTopPt, _bikePenumbraLinePaint);
      canvas.drawLine(frontPt, frontTopPt, _bikePenumbraLinePaint);
      canvas.drawLine(saddlePt, barPt, _bikePenumbraLinePaint);
    }

    _bikeLinePaint
      ..color = sunState.shadowCoreColor.withValues(alpha: umbraAlpha * 0.92)
      ..strokeWidth = bikeStrokePx;
    canvas.drawLine(rearPt, rearTopPt, _bikeLinePaint);
    canvas.drawLine(frontPt, frontTopPt, _bikeLinePaint);
    canvas.drawLine(rearPt, saddlePt, _bikeLinePaint);
    canvas.drawLine(saddlePt, barPt, _bikeLinePaint);
    canvas.drawLine(barPt, frontPt, _bikeLinePaint);

    // 4. Cień kontaktowy AO pod oponami roweru na asfalcie.
    final Offset midWheel = Offset((rearPt.dx + frontPt.dx) * 0.5, (rearPt.dy + frontPt.dy) * 0.5);
    final double aoWidth = (frontPt - rearPt).distance.clamp(4.0, 90.0) * 1.08;
    final double aoHeight = (pCenter.perspectiveScale * 4.2).clamp(1.5, 16.0);
    final double bikeAngle = math.atan2(frontPt.dy - rearPt.dy, frontPt.dx - rearPt.dx);

    canvas.save();
    canvas.translate(midWheel.dx, midWheel.dy);
    canvas.rotate(bikeAngle);
    _contactAoPaint.color = sunState.shadowCoreColor.withValues(
      alpha: (umbraAlpha * (rider.isSelected ? 1.18 : 1.05)).clamp(0.06, 0.65),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: aoWidth, height: aoHeight),
      _contactAoPaint,
    );
    canvas.restore();
  }

  /// Renderuje miękki cień planarny drzewa (sosna, drzewo liściaste, cyprys) na powierzchnię asfaltu.
  void paintTreePlanarShadow({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required PlanarShadowTreeInput tree,
    required PlanarSunProjectionState sunState,
  }) {
    final ProjectedPoint3D pBase = projection.worldToScreen(tree.baseWorldPosition);
    if (!pBase.isInFrontOfCamera) return;
    if (pBase.depthEye > config.maxShadowDistanceMeters) return;

    final double distFade =
        (1.0 - (pBase.depthEye / config.maxShadowDistanceMeters)).clamp(0.0, 1.0);
    final double umbraAlpha = (sunState.umbraOpacity * distFade * 0.92).clamp(0.03, 0.52);
    final double penumbraAlpha = (sunState.penumbraOpacity * distFade * 0.95).clamp(0.015, 0.25);

    final Vector3 tangent =
        tree.roadTangent.length2 > 1e-6 ? tree.roadTangent.normalized() : Vector3(0.0, 0.0, 1.0);
    final Vector3 right =
        tree.roadRight.length2 > 1e-6 ? tree.roadRight.normalized() : Vector3(1.0, 0.0, 0.0);
    final Vector3 planeNormal = resolveAsphaltPlaneNormal(
      roadTangent: tangent,
      roadNormal: tree.roadNormal,
      slopeExposure: slopeExposure,
    );

    Vector3 projPlane(Vector3 pt) => projectWorldPointOntoAsphaltPlane(
          worldPoint: pt,
          planeOrigin: tree.roadPlaneOrigin,
          planeNormal: planeNormal,
          sunDirectionWorld: sunState.sunDirectionWorld,
          maxStretchMultiplier: config.maxShadowStretchMultiplier,
        );

    final Vector3 trunkBaseOnPlane = projPlane(tree.baseWorldPosition);
    final Vector3 crownStartWorld =
        tree.baseWorldPosition + (planeNormal * (tree.heightMeters * 0.30));
    final Vector3 crownMidWorld =
        tree.baseWorldPosition + (planeNormal * (tree.heightMeters * 0.62));
    final Vector3 crownTipWorld = tree.baseWorldPosition + (planeNormal * tree.heightMeters);

    final Vector3 crownStartShadow = projPlane(crownStartWorld);
    final Vector3 crownMidShadow = projPlane(crownMidWorld);
    final Vector3 crownTipShadow = projPlane(crownTipWorld);

    // Wyznaczamy kierunek poprzeczny do cienia na płaszczyźnie asfaltu.
    Vector3 shadowAxis = crownTipShadow - trunkBaseOnPlane;
    if (shadowAxis.length2 < 1e-5) {
      shadowAxis = right;
    } else {
      shadowAxis.normalize();
    }
    final Vector3 shadowPerp = planeNormal.cross(shadowAxis)..normalize();

    final double r = tree.canopyRadiusMeters;
    final double spreadMeters =
        tree.heightMeters * sunState.penumbraSpreadPerMeter * 0.28 * config.penumbraSoftnessScale;

    final List<Vector3> umbraWorldPoints;
    final List<Vector3> penumbraWorldPoints;

    switch (tree.species) {
      case PlanarTreeSpecies.pine:
        umbraWorldPoints = <Vector3>[
          trunkBaseOnPlane - (shadowPerp * (r * 0.16)),
          crownStartShadow - (shadowPerp * (r * 1.05)),
          crownMidShadow - (shadowPerp * (r * 0.62)),
          crownTipShadow,
          crownMidShadow + (shadowPerp * (r * 0.62)),
          crownStartShadow + (shadowPerp * (r * 1.05)),
          trunkBaseOnPlane + (shadowPerp * (r * 0.16)),
        ];
        penumbraWorldPoints = _expandWorldPolygonOutward(
          points: umbraWorldPoints,
          centroid: crownMidShadow,
          expandMeters: spreadMeters,
        );
      case PlanarTreeSpecies.cypress:
        umbraWorldPoints = <Vector3>[
          trunkBaseOnPlane - (shadowPerp * (r * 0.20)),
          crownStartShadow - (shadowPerp * (r * 0.85)),
          crownMidShadow - (shadowPerp * (r * 0.68)),
          crownTipShadow,
          crownMidShadow + (shadowPerp * (r * 0.68)),
          crownStartShadow + (shadowPerp * (r * 0.85)),
          trunkBaseOnPlane + (shadowPerp * (r * 0.20)),
        ];
        penumbraWorldPoints = _expandWorldPolygonOutward(
          points: umbraWorldPoints,
          centroid: crownMidShadow,
          expandMeters: spreadMeters * 0.85,
        );
      case PlanarTreeSpecies.deciduous:
        final Vector3 crownCenter = Vector3(
          (crownStartShadow.x + crownTipShadow.x) * 0.5,
          (crownStartShadow.y + crownTipShadow.y) * 0.5,
          (crownStartShadow.z + crownTipShadow.z) * 0.5,
        );
        final double halfLen = ((crownTipShadow - crownStartShadow).length * 0.5).clamp(r * 0.8, 28.0);
        umbraWorldPoints = <Vector3>[
          trunkBaseOnPlane - (shadowPerp * (r * 0.22)),
          crownStartShadow - (shadowPerp * (r * 0.78)),
          crownCenter - (shadowPerp * (r * 1.08)),
          crownCenter + (shadowAxis * (halfLen * 0.65)) - (shadowPerp * (r * 0.82)),
          crownTipShadow,
          crownCenter + (shadowAxis * (halfLen * 0.65)) + (shadowPerp * (r * 0.82)),
          crownCenter + (shadowPerp * (r * 1.08)),
          crownStartShadow + (shadowPerp * (r * 0.78)),
          trunkBaseOnPlane + (shadowPerp * (r * 0.22)),
        ];
        penumbraWorldPoints = _expandWorldPolygonOutward(
          points: umbraWorldPoints,
          centroid: crownCenter,
          expandMeters: spreadMeters * 1.15,
        );
    }

    if (config.quality != PlanarShadowQuality.performance) {
      final Path? penumbraPath = _projectWorldPolygonToPath(projection, penumbraWorldPoints);
      if (penumbraPath != null) {
        _penumbraFillPaint
          ..color = sunState.shadowCoreColor.withValues(alpha: penumbraAlpha)
          ..maskFilter = (config.quality == PlanarShadowQuality.high && pBase.depthEye < 45.0)
              ? const MaskFilter.blur(BlurStyle.normal, 4.0)
              : null;
        canvas.drawPath(penumbraPath, _penumbraFillPaint);
        _penumbraFillPaint.maskFilter = null;
      }
    }

    final Path? umbraPath = _projectWorldPolygonToPath(projection, umbraWorldPoints);
    if (umbraPath != null) {
      _umbraFillPaint.color = sunState.shadowCoreColor.withValues(alpha: umbraAlpha * 0.84);
      canvas.drawPath(umbraPath, _umbraFillPaint);
    }

    // Cień kontaktowy AO u podstawy pnia.
    final ProjectedPoint3D pTrunk = projection.worldToScreen(trunkBaseOnPlane);
    if (pTrunk.isInFrontOfCamera) {
      final double aoR = (pTrunk.perspectiveScale * r * 5.0).clamp(2.5, 28.0);
      _contactAoPaint.color = sunState.shadowCoreColor.withValues(alpha: (umbraAlpha * 1.08).clamp(0.05, 0.60));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(pTrunk.screenX, pTrunk.screenY),
          width: aoR * 1.6,
          height: aoR * 0.65,
        ),
        _contactAoPaint,
      );
    }
  }

  /// Renderuje miękki cień planarny bramy wyścigowej (KM, Flamme Rouge, Meta) na powierzchnię asfaltu.
  void paintGatePlanarShadow({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required PlanarShadowGateInput gate,
    required PlanarSunProjectionState sunState,
  }) {
    final ProjectedPoint3D pCenter = projection.worldToScreen(gate.centerWorldPosition);
    if (!pCenter.isInFrontOfCamera) return;
    if (pCenter.depthEye > config.maxShadowDistanceMeters) return;

    final double distFade =
        (1.0 - (pCenter.depthEye / config.maxShadowDistanceMeters)).clamp(0.0, 1.0);
    final double umbraAlpha = (sunState.umbraOpacity * distFade).clamp(0.03, 0.56);
    final double penumbraAlpha = (sunState.penumbraOpacity * distFade).clamp(0.015, 0.28);

    final Vector3 tangent =
        gate.roadTangent.length2 > 1e-6 ? gate.roadTangent.normalized() : Vector3(0.0, 0.0, 1.0);
    final Vector3 right =
        gate.roadRight.length2 > 1e-6 ? gate.roadRight.normalized() : Vector3(1.0, 0.0, 0.0);
    final Vector3 planeNormal = resolveAsphaltPlaneNormal(
      roadTangent: tangent,
      roadNormal: gate.roadNormal,
      slopeExposure: slopeExposure,
    );

    Vector3 projPlane(Vector3 pt) => projectWorldPointOntoAsphaltPlane(
          worldPoint: pt,
          planeOrigin: gate.centerWorldPosition,
          planeNormal: planeNormal,
          sunDirectionWorld: sunState.sunDirectionWorld,
          maxStretchMultiplier: config.maxShadowStretchMultiplier,
        );

    final double halfSpan = gate.spanWidthMeters * 0.5;
    final double halfDepth = gate.bannerDepthMeters * 0.5;
    const double pillarWidth = 0.42;

    final Vector3 leftBase = gate.centerWorldPosition - (right * halfSpan);
    final Vector3 rightBase = gate.centerWorldPosition + (right * halfSpan);
    final Vector3 leftTop = leftBase + (planeNormal * gate.archHeightMeters);
    final Vector3 rightTop = rightBase + (planeNormal * gate.archHeightMeters);

    // 4 narożniki banera/kratownicy nad jezdnią zrzutowane na płaszczyznę asfaltu.
    final double bannerBottomH = (gate.archHeightMeters - gate.bannerHeightMeters).clamp(2.5, 8.0);
    final Vector3 bLeftBack =
        leftBase + (planeNormal * bannerBottomH) - (tangent * halfDepth);
    final Vector3 bRightBack =
        rightBase + (planeNormal * bannerBottomH) - (tangent * halfDepth);
    final Vector3 bRightFront =
        rightBase + (planeNormal * gate.archHeightMeters) + (tangent * halfDepth);
    final Vector3 bLeftFront =
        leftBase + (planeNormal * gate.archHeightMeters) + (tangent * halfDepth);

    final List<Vector3> bannerShadowWorld = <Vector3>[
      projPlane(bLeftBack),
      projPlane(bRightBack),
      projPlane(bRightFront),
      projPlane(bLeftFront),
    ];

    final Vector3 bannerCentroid = (bannerShadowWorld[0] +
            bannerShadowWorld[1] +
            bannerShadowWorld[2] +
            bannerShadowWorld[3]) *
        0.25;

    final double spreadMeters =
        gate.archHeightMeters * sunState.penumbraSpreadPerMeter * 0.35 * config.penumbraSoftnessScale;

    // 1. Półcień (penumbra) górnej belki/banera bramy.
    if (config.quality != PlanarShadowQuality.performance) {
      final List<Vector3> bannerPenumbraWorld = _expandWorldPolygonOutward(
        points: bannerShadowWorld,
        centroid: bannerCentroid,
        expandMeters: spreadMeters,
      );
      final Path? penumbraPath = _projectWorldPolygonToPath(projection, bannerPenumbraWorld);
      if (penumbraPath != null) {
        _penumbraFillPaint
          ..color = sunState.shadowCoreColor.withValues(alpha: penumbraAlpha)
          ..maskFilter = (config.quality == PlanarShadowQuality.high && pCenter.depthEye < 48.0)
              ? const MaskFilter.blur(BlurStyle.normal, 4.5)
              : null;
        canvas.drawPath(penumbraPath, _penumbraFillPaint);
        _penumbraFillPaint.maskFilter = null;
      }
    }

    // 2. Rdzeń cienia (umbra) belki bramy na asfalcie.
    final Path? bannerUmbraPath = _projectWorldPolygonToPath(projection, bannerShadowWorld);
    if (bannerUmbraPath != null) {
      _umbraFillPaint.color = sunState.shadowCoreColor.withValues(alpha: umbraAlpha * 0.85);
      canvas.drawPath(bannerUmbraPath, _umbraFillPaint);
    }

    // 3. Cienie obu filarów bocznych bramy (lewy + prawy) oraz AO podstawy.
    _drawPillarShadow(
      canvas: canvas,
      projection: projection,
      baseWorld: leftBase,
      topWorld: leftTop,
      rightAxis: right,
      pillarHalfWidthMeters: pillarWidth * 0.5,
      projPlane: projPlane,
      sunState: sunState,
      umbraAlpha: umbraAlpha,
      penumbraAlpha: penumbraAlpha,
    );
    _drawPillarShadow(
      canvas: canvas,
      projection: projection,
      baseWorld: rightBase,
      topWorld: rightTop,
      rightAxis: right,
      pillarHalfWidthMeters: pillarWidth * 0.5,
      projPlane: projPlane,
      sunState: sunState,
      umbraAlpha: umbraAlpha,
      penumbraAlpha: penumbraAlpha,
    );
  }

  void _drawPillarShadow({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required Vector3 baseWorld,
    required Vector3 topWorld,
    required Vector3 rightAxis,
    required double pillarHalfWidthMeters,
    required Vector3 Function(Vector3) projPlane,
    required PlanarSunProjectionState sunState,
    required double umbraAlpha,
    required double penumbraAlpha,
  }) {
    final Vector3 b1 = projPlane(baseWorld - (rightAxis * pillarHalfWidthMeters));
    final Vector3 b2 = projPlane(baseWorld + (rightAxis * pillarHalfWidthMeters));
    final Vector3 t2 = projPlane(topWorld + (rightAxis * pillarHalfWidthMeters));
    final Vector3 t1 = projPlane(topWorld - (rightAxis * pillarHalfWidthMeters));

    final List<Vector3> pillarPoly = <Vector3>[b1, b2, t2, t1];
    if (config.quality != PlanarShadowQuality.performance) {
      final Vector3 centroid = (b1 + b2 + t2 + t1) * 0.25;
      final List<Vector3> expanded = _expandWorldPolygonOutward(
        points: pillarPoly,
        centroid: centroid,
        expandMeters: 0.28 * config.penumbraSoftnessScale,
      );
      final Path? penumbraPath = _projectWorldPolygonToPath(projection, expanded);
      if (penumbraPath != null) {
        _penumbraFillPaint.color = sunState.shadowCoreColor.withValues(alpha: penumbraAlpha);
        canvas.drawPath(penumbraPath, _penumbraFillPaint);
      }
    }

    final Path? umbraPath = _projectWorldPolygonToPath(projection, pillarPoly);
    if (umbraPath != null) {
      _umbraFillPaint.color = sunState.shadowCoreColor.withValues(alpha: umbraAlpha * 0.88);
      canvas.drawPath(umbraPath, _umbraFillPaint);
    }

    final ProjectedPoint3D pBase = projection.worldToScreen(projPlane(baseWorld));
    if (pBase.isInFrontOfCamera) {
      final double aoR = (pBase.perspectiveScale * 3.8).clamp(2.0, 18.0);
      _contactAoPaint.color =
          sunState.shadowCoreColor.withValues(alpha: (umbraAlpha * 1.1).clamp(0.05, 0.62));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(pBase.screenX, pBase.screenY),
          width: aoR * 1.4,
          height: aoR * 0.65,
        ),
        _contactAoPaint,
      );
    }
  }

  static Path _buildRiderPolygon({
    required Offset rearPt,
    required Offset frontPt,
    required Offset shoulderLPt,
    required Offset shoulderRPt,
    required Offset headPt,
  }) {
    final Offset midShoulder = Offset(
      (shoulderLPt.dx + shoulderRPt.dx) * 0.5,
      (shoulderLPt.dy + shoulderRPt.dy) * 0.5,
    );
    final Offset headL = Offset.lerp(shoulderLPt, headPt, 0.72)!;
    final Offset headR = Offset.lerp(shoulderRPt, headPt, 0.72)!;

    return Path()
      ..moveTo(rearPt.dx, rearPt.dy)
      ..lineTo(shoulderLPt.dx, shoulderLPt.dy)
      ..quadraticBezierTo(headL.dx, headL.dy, headPt.dx, headPt.dy)
      ..quadraticBezierTo(headR.dx, headR.dy, shoulderRPt.dx, shoulderRPt.dy)
      ..lineTo(frontPt.dx, frontPt.dy)
      ..lineTo(midShoulder.dx, midShoulder.dy)
      ..close();
  }

  static Path _buildExpandedRiderPolygon({
    required Offset rearPt,
    required Offset frontPt,
    required Offset shoulderLPt,
    required Offset shoulderRPt,
    required Offset headPt,
    required double expandPx,
  }) {
    final Offset centroid = Offset(
      (rearPt.dx + frontPt.dx + shoulderLPt.dx + shoulderRPt.dx + headPt.dx) * 0.2,
      (rearPt.dy + frontPt.dy + shoulderLPt.dy + shoulderRPt.dy + headPt.dy) * 0.2,
    );

    Offset pushOut(Offset pt, double factor) {
      final Offset d = pt - centroid;
      final double len = d.distance;
      if (len < 0.01) return pt;
      return pt + (d / len) * (expandPx * factor);
    }

    final Offset eRear = pushOut(rearPt, 0.55);
    final Offset eFront = pushOut(frontPt, 0.55);
    final Offset eShoulderL = pushOut(shoulderLPt, 1.0);
    final Offset eShoulderR = pushOut(shoulderRPt, 1.0);
    final Offset eHead = pushOut(headPt, 1.15);

    return Path()
      ..moveTo(eRear.dx, eRear.dy)
      ..lineTo(eShoulderL.dx, eShoulderL.dy)
      ..lineTo(eHead.dx, eHead.dy)
      ..lineTo(eShoulderR.dx, eShoulderR.dy)
      ..lineTo(eFront.dx, eFront.dy)
      ..close();
  }

  static List<Vector3> _expandWorldPolygonOutward({
    required List<Vector3> points,
    required Vector3 centroid,
    required double expandMeters,
  }) {
    if (expandMeters <= 0.001) return points;
    return points.map((pt) {
      final Vector3 delta = pt - centroid;
      final double len = delta.length;
      if (len < 1e-4) return pt;
      return pt + (delta * (expandMeters / len));
    }).toList(growable: false);
  }

  static Path? _projectWorldPolygonToPath(
    Scene3DMathProjection projection,
    List<Vector3> worldPoints,
  ) {
    if (worldPoints.length < 3) return null;
    final Path path = Path();
    bool started = false;
    for (final pt in worldPoints) {
      final ProjectedPoint3D projected = projection.worldToScreen(pt);
      if (!projected.isInFrontOfCamera) {
        return null;
      }
      if (!started) {
        path.moveTo(projected.screenX, projected.screenY);
        started = true;
      } else {
        path.lineTo(projected.screenX, projected.screenY);
      }
    }
    if (!started) return null;
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant ProjectedPlanarShadowsPainter oldDelegate) {
    return oldDelegate.timeOfDay != timeOfDay ||
        oldDelegate.weatherCondition != weatherCondition ||
        oldDelegate.slopeExposure.gradientPercent != slopeExposure.gradientPercent ||
        oldDelegate.slopeExposure.crossSlopePercent != slopeExposure.crossSlopePercent ||
        oldDelegate.slopeExposure.slopeAspectRadians != slopeExposure.slopeAspectRadians ||
        oldDelegate.slopeExposure.terrainExposureFactor != slopeExposure.terrainExposureFactor ||
        oldDelegate.config.quality != config.quality ||
        oldDelegate.riders.length != riders.length ||
        oldDelegate.trees.length != trees.length ||
        oldDelegate.gates.length != gates.length ||
        oldDelegate.elapsedSeconds != elapsedSeconds ||
        oldDelegate.projection != projection;
  }
}
