// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../state/race_simulation_notifier.dart';
import 'peloton_instanced_renderer.dart';
import 'scene_3d_math_projection.dart';

// =============================================================================
// 1. ENUMERACJE I MODELE DANYCH AERODYNAMIKI
// =============================================================================

/// Strona szosy, po której formuje się naturalny wachlarz (Echelon) przy wietrze bocznym.
enum EchelonSide {
  /// Wiatr wieje z prawej strony -> kolarze kryją się po lewej stronie koła lidera.
  left('Wachlarz w Lewo', 'Krycie po lewej stronie szosy', -1.0),

  /// Wiatr wieje z lewej strony -> kolarze kryją się po prawej stronie koła lidera.
  right('Wachlarz w Prawo', 'Krycie po prawej stronie szosy (ranty)', 1.0),

  /// Wiatr czołowy lub tylny -> jazda bezpośrednio na kole w linii prostej (wężyk).
  center('Szyk Osiowy', 'Jazda bezpośrednio na kole w osi jezdni', 0.0);

  final String label;
  final String description;
  final double lateralSign; // -1.0 dla lewej, +1.0 dla prawej, 0.0 dla środka

  const EchelonSide(this.label, this.description, this.lateralSign);
}

/// Stan pozornego wiatru (Apparent Wind) i geometrii wachlarza w klatce symulacji.
class AeroFlowState {
  /// Kąt pozornego wiatru odczuwanego przez kolarza względem kierunku jazdy [rad].
  /// 0 = idealnie czołowy, pi/2 = prostopadły z prawej, -pi/2 = prostopadły z lewej.
  final double apparentWindAngleRad;

  /// Prędkość pozornego wiatru odczuwana na klatce piersiowej [km/h].
  final double apparentWindSpeedKmh;

  /// Składowa boczna wiatru poprzecznego [km/h] (ujemna = z lewej, dodatnia = z prawej).
  final double crosswindSpeedKmh;

  /// Składowa czołowa wiatru [km/h] (>0 = wiatr w twarz, <0 = wiatr w plecy).
  final double headwindSpeedKmh;

  /// Strona, w którą odchyla się cień aerodynamiczny za kolarzem.
  final EchelonSide echelonSide;

  /// Kąt odchylenia strugi aerodynamicznej (Drafting Wake) w płaszczyźnie poziomej [rad].
  final double echelonDeflectionAngleRad;

  /// Odchylenie poprzeczne strugi na każdy metr odległości za kolarzem [m/m].
  final double echelonDeflectionRatio;

  /// Zalecenie taktyczne dla gracza wyświetlane na HUDzie Aero Vision.
  final String echelonRecommendation;

  const AeroFlowState({
    this.apparentWindAngleRad = 0.0,
    this.apparentWindSpeedKmh = 45.0,
    this.crosswindSpeedKmh = 0.0,
    this.headwindSpeedKmh = 45.0,
    this.echelonSide = EchelonSide.center,
    this.echelonDeflectionAngleRad = 0.0,
    this.echelonDeflectionRatio = 0.0,
    this.echelonRecommendation = 'Wiatr czołowy: Trzymaj koło w linii osi szosy.',
  });
}

/// Aktywna kieszeń aerodynamiczna pojedynczego kolarza w rzucie 3D.
class RiderAeroPocket {
  final String riderId;
  final String riderName;
  final int bibNumber;
  final String teamJerseyHex;
  final bool isPlayerRider;
  final bool isPulling;
  final double draftingSavingsPercent;
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double speedKmh;

  // Koordynaty ekranowe 2D wyznaczone przez rzutowanie 3D
  final Offset screenPosition;
  final double perspectiveScale;
  final bool isInFrontOfCamera;
  final double depth;

  const RiderAeroPocket({
    required this.riderId,
    required this.riderName,
    required this.bibNumber,
    required this.teamJerseyHex,
    required this.isPlayerRider,
    required this.isPulling,
    required this.draftingSavingsPercent,
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.speedKmh,
    required this.screenPosition,
    required this.perspectiveScale,
    required this.isInFrontOfCamera,
    required this.depth,
  });

  /// Czy kolarz znajduje się w bezpiecznej, głębokiej strefie osłony (oszczędność >= 25%).
  bool get hasEffectiveDrafting => draftingSavingsPercent >= 25.0;

  /// Czy kolarz jest wystawiony na boczny wiatr i ponosi pełen opór (niska osłona lub czoło).
  bool get isExposedToWind => isPulling || draftingSavingsPercent < 15.0;
}

/// Cząsteczka płynąca wzdłuż linii prądu powietrza (Streamline Flow Particle).
class StreamlineParticle3D {
  /// Znormalizowana pozycja wzdłuż strugi [0.0 = plecy kolarza, 1.0 = ogon strugi].
  double progress;

  /// Indeks przypisanego kolarza w buforze
  int riderIndex;

  /// Indeks linii prądu (np. 0 = środek strugi, 1 = lewa krawędź, 2 = prawa krawędź).
  final int lineIndex;

  /// Odchylenie poprzeczne od osi strugi [m]
  final double lateralOffset;

  /// Wysokość cząsteczki nad asfaltem [m]
  final double verticalHeightMeters;

  /// Indywidualny mnożnik prędkości przepływu strugi
  final double speedFactor;

  StreamlineParticle3D({
    this.progress = 0.0,
    this.riderIndex = 0,
    required this.lineIndex,
    required this.lateralOffset,
    required this.verticalHeightMeters,
    this.speedFactor = 1.0,
  });
}

// =============================================================================
// 2. KONFIGURACJA WIZUALIZATORA AERO VISION
// =============================================================================

/// Konfiguracja parametrów i trybów wizualizatora tunelu aerodynamicznego 3D.
class WindStreamlinesConfig {
  /// Czy moduł jest globalnie włączony w silniku renderującym.
  final bool enabled;

  /// Czy tryb Aero Vision ("Tunel Aerodynamiczny na żywo") jest aktywny w widoku.
  final bool aeroVisionActive;

  /// Liczba animowanych linii prądu renderowanych dla każdego kolarza.
  final int streamlinesPerRider;

  /// Maksymalna liczba kolarzy, dla których renderowany jest pełny tunel (blisko kamery).
  final int maxVisualizedRiders;

  /// Długość strugi aerodynamicznej (Drafting Wake Length) za kolarzem w metrach.
  final double streamlineLengthMeters;

  /// Przezroczystość zielonej strefy osłony aerodynamicznej [0.1 - 1.0].
  final double pocketGreenOpacity;

  /// Przezroczystość czerwonej strefy turbulentnego oporu bocznego [0.1 - 1.0].
  final double pocketRedOpacity;

  /// Czy renderować wypełnione wielokąty cienia aerodynamicznego (Drafting Pockets).
  final bool enableDraftingPockets;

  /// Czy renderować czerwone strefy wystawienia na wiatr boczny (High Drag Exposure).
  final bool enableCrosswindRedZones;

  /// Czy renderować animowane linie prądu powietrza i wstęgi aero (Streamlines).
  final bool enableStreamlineRibbons;

  /// Czy renderować linie łączące pociąg drużyny na rantach (Echelon Formation Guides).
  final bool enableEchelonTeamGuides;

  /// Czy wyświetlać mini-kompas aerodynamiczny i telemetrię rantów na HUDzie.
  final bool enableAeroCompassHud;

  /// Mnożnik prędkości animacji przepływu powietrza.
  final double flowSpeedMultiplier;

  const WindStreamlinesConfig({
    this.enabled = true,
    this.aeroVisionActive = false,
    this.streamlinesPerRider = 4,
    this.maxVisualizedRiders = 22,
    this.streamlineLengthMeters = 11.5,
    this.pocketGreenOpacity = 0.38,
    this.pocketRedOpacity = 0.32,
    this.enableDraftingPockets = true,
    this.enableCrosswindRedZones = true,
    this.enableStreamlineRibbons = true,
    this.enableEchelonTeamGuides = true,
    this.enableAeroCompassHud = true,
    this.flowSpeedMultiplier = 1.0,
  });

  WindStreamlinesConfig copyWith({
    bool? enabled,
    bool? aeroVisionActive,
    int? streamlinesPerRider,
    int? maxVisualizedRiders,
    double? streamlineLengthMeters,
    double? pocketGreenOpacity,
    double? pocketRedOpacity,
    bool? enableDraftingPockets,
    bool? enableCrosswindRedZones,
    bool? enableStreamlineRibbons,
    bool? enableEchelonTeamGuides,
    bool? enableAeroCompassHud,
    double? flowSpeedMultiplier,
  }) {
    return WindStreamlinesConfig(
      enabled: enabled ?? this.enabled,
      aeroVisionActive: aeroVisionActive ?? this.aeroVisionActive,
      streamlinesPerRider: streamlinesPerRider ?? this.streamlinesPerRider,
      maxVisualizedRiders: maxVisualizedRiders ?? this.maxVisualizedRiders,
      streamlineLengthMeters: streamlineLengthMeters ?? this.streamlineLengthMeters,
      pocketGreenOpacity: pocketGreenOpacity ?? this.pocketGreenOpacity,
      pocketRedOpacity: pocketRedOpacity ?? this.pocketRedOpacity,
      enableDraftingPockets: enableDraftingPockets ?? this.enableDraftingPockets,
      enableCrosswindRedZones: enableCrosswindRedZones ?? this.enableCrosswindRedZones,
      enableStreamlineRibbons: enableStreamlineRibbons ?? this.enableStreamlineRibbons,
      enableEchelonTeamGuides: enableEchelonTeamGuides ?? this.enableEchelonTeamGuides,
      enableAeroCompassHud: enableAeroCompassHud ?? this.enableAeroCompassHud,
      flowSpeedMultiplier: flowSpeedMultiplier ?? this.flowSpeedMultiplier,
    );
  }
}

// =============================================================================
// 3. WIZUALIZATOR TUNELU AERODYNAMICZNEGO I RANTÓW (WIND STREAMLINES VISUALIZER)
// =============================================================================

/// Silnik czasu rzeczywistego do analitycznej wizualizacji aerodynamiki ("Aero Vision Mode").
///
/// Umożliwia graczowi wgląd w:
/// 1. **Strefy Cienia Aerodynamicznego (Drafting Pockets)**:
///    - Zielone stożki niskiego oporu ciągnące się za plecami kolarzy, odchylane
///      wzdłuż wektora pozornego wiatru (Apparent Wind Vector).
///    - Złoto-żółte strefy przejścia (Transition Margin).
/// 2. **Strefy Turbulencji i Pełnego Oporu (Crosswind Drag Zones)**:
///    - Czerwone aury oporu po stronie nawietrznej kolarza, unaoczniające
///      ryzyko odpadnięcia z rantu przy silnym bocznym podmuchu.
/// 3. **Półprzezroczyste Linie Przepływu (Airflow Streamlines)**:
///    - Trójwymiarowe wstęgi przepływu powietrza opływające sylwetki kolarzy.
/// 4. **Wskaźnik i Kompas Rantów (Echelon Aero HUD)**:
///    - Wizualna róża wiatrów, wektor pozornego wiatru oraz rekomendacja ustawienia wachlarza.
///
/// Zaprojektowany w standardzie Zero-GC (120 FPS) z prealokowanymi obiektami Paint i Path.
class WindStreamlinesVisualizer {
  WindStreamlinesConfig config;

  // Bieżący stan fizyki wiatru pozornego
  AeroFlowState _lastAeroState = const AeroFlowState();

  // Pula buforów kolarzy w kadrze
  final List<RiderAeroPocket> _activePockets = [];

  // Pula prealokowanych cząsteczek linii prądu powietrza
  final List<StreamlineParticle3D> _particlesPool = [];

  // Prealokowany cache farb (Zero-GC)
  late final Paint _shelterGreenFillPaint;
  late final Paint _shelterGreenStrokePaint;
  late final Paint _exposedRedFillPaint;
  late final Paint _exposedRedStrokePaint;
  late final Paint _streamlineCyanPaint;
  late final Paint _streamlineParticlePaint;
  late final Paint _echelonTrainGuidePaint;
  late final Paint _echelonGutterWarningPaint;
  late final Paint _hudBgPaint;
  late final Paint _hudBorderPaint;
  late final Paint _hudCompassRingPaint;
  late final Paint _hudCompassNeedlePaint;

  // Prealokowany Path do wielokątów cienia
  final Path _pocketPolygonPath = Path();

  WindStreamlinesVisualizer({
    this.config = const WindStreamlinesConfig(),
  }) {
    _initPaintCache();
    _initParticlePool();
  }

  void _initPaintCache() {
    _shelterGreenFillPaint = Paint()
      ..color = AppColors.emeraldGreen.withValues(alpha: config.pocketGreenOpacity)
      ..style = PaintingStyle.fill;

    _shelterGreenStrokePaint = Paint()
      ..color = AppColors.emeraldGreen.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    _exposedRedFillPaint = Paint()
      ..color = AppColors.crimsonAlert.withValues(alpha: config.pocketRedOpacity)
      ..style = PaintingStyle.fill;

    _exposedRedStrokePaint = Paint()
      ..color = AppColors.crimsonAlert.withValues(alpha: 0.80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    _streamlineCyanPaint = Paint()
      ..color = AppColors.cyanAccent.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;

    _streamlineParticlePaint = Paint()
      ..color = const Color(0xFFE0F7FA)
      ..style = PaintingStyle.fill;

    _echelonTrainGuidePaint = Paint()
      ..color = AppColors.emeraldGreen.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;

    _echelonGutterWarningPaint = Paint()
      ..color = AppColors.crimsonAlert.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;

    _hudBgPaint = Paint()
      ..color = const Color(0xFF0F121C).withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;

    _hudBorderPaint = Paint()
      ..color = const Color(0xFF2E3440)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    _hudCompassRingPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    _hudCompassNeedlePaint = Paint()
      ..color = AppColors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;
  }

  void _initParticlePool() {
    _particlesPool.clear();
    const int totalParticles = 96;
    final rand = math.Random(42);

    for (int i = 0; i < totalParticles; i++) {
      final lineIdx = i % 4;
      double lat = 0.0;
      switch (lineIdx) {
        case 0:
          lat = 0.0; // Osiowa struga
          break;
        case 1:
          lat = -0.35; // Lewy bark
          break;
        case 2:
          lat = 0.35; // Prawy bark
          break;
        case 3:
          lat = (rand.nextDouble() - 0.5) * 0.9; // Wir krawędziowy
          break;
      }

      _particlesPool.add(
        StreamlineParticle3D(
          progress: rand.nextDouble(),
          riderIndex: (i / 4).floor(),
          lineIndex: lineIdx,
          lateralOffset: lat,
          verticalHeightMeters: 0.45 + rand.nextDouble() * 0.75,
          speedFactor: 0.85 + rand.nextDouble() * 0.35,
        ),
      );
    }
  }

  /// Włącza lub wyłącza tryb Aero Vision.
  void setAeroVisionActive(bool active) {
    config = config.copyWith(aeroVisionActive: active);
  }

  /// Przełącza stan aktywności trybu Aero Vision.
  void toggleAeroVision() {
    config = config.copyWith(aeroVisionActive: !config.aeroVisionActive);
  }

  bool get isAeroVisionActive => config.enabled && config.aeroVisionActive;
  AeroFlowState get lastAeroState => _lastAeroState;
  int get activePocketsCount => _activePockets.length;
  int get activeStreamlinesCount => _particlesPool.length;

  // ===========================================================================
  // 4. FIZYKA WIATRU POZORNEGO I KALKULATOR RANTÓW (APPARENT WIND VECTOR)
  // ===========================================================================

  /// Oblicza wypadkowy wektor pozornego wiatru (Apparent Wind) na podstawie
  /// parametrów segmentu drogi oraz średniej prędkości kolarzy.
  AeroFlowState calculateApparentWind({
    required StageSegment segment,
    double windSpeedKmh = 18.0,
    double riderSpeedKmh = 44.0,
  }) {
    final double windSpeed = (windSpeedKmh > 0.0)
        ? windSpeedKmh
        : 18.0;

    // 1. Kąt relatywny wiatru względem kierunku szosy [stopnie]
    final double roadBearing = segment.roadBearingDegrees;
    final double windDir = segment.windDirectionDegrees;

    // Różnica kątowa: skąd wieje wiatr względem osi jazdy kolarza
    double relAngleDeg = (windDir - roadBearing) % 360.0;
    if (relAngleDeg < 0.0) relAngleDeg += 360.0;
    final double relAngleRad = relAngleDeg * (math.pi / 180.0);

    // 2. Składowe prędkości wiatru rzeczywistego w układzie drogi:
    // Z = wzdłuż szosy (do przodu), X = poprzecznie w prawo.
    // Wiatr "wieje z kąta relAngle", więc wektor ruchu powietrza jest przeciwny do relAngle.
    final double vWindZ = -windSpeed * math.cos(relAngleRad);
    final double vWindX = -windSpeed * math.sin(relAngleRad);

    // 3. Prędkość kolarza w przód (+Z)
    final double vRiderZ = math.max(10.0, riderSpeedKmh);

    // 4. Wektor pozornego wiatru odczuwany przez poruszającego się kolarza:
    // vApparent = vWind - vRider
    final double vApparentZ = vWindZ - vRiderZ;
    final double vApparentX = vWindX;

    final double apparentSpeedKmh = math.sqrt(vApparentZ * vApparentZ + vApparentX * vApparentX);
    final double apparentAngleRad = math.atan2(vApparentX, vApparentZ);

    // 5. Składowa boczna i czołowa
    final double crosswindKmh = vWindX.abs();
    final double headwindKmh = -vWindZ;

    // 6. Odchylenie strugi cienia aerodynamicznego za kolarzem:
    // Cień aerodynamiczny rozciąga się w kierunku przepływu strugi za plecami kolarza.
    // Stosunek przesunięcia poprzecznego na metr dystansu za plecami:
    final double deflectionRatio = (vApparentX / (-vApparentZ)).clamp(-0.95, 0.95);
    final double deflectionAngleRad = math.atan(deflectionRatio);

    // 7. Klasyfikacja strony wachlarza (Echelon Side)
    EchelonSide side;
    String recommendation;

    if (crosswindKmh < 6.0) {
      side = EchelonSide.center;
      recommendation = 'Wiatr czołowy: Trzymaj koło prosto w linii.';
    } else if (vWindX > 0.0) {
      // Wiatr wieje z lewej strony (vWindX > 0, powietrze płynie w prawo) -> cień odchyla się w prawo (+X).
      side = EchelonSide.right;
      recommendation = 'Wiatr z lewej (${crosswindKmh.toStringAsFixed(0)} km/h): Ranty w prawo! Osłona po prawej stronie koła.';
    } else {
      // Wiatr wieje z prawej strony (vWindX < 0, powietrze płynie w lewo) -> cień odchyla się w lewo (-X).
      side = EchelonSide.left;
      recommendation = 'Wiatr z prawej (${crosswindKmh.toStringAsFixed(0)} km/h): Ranty w lewo! Osłona po lewej stronie koła.';
    }

    return AeroFlowState(
      apparentWindAngleRad: apparentAngleRad,
      apparentWindSpeedKmh: apparentSpeedKmh,
      crosswindSpeedKmh: crosswindKmh,
      headwindSpeedKmh: headwindKmh,
      echelonSide: side,
      echelonDeflectionAngleRad: deflectionAngleRad,
      echelonDeflectionRatio: deflectionRatio,
      echelonRecommendation: recommendation,
    );
  }

  // ===========================================================================
  // 5. SYNCHRONIZACJA I AKTUALIZACJA FIZYKI STRUG (TICK UPDATE)
  // ===========================================================================

  /// Aktualizuje stan strug i cząsteczek aerodynamicznych w danej klatce.
  void updatePhysics({
    List<PelotonRenderItem>? activeRiders,
    List<RiderPositionSnapshot>? snapshots,
    required RaceStage activeStage,
    required List<StageSegment> segments,
    required double dtSeconds,
    required double elapsedAnimSeconds,
  }) {
    if (!config.enabled) return;

    // 1. Wyznaczenie segmentu referencyjnego dla geometrii wiatru
    final refSegment = segments.isNotEmpty
        ? segments.first
        : const StageSegment(
            index: 0,
            startKm: 0.0,
            lengthKm: 10.0,
            startElevationM: 400.0,
            endElevationM: 450.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 20.0,
            windDirectionDegrees: 240.0,
            roadBearingDegrees: 45.0,
            sprintOrKomClassification: SegmentClassification.none,
          );

    // 2. Obliczenie uaktualnionego wektora wiatru pozornego
    _lastAeroState = calculateApparentWind(
      segment: refSegment,
      windSpeedKmh: activeStage.windSpeedKmh,
      riderSpeedKmh: 43.5,
    );

    // 3. Aktualizacja pozycji cząsteczek linii prądu
    final double effectiveDt = dtSeconds * config.flowSpeedMultiplier;
    final double particleSpeed = (0.75 + (_lastAeroState.apparentWindSpeedKmh / 50.0) * 0.5) * effectiveDt;

    for (final p in _particlesPool) {
      p.progress += particleSpeed * p.speedFactor;
      if (p.progress > 1.0) {
        p.progress -= 1.0;
      }
    }

    // 4. Budowanie bufora kieszeni kolarzy (RiderAeroPocket)
    _activePockets.clear();

    if (activeRiders != null && activeRiders.isNotEmpty) {
      final int count = math.min(config.maxVisualizedRiders, activeRiders.length);
      for (int i = 0; i < count; i++) {
        final item = activeRiders[i];
        final snap = item.snapshot;

        _activePockets.add(
          RiderAeroPocket(
            riderId: snap.riderId,
            riderName: snap.riderName,
            bibNumber: snap.bibNumber,
            teamJerseyHex: snap.teamJerseyHexColor,
            isPlayerRider: snap.isPlayerRider,
            isPulling: snap.isPulling,
            draftingSavingsPercent: snap.draftingSavingsPercent,
            distanceMeters: snap.distanceCoveredMeters,
            lateralOffsetMeters: snap.lateralOffsetRoadMeters,
            speedKmh: snap.speedKmh,
            screenPosition: Offset(item.projectedCenter.screenX, item.projectedCenter.screenY),
            perspectiveScale: item.screenScale,
            isInFrontOfCamera: item.projectedCenter.isInFrontOfCamera,
            depth: item.cameraDistance,
          ),
        );
      }
    } else if (snapshots != null && snapshots.isNotEmpty) {
      final int count = math.min(config.maxVisualizedRiders, snapshots.length);
      for (int i = 0; i < count; i++) {
        final snap = snapshots[i];
        _activePockets.add(
          RiderAeroPocket(
            riderId: snap.riderId,
            riderName: snap.riderName,
            bibNumber: snap.bibNumber,
            teamJerseyHex: snap.teamJerseyHexColor,
            isPlayerRider: snap.isPlayerRider,
            isPulling: snap.isPulling,
            draftingSavingsPercent: snap.draftingSavingsPercent,
            distanceMeters: snap.distanceCoveredMeters,
            lateralOffsetMeters: snap.lateralOffsetRoadMeters,
            speedKmh: snap.speedKmh,
            screenPosition: Offset.zero,
            perspectiveScale: 1.0,
            isInFrontOfCamera: true,
            depth: 10.0,
          ),
        );
      }
    }
  }

  // ===========================================================================
  // 6. GŁÓWNA METODA RENDEROWANIA AERO VISION NA CANVAS 3D
  // ===========================================================================

  /// Renderuje pełną scenę tunelu aerodynamicznego:
  /// - Zielone stożki osłony aerodynamicznej za plecami (Drafting Pockets),
  /// - Czerwone aury oporu po stronie nawietrznej (Crosswind Drag Zones),
  /// - Półprzezroczyste wstęgi przepływu powietrza (Airflow Streamlines),
  /// - Wskaźnik pociągu drużyny na rantach oraz róża wiatrów na HUD.
  void renderAeroVision({
    required Canvas canvas,
    required Size size,
    required Scene3DMathProjection projection,
    double elapsedAnimSeconds = 0.0,
  }) {
    if (!config.enabled || !config.aeroVisionActive) return;
    if (_activePockets.isEmpty) return;

    // Krok 1: Renderowanie stref osłony i oporu (Drafting Pockets & Red Zones)
    if (config.enableDraftingPockets || config.enableCrosswindRedZones) {
      for (final pocket in _activePockets) {
        _drawRiderAeroWake(
          canvas: canvas,
          projection: projection,
          pocket: pocket,
          aero: _lastAeroState,
          animSeconds: elapsedAnimSeconds,
        );
      }
    }

    // Krok 2: Półprzezroczyste linie przepływu powietrza (Streamlines)
    if (config.enableStreamlineRibbons) {
      _drawStreamlinesRibbons(
        canvas: canvas,
        projection: projection,
        aero: _lastAeroState,
        animSeconds: elapsedAnimSeconds,
      );
    }

    // Krok 3: Prowadnice pociągu drużyny na rantach (Echelon Alignment Guides)
    if (config.enableEchelonTeamGuides) {
      _drawEchelonTrainConnections(canvas, projection, _activePockets);
    }

    // Krok 4: Aerodynamiczny kompas i telemetria rantów na HUD
    if (config.enableAeroCompassHud) {
      _drawAeroCompassHud(canvas, size, _lastAeroState);
    }
  }

  // ===========================================================================
  // 7. RYSOWANIE KIESZENI CIENIA ORAZ STREF OPORU BOCZNEGO (AERO WAKES)
  // ===========================================================================

  void _drawRiderAeroWake({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required RiderAeroPocket pocket,
    required AeroFlowState aero,
    required double animSeconds,
  }) {
    final double dist = pocket.distanceMeters;
    final double lat = pocket.lateralOffsetMeters;
    final double wakeLength = config.streamlineLengthMeters * (0.8 + (pocket.speedKmh / 50.0) * 0.4);

    // Odchylenie strugi na końcu strefy cienia [m]
    final double endDeflection = wakeLength * aero.echelonDeflectionRatio;

    // --- A. ZIELONY STOŻEK CIENIA AERODYNAMICZNEGO (SHELTERED POCKET) ---
    if (config.enableDraftingPockets) {
      // 4 wierzchołki trapezu cienia w układzie szosy:
      // P1: tylne koło lewa strona kolarza
      final p1World = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: dist - 0.2,
        lateralOffsetMeters: lat - 0.38,
        elevationMeters: 0.05,
      );
      // P2: tylne koło prawa strona kolarza
      final p2World = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: dist - 0.2,
        lateralOffsetMeters: lat + 0.38,
        elevationMeters: 0.05,
      );
      // P3: koniec strugi prawa strona (rozszerzenie do 1.6m)
      final p3World = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: dist - wakeLength,
        lateralOffsetMeters: lat + endDeflection + 0.78,
        elevationMeters: 0.05,
      );
      // P4: koniec strugi lewa strona
      final p4World = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: dist - wakeLength,
        lateralOffsetMeters: lat + endDeflection - 0.78,
        elevationMeters: 0.05,
      );

      final proj1 = projection.worldToScreen(p1World);
      final proj2 = projection.worldToScreen(p2World);
      final proj3 = projection.worldToScreen(p3World);
      final proj4 = projection.worldToScreen(p4World);

      // Jeśli wierzchołki są w polu widzenia kamery
      if (proj1.isInFrontOfCamera && proj2.isInFrontOfCamera &&
          proj3.isInFrontOfCamera && proj4.isInFrontOfCamera) {
        _pocketPolygonPath.reset();
        _pocketPolygonPath.moveTo(proj1.screenX, proj1.screenY);
        _pocketPolygonPath.lineTo(proj2.screenX, proj2.screenY);
        _pocketPolygonPath.lineTo(proj3.screenX, proj3.screenY);
        _pocketPolygonPath.lineTo(proj4.screenX, proj4.screenY);
        _pocketPolygonPath.close();

        // Rysowanie zielonej kieszeni cienia
        canvas.drawPath(_pocketPolygonPath, _shelterGreenFillPaint);
        canvas.drawPath(_pocketPolygonPath, _shelterGreenStrokePaint);

        // Oznaczenie "SWEET SPOT" w sercu strugi
        final centerScreenX = (proj1.screenX + proj2.screenX + proj3.screenX + proj4.screenX) * 0.25;
        final centerScreenY = (proj1.screenY + proj2.screenY + proj3.screenY + proj4.screenY) * 0.25;
        final scale = (proj1.perspectiveScale * 12.0).clamp(0.4, 3.5);

        if (scale > 1.0) {
          canvas.drawCircle(Offset(centerScreenX, centerScreenY), 2.5 * scale, _shelterGreenStrokePaint);
        }
      }
    }

    // --- B. CZERWONA STREFA WYSTAWIENIA NA WIATR BOCZNY (HIGH DRAG CROSSWIND) ---
    if (config.enableCrosswindRedZones && aero.crosswindSpeedKmh > 7.0) {
      // Wektor wiatru uderza z nawietrznej:
      // Jeśli wiatr z lewej (echelon w prawo) -> nawietrzna to lewa krawędź kolarza (-X).
      final double windwardSign = (aero.echelonSide == EchelonSide.right) ? -1.0 : 1.0;
      const double redWedgeWidth = 1.35;
      const double redWedgeLength = 3.2;

      final r1World = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: dist + 0.8,
        lateralOffsetMeters: lat,
        elevationMeters: 0.1,
      );
      final r2World = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: dist + 0.2,
        lateralOffsetMeters: lat + (windwardSign * 0.45),
        elevationMeters: 0.1,
      );
      final r3World = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: dist - redWedgeLength,
        lateralOffsetMeters: lat + (windwardSign * (0.45 + redWedgeWidth)),
        elevationMeters: 0.1,
      );

      final rProj1 = projection.worldToScreen(r1World);
      final rProj2 = projection.worldToScreen(r2World);
      final rProj3 = projection.worldToScreen(r3World);

      if (rProj1.isInFrontOfCamera && rProj2.isInFrontOfCamera && rProj3.isInFrontOfCamera) {
        final redPath = Path()
          ..moveTo(rProj1.screenX, rProj1.screenY)
          ..lineTo(rProj2.screenX, rProj2.screenY)
          ..lineTo(rProj3.screenX, rProj3.screenY)
          ..close();

        canvas.drawPath(redPath, _exposedRedFillPaint);
        canvas.drawPath(redPath, _exposedRedStrokePaint);
      }
    }
  }

  // ===========================================================================
  // 8. RYSOWANIE LINII PRĄDU POWIETRZA I CZĄSTECZEK (STREAMLINES)
  // ===========================================================================

  void _drawStreamlinesRibbons({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required AeroFlowState aero,
    required double animSeconds,
  }) {
    if (_activePockets.isEmpty) return;

    final double wakeLength = config.streamlineLengthMeters;

    for (final particle in _particlesPool) {
      if (particle.riderIndex >= _activePockets.length) continue;
      final rider = _activePockets[particle.riderIndex];

      // Dystans wzdłuż strugi za kolarzem
      final double dOffset = particle.progress * wakeLength;
      final double pointDist = rider.distanceMeters - dOffset;

      // Poprzeczne odchylenie strugi
      final double lateralDeflection = dOffset * aero.echelonDeflectionRatio;
      final double pointLat = rider.lateralOffsetMeters + lateralDeflection + particle.lateralOffset;

      final worldPos = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: pointDist,
        lateralOffsetMeters: pointLat,
        elevationMeters: particle.verticalHeightMeters,
      );

      final proj = projection.worldToScreen(worldPos);
      if (!proj.isInFrontOfCamera) continue;

      final scale = (proj.perspectiveScale * 14.0).clamp(0.3, 4.0);
      final alphaFactor = math.sin(particle.progress * math.pi).clamp(0.0, 1.0);

      // Rysowanie główki strugi
      _streamlineCyanPaint.strokeWidth = 1.6 * scale;
      _streamlineCyanPaint.color = AppColors.cyanAccent.withValues(alpha: 0.65 * alphaFactor);

      // Kreska prądu powietrza wzdłuż wektora strugi
      final double tailLen = 9.0 * scale * (1.0 - particle.progress * 0.4);
      final double dx = aero.echelonDeflectionRatio * tailLen * 0.45;
      final double dy = -tailLen;

      canvas.drawLine(
        Offset(proj.screenX, proj.screenY),
        Offset(proj.screenX + dx, proj.screenY - dy),
        _streamlineCyanPaint,
      );

      // Drobny świetlisty punkt cząsteczki
      canvas.drawCircle(
        Offset(proj.screenX, proj.screenY),
        1.3 * scale,
        _streamlineParticlePaint..color = const Color(0xFFE0F7FA).withValues(alpha: 0.85 * alphaFactor),
      );
    }
  }

  // ===========================================================================
  // 9. PROWADNICE POCIĄGU DRUŻYNY NA RANTACH (ECHELON TEAM ALIGNMENT)
  // ===========================================================================

  void _drawEchelonTrainConnections(
    Canvas canvas,
    Scene3DMathProjection projection,
    List<RiderAeroPocket> pockets,
  ) {
    if (pockets.length < 2) return;

    // Łączymy kolejnych kolarzy w peletonie/pociągu wizualną linią formacji
    for (int i = 0; i < pockets.length - 1; i++) {
      final lead = pockets[i];
      final follower = pockets[i + 1];

      // Rysujemy tylko dla kolarzy znajdujących się w zasięgu bezpośredniego kontaktu (<7.5m)
      final distDiff = (lead.distanceMeters - follower.distanceMeters).abs();
      if (distDiff > 8.0 || distDiff < 0.8) continue;

      if (!lead.isInFrontOfCamera || !follower.isInFrontOfCamera) continue;

      final bool hasShelter = follower.hasEffectiveDrafting;
      final linePaint = hasShelter ? _echelonTrainGuidePaint : _echelonGutterWarningPaint;

      canvas.drawLine(lead.screenPosition, follower.screenPosition, linePaint);
    }
  }

  // ===========================================================================
  // 10. AERODYNAMICZNY KOMPAS I TELEMETRIA RANTÓW NA HUD (AERO COMPASS HUD)
  // ===========================================================================

  void _drawAeroCompassHud(
    Canvas canvas,
    Size size,
    AeroFlowState aero,
  ) {
    // Umiejscowienie w prawym górnym rogu pod ewentualnym HUDem transmisji
    const double hudW = 210.0;
    const double hudH = 74.0;
    final double hudX = size.width - hudW - 16.0;
    const double hudY = 16.0;

    // Karta tła Aero HUD
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(hudX, hudY, hudW, hudH),
      const Radius.circular(10.0),
    );
    canvas.drawRRect(cardRect, _hudBgPaint);
    canvas.drawRRect(cardRect, _hudBorderPaint);

    // Mini róża wiatrów (Aero Compass)
    final double compassCenterX = hudX + 32.0;
    const double compassCenterY = hudY + 37.0;
    const double compassRadius = 22.0;

    // Pierścień kompasu
    canvas.drawCircle(Offset(compassCenterX, compassCenterY), compassRadius, _hudCompassRingPaint);

    // Oś drogi (Pionowa linia biała ze strzałką kierunku jazdy)
    canvas.drawLine(
      Offset(compassCenterX, compassCenterY + compassRadius - 4),
      Offset(compassCenterX, compassCenterY - compassRadius + 4),
      Paint()..color = Colors.white70..strokeWidth = 1.4,
    );

    // Wskazówka pozornego wiatru (Cyan Arrow wskazująca kierunek naporu powietrza)
    final double windAngle = aero.apparentWindAngleRad;
    final double nx = compassCenterX - math.sin(windAngle) * (compassRadius - 3);
    final double ny = compassCenterY - math.cos(windAngle) * (compassRadius - 3);

    canvas.drawLine(
      Offset(compassCenterX, compassCenterY),
      Offset(nx, ny),
      _hudCompassNeedlePaint,
    );
    canvas.drawCircle(Offset(nx, ny), 3.0, Paint()..color = AppColors.cyanAccent..style = PaintingStyle.fill);

    // Tekstowa telemetria aerodynamiki i rantów
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Nagłówek "AERO VISION"
    textPainter.text = const TextSpan(
      text: 'AERO VISION • TUNEL 3D',
      style: TextStyle(
        color: AppColors.cyanAccent,
        fontSize: 10.0,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(hudX + 64.0, hudY + 10.0));

    // Wartość bocznego wiatru
    final String windDesc = (aero.crosswindSpeedKmh > 5.0)
        ? '${aero.echelonSide.label} • ${aero.crosswindSpeedKmh.toStringAsFixed(0)} km/h'
        : 'Czołowy • ${aero.apparentWindSpeedKmh.toStringAsFixed(0)} km/h';

    textPainter.text = TextSpan(
      text: windDesc,
      style: TextStyle(
        color: (aero.crosswindSpeedKmh > 18.0) ? AppColors.crimsonAlert : AppColors.textPrimary,
        fontSize: 11.5,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(hudX + 64.0, hudY + 26.0));

    // Rekomendacja ustawienia rantów
    final String tip = (aero.echelonSide == EchelonSide.right)
        ? 'Ranty w prawo! (Schowaj się po prawej)'
        : (aero.echelonSide == EchelonSide.left)
            ? 'Ranty w lewo! (Schowaj się po lewej)'
            : 'Trzymaj koło w osi jezdni';

    textPainter.text = TextSpan(
      text: tip,
      style: TextStyle(
        color: (aero.crosswindSpeedKmh > 12.0) ? AppColors.emeraldGreen : AppColors.textSecondary,
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(hudX + 64.0, hudY + 44.0));
  }
}
