// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../state/race_simulation_notifier.dart';
import '../peloton/boids_steering_collision_avoidance.dart';
import '../peloton/rider_race_state.dart';
import 'camera_rig_controller.dart';
import 'dynamic_skybox_and_lighting_painter.dart';
import 'scene_3d_math_projection.dart';

/// Profil stożka karbonowego koła szosowego lub czasowego.
enum WheelProfileType {
  /// Lekkie koła górskie o stożku 35 mm.
  depth35mm(rimDepthMeters: 0.035, spokeCount: 8, isDisc: false, label: '35 mm'),

  /// Uniwersalne koła wyścigowe o stożku 50 mm.
  depth50mm(rimDepthMeters: 0.050, spokeCount: 6, isDisc: false, label: '50 mm'),

  /// Głębokie koła aerodynamiczne o stożku 65 mm.
  depth65mm(rimDepthMeters: 0.065, spokeCount: 5, isDisc: false, label: '65 mm'),

  /// Pełny karbonowy dysk tylny do jazdy na czas i szybkich finiszów.
  discRear(rimDepthMeters: 0.310, spokeCount: 0, isDisc: true, label: 'Dysk');

  final double rimDepthMeters;
  final int spokeCount;
  final bool isDisc;
  final String label;

  const WheelProfileType({
    required this.rimDepthMeters,
    required this.spokeCount,
    required this.isDisc,
    required this.label,
  });
}

/// Wariant koszulki klasyfikacyjnej lub mistrza świata noszonej przez kolarza.
enum LeaderJerseyType {
  /// Standardowa koszulka drużynowa.
  none,

  /// Żółta koszulka lidera klasyfikacji generalnej (GC).
  yellow,

  /// Zielona koszulka lidera klasyfikacji punktowej / sprinterskiej.
  green,

  /// Biała koszulka w czerwone grochy lidera klasyfikacji górskiej (KOM).
  polkaDot,

  /// Tęczowa koszulka Mistrza Świata UCI.
  rainbow,

  /// Biała koszulka najlepszego młodzieżowca.
  white,
}

/// Poziom szczegółowości renderowania pojedynczego kolarza w 3D.
enum Peloton3dLod {
  /// Pełny detal: obracające się koła ze stożkami, trójkąty ramy, dwusegmentowe nogi, kask i okulary.
  full,

  /// Średni detal: uproszczona rama, koła, sylwetka tułowia i kask.
  medium,

  /// Daleki plan: szybka bryła kapsułowa z cieniem kontaktowym.
  distant,
}

/// Typ obiektu przydrożnego renderowanego wzdłuż wstęgi drogi 3D.
enum Peloton3dPropType {
  pineTree,
  deciduousTree,
  cypressTree,
  rockBoulder,
  alpineCrag,
  kilometerGate,
  flammeRougeGate,
  finishGantry,
}

/// Konfiguracja parametrów renderowania i oświetlenia silnika [Peloton3dCanvasEngine].
class Peloton3dEngineConfig {
  /// Maksymalny zasięg widoczności wstęgi drogi przed kamerą [m].
  final double roadForwardRangeMeters;

  /// Zasięg wstęgi drogi za kamerą [m].
  final double roadBackwardRangeMeters;

  /// Krok próbkowania segmentów wstęgi drogi w pobliżu kamery [m].
  final double nearRoadStepMeters;

  /// Zasięg LOD 0 (pełna geometria roweru i kolarza) [m].
  final double lod0DistanceMeters;

  /// Zasięg LOD 1 (średni detal) [m].
  final double lod1DistanceMeters;

  /// Maksymalny zasięg renderowania kolarzy i obiektów otoczenia [m].
  final double maxRenderDistanceMeters;

  /// Znormalizowany wektor kierunku padania światła słonecznego.
  final Vector3 sunDirection;

  /// Czy rysować barierki ochronne na zakrętach, podjazdach i mecie.
  final bool enableGuardrails;

  /// Czy rysować drzewa, skały i bramy kilometrowe.
  final bool enableSceneryProps;

  /// Czy rysować nakładkę wskaźnika prędkości/mocy nad wybranym kolarzem.
  final bool enableSelectedHighlight;

  Peloton3dEngineConfig({
    this.roadForwardRangeMeters = 260.0,
    this.roadBackwardRangeMeters = 28.0,
    this.nearRoadStepMeters = 4.0,
    this.lod0DistanceMeters = 36.0,
    this.lod1DistanceMeters = 105.0,
    this.maxRenderDistanceMeters = 320.0,
    Vector3? sunDirection,
    this.enableGuardrails = true,
    this.enableSceneryProps = true,
    this.enableSelectedHighlight = true,
  }) : sunDirection = (sunDirection ?? Vector3(-0.48, 0.78, 0.40)).normalized();
}

/// Statystyki pojedynczej klatki silnika [Peloton3dCanvasEngine] do telemetrii 120 FPS.
class Peloton3dFrameStats {
  final int totalRiders;
  final int renderedRiders;
  final int culledRiders;
  final int lod0Count;
  final int lod1Count;
  final int lod2Count;
  final int roadQuadsDrawn;
  final int propsDrawn;
  final int stepTimeMicros;
  final int paintTimeMicros;
  final RaceCameraMode cameraMode;

  const Peloton3dFrameStats({
    this.totalRiders = 0,
    this.renderedRiders = 0,
    this.culledRiders = 0,
    this.lod0Count = 0,
    this.lod1Count = 0,
    this.lod2Count = 0,
    this.roadQuadsDrawn = 0,
    this.propsDrawn = 0,
    this.stepTimeMicros = 0,
    this.paintTimeMicros = 0,
    this.cameraMode = RaceCameraMode.chaseCam,
  });
}

/// Stan pojedynczego kolarza i jego roweru przygotowany do rzutowania 3D.
class Peloton3dRiderRenderData {
  final String riderId;
  final String riderName;
  final int bibNumber;
  final Color jerseyColor;
  final Color frameColor;
  final LeaderJerseyType leaderJersey;
  final WheelProfileType wheelProfile;
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double speedMs;
  final int powerWatts;
  final int cadenceRpm;
  final double leanAngleRad;
  final double wheelPhaseRad;
  final double crankPhaseRad;
  final bool isPlayerRider;
  final bool isDrafting;
  final bool isPulling;
  final bool isSprinting;
  final bool isStanding;
  final bool isCrashed;
  final bool isDnf;

  const Peloton3dRiderRenderData({
    required this.riderId,
    required this.riderName,
    required this.bibNumber,
    required this.jerseyColor,
    required this.frameColor,
    this.leaderJersey = LeaderJerseyType.none,
    this.wheelProfile = WheelProfileType.depth50mm,
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.speedMs,
    required this.powerWatts,
    required this.cadenceRpm,
    this.leanAngleRad = 0.0,
    this.wheelPhaseRad = 0.0,
    this.crankPhaseRad = 0.0,
    this.isPlayerRider = false,
    this.isDrafting = false,
    this.isPulling = false,
    this.isSprinting = false,
    this.isStanding = false,
    this.isCrashed = false,
    this.isDnf = false,
  });

  /// Buduje deskryptor 3D ze snapshotu symulacji i ciągłego stanu Boids (#184).
  factory Peloton3dRiderRenderData.fromSnapshotAndBoid({
    required RiderPositionSnapshot snapshot,
    required BoidRiderState boid,
    required double wheelPhaseRad,
    required double crankPhaseRad,
    LeaderJerseyType leaderJersey = LeaderJerseyType.none,
    WheelProfileType? wheelProfile,
  }) {
    final Color teamColor = _parseHexColor(snapshot.teamJerseyHexColor);
    final bool sprinting = snapshot.powerWatts >= 780 ||
        snapshot.activeTacticalOrder == TacticalOrder.attack;
    final bool standing = sprinting ||
        (snapshot.currentGradientPercent >= 7.5 && snapshot.powerWatts >= 360);

    final WheelProfileType resolvedWheel = wheelProfile ??
        (sprinting
            ? WheelProfileType.depth65mm
            : (snapshot.currentGradientPercent >= 6.0
                ? WheelProfileType.depth35mm
                : WheelProfileType.depth50mm));

    return Peloton3dRiderRenderData(
      riderId: snapshot.riderId,
      riderName: snapshot.riderName,
      bibNumber: snapshot.bibNumber,
      jerseyColor: teamColor,
      frameColor: Color.lerp(teamColor, const Color(0xFF111827), 0.25) ?? teamColor,
      leaderJersey: leaderJersey,
      wheelProfile: resolvedWheel,
      distanceMeters: boid.distanceMeters,
      lateralOffsetMeters: boid.lateralOffsetMeters,
      speedMs: boid.longitudinalSpeedMs,
      powerWatts: snapshot.powerWatts,
      cadenceRpm: snapshot.cadenceRpm,
      leanAngleRad: boid.leanAngleRad,
      wheelPhaseRad: wheelPhaseRad,
      crankPhaseRad: crankPhaseRad,
      isPlayerRider: snapshot.isPlayerRider,
      isDrafting: snapshot.isDrafting || boid.draftingTargetRiderId != null,
      isPulling: snapshot.isPulling,
      isSprinting: sprinting,
      isStanding: standing,
      isCrashed: snapshot.isCrashed || boid.isCrashed,
      isDnf: snapshot.isDnf || boid.isDnf,
    );
  }

  static Color _parseHexColor(String hex) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final parsed = int.tryParse('FF$clean', radix: 16);
      if (parsed != null) return Color(parsed);
    } else if (clean.length == 8) {
      final parsed = int.tryParse(clean, radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return AppColors.primaryAccent;
  }
}

/// Węzeł geometryczny 3D osi trasy wyścigu.
class Peloton3dRoadNode {
  final double distanceMeters;
  final Vector3 center;
  final Vector3 tangent;
  final Vector3 right;
  final Vector3 normal;
  final double roadWidthMeters;
  final double gradientPercent;
  final double curvature;
  final SegmentSurfaceType surfaceType;

  const Peloton3dRoadNode({
    required this.distanceMeters,
    required this.center,
    required this.tangent,
    required this.right,
    required this.normal,
    required this.roadWidthMeters,
    required this.gradientPercent,
    required this.curvature,
    required this.surfaceType,
  });
}

/// Obiekt przydrożny umieszczony w przestrzeni 3D wzdłuż trasy.
class Peloton3dSceneryProp {
  final String id;
  final Peloton3dPropType type;
  final double distanceMeters;
  final Vector3 position;
  final Vector3 tangent;
  final Vector3 right;
  final Vector3 normal;
  final double scale;
  final double yawRadians;
  final String? label;

  const Peloton3dSceneryProp({
    required this.id,
    required this.type,
    required this.distanceMeters,
    required this.position,
    required this.tangent,
    required this.right,
    required this.normal,
    this.scale = 1.0,
    this.yawRadians = 0.0,
    this.label,
  });
}

/// Wewnętrzny element kolejki sortowanej malowania kolarza.
class _RiderQueueItem {
  final Peloton3dRiderRenderData rider;
  final Peloton3dRoadNode roadSample;
  final Vector3 worldPos;
  final double cameraDepth;
  final Peloton3dLod lod;

  const _RiderQueueItem({
    required this.rider,
    required this.roadSample,
    required this.worldPos,
    required this.cameraDepth,
    required this.lod,
  });
}

/// Wewnętrzny element kolejki sortowanej malowania obiektu otoczenia.
class _PropQueueItem {
  final Peloton3dSceneryProp prop;
  final double cameraDepth;

  const _PropQueueItem({
    required this.prop,
    required this.cameraDepth,
  });
}

/// Wynik rzutowania pozycji kolarza 3D na współrzędne ekranowe 2D na potrzeby Raycastingu / Hit-testingu.
class Peloton3dProjectedRiderHit {
  final String riderId;
  final Offset screenCenter;
  final double hitRadius;
  final double cameraDepth;

  const Peloton3dProjectedRiderHit({
    required this.riderId,
    required this.screenCenter,
    required this.hitRadius,
    required this.cameraDepth,
  });
}

/// Natywny, ultrawydajny silnik renderowania 3D na Canvasie Fluttera (120 FPS).
///
/// Zapewnia pełne trójwymiarowe renderowanie wyścigu kolarskiego z wykorzystaniem
/// rzutowania macierzowego `vector_math_64` ([Scene3DMathProjection]), integracją
/// kamer wyścigowych ([CameraRigController]) oraz bezkolizyjnej fizyki peletonu
/// ([BoidsSteeringCollisionAvoidance] z zadania #184).
class Peloton3dCanvasEngine {
  final Peloton3dEngineConfig config;
  final Scene3DMathProjection projection;
  final CameraRigController cameraRig;
  final BoidsSteeringCollisionAvoidance boidsEngine;

  // Węzły osi drogi oraz obiekty otoczenia wygenerowane dla aktywnego etapu
  final List<Peloton3dRoadNode> _roadNodes = <Peloton3dRoadNode>[];
  final List<Peloton3dSceneryProp> _sceneryProps = <Peloton3dSceneryProp>[];
  double _courseTotalMeters = 25000.0;

  // Ciągły stan Boids i faz animacji per kolarz
  final Map<String, BoidRiderState> _boidStates = <String, BoidRiderState>{};
  final Map<String, double> _wheelPhases = <String, double>{};
  final Map<String, double> _crankPhases = <String, double>{};
  final List<Peloton3dRiderRenderData> _activeRiders = <Peloton3dRiderRenderData>[];

  // Kolejki sortowane back-to-front (Zero-GC reuse)
  final List<_RiderQueueItem> _riderQueue = <_RiderQueueItem>[];
  final List<_PropQueueItem> _propQueue = <_PropQueueItem>[];
  final List<Peloton3dProjectedRiderHit> _projectedHits = <Peloton3dProjectedRiderHit>[];

  /// Identyfikator aktualnie wybranego kolarza (podświetlany złotym pierścieniem taktycznym #D4AF37).
  String? selectedRiderId;

  // Statystyki ostatniej klatki
  Peloton3dFrameStats _lastStats = const Peloton3dFrameStats();
  double _lastFocusDistanceMeters = 0.0;

  // Prealokowane bufory Paint & Path dla gwarancji 120 FPS bez presji na GC
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final Path _scratchPath = Path();
  final Path _scratchPath2 = Path();

  Peloton3dCanvasEngine({
    Peloton3dEngineConfig? config,
    Scene3DMathProjection? projection,
    CameraRigController? cameraRig,
    BoidsSteeringCollisionAvoidance? boidsEngine,
  })  : config = config ?? Peloton3dEngineConfig(),
        projection = projection ?? Scene3DMathProjection(),
        cameraRig = cameraRig ?? CameraRigController(initialMode: RaceCameraMode.chaseCam),
        boidsEngine = boidsEngine ?? const BoidsSteeringCollisionAvoidance() {
    loadDefaultShowcaseCourse();
  }

  /// Aktualne statystyki wydajnościowe ostatniej wyrenderowanej klatki.
  Peloton3dFrameStats get lastStats => _lastStats;

  /// Łączna długość aktualnie załadowanej trasy w metrach.
  double get courseTotalMeters => _courseTotalMeters;

  /// Lista bieżących obiektów renderowanych kolarzy (tylko do odczytu).
  List<Peloton3dRiderRenderData> get activeRiders =>
      List<Peloton3dRiderRenderData>.unmodifiable(_activeRiders);

  /// Przełącza aktywny tryb kamery (`ChaseCam`, `MotoTvCam`, `HeliCam`, `FinishLineCam`).
  void switchCameraMode(
    RaceCameraMode mode, {
    bool immediate = false,
    double transitionDurationSeconds = 0.75,
  }) {
    cameraRig.switchMode(
      mode,
      immediate: immediate,
      transitionDurationSeconds: transitionDurationSeconds,
    );
  }

  /// Przekazuje gest manualnego obrotu i przybliżenia do kontrolera kamery.
  void addCameraOrbit({
    double deltaYaw = 0.0,
    double deltaPitch = 0.0,
    double deltaZoom = 0.0,
  }) {
    cameraRig.addManualOrbit(
      deltaYaw: deltaYaw,
      deltaPitch: deltaPitch,
      deltaZoom: deltaZoom,
    );
  }

  /// Resetuje manualny obrót kamery do domyślnego kąta.
  void resetCameraOrbit() {
    cameraRig.resetManualOrbit();
  }

  /// Wykrywa kliknięcie 2D na kolarza wyrenderowanego w scenie 3D (Raycasting / Hit-testing).
  String? hitTestRider(Offset tapPosition) {
    String? bestRiderId;
    double bestWeightedScore = double.infinity;

    for (final hit in _projectedHits) {
      final double dist = (hit.screenCenter - tapPosition).distance;
      if (dist <= hit.hitRadius) {
        final double weightedScore = dist + (hit.cameraDepth * 0.65);
        if (weightedScore < bestWeightedScore) {
          bestWeightedScore = weightedScore;
          bestRiderId = hit.riderId;
        }
      }
    }
    return bestRiderId;
  }

  /// Ładuje domyślną trasę pokazową (alpejski etap z zakrętami, brukiem i metą).
  void loadDefaultShowcaseCourse() {
    final demoSegments = <StageSegment>[
      const StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 4.0,
        startElevationM: 220.0,
        endElevationM: 280.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        roadBearingDegrees: 15.0,
        windDirectionDegrees: 95.0,
        technicalDifficulty: 25.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      const StageSegment(
        index: 1,
        startKm: 4.0,
        lengthKm: 3.5,
        startElevationM: 280.0,
        endElevationM: 497.0,
        surfaceType: SegmentSurfaceType.roughAsphalt,
        roadBearingDegrees: 52.0,
        windDirectionDegrees: 120.0,
        technicalDifficulty: 60.0,
        sprintOrKomClassification: SegmentClassification.cat2,
      ),
      const StageSegment(
        index: 2,
        startKm: 7.5,
        lengthKm: 2.5,
        startElevationM: 497.0,
        endElevationM: 510.0,
        surfaceType: SegmentSurfaceType.cobblestonesSector3,
        roadBearingDegrees: 35.0,
        windDirectionDegrees: 80.0,
        technicalDifficulty: 70.0,
        sprintOrKomClassification: SegmentClassification.intermediateSprint,
      ),
      const StageSegment(
        index: 3,
        startKm: 10.0,
        lengthKm: 5.0,
        startElevationM: 510.0,
        endElevationM: 750.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        roadBearingDegrees: 5.0,
        windDirectionDegrees: 60.0,
        technicalDifficulty: 45.0,
        sprintOrKomClassification: SegmentClassification.finishLine,
      ),
    ];
    loadCourseFromSegments(demoSegments, totalDistanceMeters: 15000.0);
  }

  /// Buduje geometrię 3D trasy i otoczenia na podstawie obiektu [RaceStage].
  void loadCourseFromStage(RaceStage stage) {
    final double totalMeters = math.max(1000.0, stage.totalDistanceKm * 1000.0);
    if (stage.segments.isEmpty) {
      loadCourseFromSegments(
        const <StageSegment>[
          StageSegment(
            index: 0,
            startKm: 0.0,
            lengthKm: 15.0,
            startElevationM: 120.0,
            endElevationM: 420.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 30.0,
            windDirectionDegrees: 90.0,
            roadBearingDegrees: 0.0,
            sprintOrKomClassification: SegmentClassification.finishLine,
          ),
        ],
        totalDistanceMeters: totalMeters,
      );
      return;
    }
    loadCourseFromSegments(stage.segments, totalDistanceMeters: totalMeters);
  }

  /// Buduje geometrię 3D wstęgi drogi, barierek, drzew, skał i bram kilometrowych.
  void loadCourseFromSegments(
    List<StageSegment> segments, {
    double? totalDistanceMeters,
  }) {
    _roadNodes.clear();
    _sceneryProps.clear();

    final double computedTotal = totalDistanceMeters ??
        (segments.isNotEmpty ? math.max(1000.0, segments.last.endKm * 1000.0) : 15000.0);
    _courseTotalMeters = computedTotal;

    // Krok próbkowania węzłów trasy (co 10m daje bardzo gładkie zakręty i małą tablicę)
    const double nodeStepMeters = 10.0;
    final int nodeCount = (computedTotal / nodeStepMeters).ceil() + 1;

    Vector3 cursor = Vector3(0.0, 0.0, 0.0);
    double currentHeadingRad = 0.0;

    for (int i = 0; i < nodeCount; i++) {
      final double dist = math.min(i * nodeStepMeters, computedTotal);
      final StageSegment? seg = _findSegmentAtDistance(segments, dist / 1000.0);

      // Płynne krzywizny zakrętów (serpentyny + łuki dolinowe)
      final double segDifficulty = seg?.technicalDifficulty ?? 30.0;
      final double curveIntensity = (segDifficulty / 100.0).clamp(0.15, 1.0);
      final double curvature = 0.0045 *
          curveIntensity *
          (math.sin(dist * 0.0085) + 0.55 * math.cos(dist * 0.021));

      final double gradPercent = seg?.gradientPercent ?? 0.0;
      final double slopeAngle = math.atan(gradPercent / 100.0);
      final double roadWidth = boidsEngine.resolveRoadWidthMeters(segment: seg);
      final SegmentSurfaceType surface = seg?.surfaceType ?? SegmentSurfaceType.smoothAsphalt;

      final double cosSlope = math.cos(slopeAngle);
      final double sinSlope = math.sin(slopeAngle);

      final Vector3 tangent = Vector3(
        math.sin(currentHeadingRad) * cosSlope,
        sinSlope,
        math.cos(currentHeadingRad) * cosSlope,
      ).normalized();

      final Vector3 worldUp = Vector3(0.0, 1.0, 0.0);
      Vector3 right = tangent.cross(worldUp);
      if (right.length2 < 1e-6) {
        right = Vector3(1.0, 0.0, 0.0);
      } else {
        right.normalize();
      }
      final Vector3 normal = right.cross(tangent).normalized();

      _roadNodes.add(
        Peloton3dRoadNode(
          distanceMeters: dist,
          center: cursor.clone(),
          tangent: tangent,
          right: right,
          normal: normal,
          roadWidthMeters: roadWidth,
          gradientPercent: gradPercent,
          curvature: curvature,
          surfaceType: surface,
        ),
      );

      // Przesunięcie kursora do kolejnego węzła
      cursor = cursor + tangent * nodeStepMeters;
      currentHeadingRad += curvature * nodeStepMeters;
    }

    _populateSceneryProps();
  }

  StageSegment? _findSegmentAtDistance(List<StageSegment> segments, double km) {
    for (final s in segments) {
      if (km >= s.startKm && km <= s.endKm) return s;
    }
    return segments.isNotEmpty ? segments.last : null;
  }

  /// Deterministycznie rozmieszcza drzewa, skały i bramy kilometrowe wzdłuż trasy.
  void _populateSceneryProps() {
    if (_roadNodes.isEmpty) return;

    // 1. Drzewa i skały po obu stronach drogi co ~18m
    for (int i = 2; i < _roadNodes.length - 2; i += 2) {
      final node = _roadNodes[i];
      final int hash = ((node.distanceMeters * 13.37).round() ^ (i * 2654435761)) & 0x7fffffff;
      final double rand01 = (hash % 1000) / 1000.0;
      final double side = (hash % 2 == 0) ? 1.0 : -1.0;

      // Drzewo lub skała w bezpiecznej odległości od krawędzi asfaltu
      final double lateral = side * (node.roadWidthMeters * 0.5 + 3.8 + rand01 * 9.5);
      final Vector3 pos = node.center + node.right * lateral;

      final Peloton3dPropType propType;
      if (node.gradientPercent >= 5.5 || node.center.y > 40.0) {
        propType = (hash % 5 == 0)
            ? Peloton3dPropType.alpineCrag
            : (hash % 3 == 0 ? Peloton3dPropType.rockBoulder : Peloton3dPropType.pineTree);
      } else if (_isCobblestoneSurface(node.surfaceType)) {
        propType = (hash % 4 == 0)
            ? Peloton3dPropType.rockBoulder
            : Peloton3dPropType.deciduousTree;
      } else {
        propType = (hash % 4 == 0)
            ? Peloton3dPropType.cypressTree
            : (hash % 2 == 0
                ? Peloton3dPropType.pineTree
                : Peloton3dPropType.deciduousTree);
      }

      _sceneryProps.add(
        Peloton3dSceneryProp(
          id: 'prop_${i}_$hash',
          type: propType,
          distanceMeters: node.distanceMeters,
          position: pos,
          tangent: node.tangent,
          right: node.right,
          normal: node.normal,
          scale: 0.85 + (hash % 45) / 100.0,
          yawRadians: (hash % 628) / 100.0,
        ),
      );
    }

    // 2. Bramy kilometrowe (co 1000m), Flamme Rouge (1km przed metą) oraz Brama Mety
    final double finishDist = _courseTotalMeters;
    for (double d = 1000.0; d < finishDist - 250.0; d += 1000.0) {
      final node = sampleRoadAtDistance(d);
      final double kmLeft = ((finishDist - d) / 1000.0);
      final bool isFlamme = (kmLeft - 1.0).abs() < 0.15;
      _sceneryProps.add(
        Peloton3dSceneryProp(
          id: 'gate_${d.toInt()}',
          type: isFlamme ? Peloton3dPropType.flammeRougeGate : Peloton3dPropType.kilometerGate,
          distanceMeters: d,
          position: node.center,
          tangent: node.tangent,
          right: node.right,
          normal: node.normal,
          scale: 1.0,
          label: isFlamme ? '1 KM • FLAMME ROUGE' : '${kmLeft.toStringAsFixed(0)} KM',
        ),
      );
    }

    final finishNode = sampleRoadAtDistance(finishDist);
    _sceneryProps.add(
      Peloton3dSceneryProp(
        id: 'gate_finish',
        type: Peloton3dPropType.finishGantry,
        distanceMeters: finishDist,
        position: finishNode.center,
        tangent: finishNode.tangent,
        right: finishNode.right,
        normal: finishNode.normal,
        scale: 1.15,
        label: 'ARRIVÉE • META',
      ),
    );
  }

  /// Szybka interpolacja pozycji, stycznych i nachylenia drogi dla zadanego dystansu [m].
  Peloton3dRoadNode sampleRoadAtDistance(double distanceMeters) {
    if (_roadNodes.isEmpty) {
      return Peloton3dRoadNode(
        distanceMeters: distanceMeters,
        center: Vector3(0.0, 0.0, distanceMeters),
        tangent: Vector3(0.0, 0.0, 1.0),
        right: Vector3(1.0, 0.0, 0.0),
        normal: Vector3(0.0, 1.0, 0.0),
        roadWidthMeters: 7.0,
        gradientPercent: 0.0,
        curvature: 0.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
      );
    }

    final double clamped = distanceMeters.clamp(0.0, _courseTotalMeters);
    int low = 0;
    int high = _roadNodes.length - 1;
    while (low + 1 < high) {
      final int mid = (low + high) >> 1;
      if (_roadNodes[mid].distanceMeters <= clamped) {
        low = mid;
      } else {
        high = mid;
      }
    }

    final a = _roadNodes[low];
    final b = _roadNodes[high];
    final double span = b.distanceMeters - a.distanceMeters;
    final double t = span > 1e-5 ? ((clamped - a.distanceMeters) / span).clamp(0.0, 1.0) : 0.0;

    final Vector3 center = a.center + (b.center - a.center) * t;
    final Vector3 tangent = (a.tangent + (b.tangent - a.tangent) * t).normalized();
    final Vector3 right = (a.right + (b.right - a.right) * t).normalized();
    final Vector3 normal = (a.normal + (b.normal - a.normal) * t).normalized();

    return Peloton3dRoadNode(
      distanceMeters: clamped,
      center: center,
      tangent: tangent,
      right: right,
      normal: normal,
      roadWidthMeters: a.roadWidthMeters + (b.roadWidthMeters - a.roadWidthMeters) * t,
      gradientPercent: a.gradientPercent + (b.gradientPercent - a.gradientPercent) * t,
      curvature: a.curvature + (b.curvature - a.curvature) * t,
      surfaceType: t < 0.5 ? a.surfaceType : b.surfaceType,
    );
  }

  /// Wykonuje krok fizyki Boids (#184), animacji kół/korb i aktualizacji kamer 3D.
  Peloton3dFrameStats stepFrame({
    required double dtSeconds,
    required List<RiderPositionSnapshot> snapshots,
    String? focusRiderId,
    StageSegment? activeSegment,
    double windSpeedKmh = 0.0,
    Map<String, LeaderJerseyType>? leaderJerseys,
    Map<String, WheelProfileType>? wheelProfiles,
  }) {
    final Stopwatch sw = Stopwatch()..start();
    final double safeDt = dtSeconds.clamp(0.001, 0.05);

    if (snapshots.isEmpty) {
      _activeRiders.clear();
      sw.stop();
      return _lastStats;
    }

    // 1. Synchronizacja i krok ciągłej fizyki Boids (zadanie #184)
    final List<BoidRiderState> currentBoids = <BoidRiderState>[];
    for (final snap in snapshots) {
      final existing = _boidStates[snap.riderId];
      if (existing == null) {
        currentBoids.add(BoidRiderState.fromSnapshot(snap));
      } else {
        // Płynne dociąganie prędkości docelowej i pozycji wzdłużnej do symulatora
        final double syncedDist =
            existing.distanceMeters + (snap.distanceCoveredMeters - existing.distanceMeters) * 0.18;
        currentBoids.add(
          existing.copyWith(
            distanceMeters: syncedDist,
            targetSpeedMs: snap.speedMs,
            tacticalOrder: snap.activeTacticalOrder,
            isCrashed: snap.isCrashed,
            isDnf: snap.isDnf,
          ),
        );
      }
    }

    final BoidsFrameResult boidsResult = boidsEngine.stepFrame(
      riders: currentBoids,
      dtSeconds: safeDt,
      segment: activeSegment,
      windSpeedKmh: windSpeedKmh,
    );

    final Map<String, BoidRiderState> updatedBoidMap = <String, BoidRiderState>{
      for (final b in boidsResult.riders) b.riderId: b,
    };
    _boidStates
      ..clear()
      ..addAll(updatedBoidMap);

    // 2. Aktualizacja faz obrotu kół (v * dt / R) oraz korb (RPM) i budowa deskryptorów 3D
    const double wheelRadiusMeters = 0.34;
    _activeRiders.clear();

    Peloton3dRiderRenderData? focusRider;
    double sumX = 0.0;
    double sumY = 0.0;
    double sumZ = 0.0;
    int activeCount = 0;

    for (final snap in snapshots) {
      final boid = updatedBoidMap[snap.riderId] ?? BoidRiderState.fromSnapshot(snap);
      final double prevWheel = _wheelPhases[snap.riderId] ?? 0.0;
      final double prevCrank = _crankPhases[snap.riderId] ?? (snap.bibNumber * 0.7);

      final double wheelDelta = (boid.longitudinalSpeedMs * safeDt) / wheelRadiusMeters;
      final double crankAngularVel = (snap.cadenceRpm * 2.0 * math.pi) / 60.0;
      final double crankDelta = crankAngularVel * safeDt;

      final double nextWheel = (prevWheel + wheelDelta) % (2.0 * math.pi);
      final double nextCrank = (prevCrank + crankDelta) % (2.0 * math.pi);

      _wheelPhases[snap.riderId] = nextWheel;
      _crankPhases[snap.riderId] = nextCrank;

      final renderData = Peloton3dRiderRenderData.fromSnapshotAndBoid(
        snapshot: snap,
        boid: boid,
        wheelPhaseRad: nextWheel,
        crankPhaseRad: nextCrank,
        leaderJersey: leaderJerseys?[snap.riderId] ?? LeaderJerseyType.none,
        wheelProfile: wheelProfiles?[snap.riderId],
      );
      _activeRiders.add(renderData);

      if (snap.riderId == focusRiderId || (focusRider == null && snap.isPlayerRider)) {
        focusRider = renderData;
      }

      if (!renderData.isDnf) {
        final node = sampleRoadAtDistance(renderData.distanceMeters);
        final worldP = node.center + node.right * renderData.lateralOffsetMeters;
        sumX += worldP.x;
        sumY += worldP.y;
        sumZ += worldP.z;
        activeCount++;
      }
    }

    focusRider ??= _activeRiders.first;
    _lastFocusDistanceMeters = focusRider.distanceMeters;

    // 3. Aktualizacja kamer wyścigowych (ChaseCam, MotoTvCam, HeliCam, FinishLineCam)
    final focusNode = sampleRoadAtDistance(focusRider.distanceMeters);
    final Vector3 focusWorldPos =
        focusNode.center + focusNode.right * focusRider.lateralOffsetMeters;
    final Cyclist3DPose targetPose = _buildCyclistPoseFromNode(
      node: focusNode,
      worldPos: focusWorldPos,
      leanAngleRad: focusRider.leanAngleRad,
    );

    final Vector3 pelotonCentroid = activeCount > 0
        ? Vector3(sumX / activeCount, sumY / activeCount, sumZ / activeCount)
        : focusWorldPos;

    final finishNode = sampleRoadAtDistance(_courseTotalMeters);

    cameraRig.update(
      dtSeconds: safeDt,
      targetRiderPose: targetPose,
      pelotonCentroid: pelotonCentroid,
      pelotonSpreadRadius: math.max(12.0, boidsResult.pelotonLengthMeters * 0.45),
      finishLinePosition: finishNode.center,
      finishApproachDirection: finishNode.tangent,
      isSprinting: focusRider.isSprinting,
      isAttacking: focusRider.powerWatts >= 550,
      riderSpeedMs: focusRider.speedMs,
    );

    sw.stop();
    _lastStats = Peloton3dFrameStats(
      totalRiders: _activeRiders.length,
      renderedRiders: _lastStats.renderedRiders,
      culledRiders: _lastStats.culledRiders,
      lod0Count: _lastStats.lod0Count,
      lod1Count: _lastStats.lod1Count,
      lod2Count: _lastStats.lod2Count,
      roadQuadsDrawn: _lastStats.roadQuadsDrawn,
      propsDrawn: _lastStats.propsDrawn,
      stepTimeMicros: sw.elapsedMicroseconds,
      paintTimeMicros: _lastStats.paintTimeMicros,
      cameraMode: cameraRig.activeMode,
    );
    return _lastStats;
  }

  /// Umożliwia bezpośrednie ustawienie listy kolarzy (np. w trybie podglądu lub testach).
  void setDirectRidersForRender(
    List<Peloton3dRiderRenderData> riders, {
    String? focusRiderId,
    double dtSeconds = 1.0 / 60.0,
  }) {
    _activeRiders
      ..clear()
      ..addAll(riders);
    if (_activeRiders.isEmpty) return;

    final focus = _activeRiders.firstWhere(
      (r) => r.riderId == focusRiderId || r.isPlayerRider,
      orElse: () => _activeRiders.first,
    );
    _lastFocusDistanceMeters = focus.distanceMeters;
    final focusNode = sampleRoadAtDistance(focus.distanceMeters);
    final Vector3 focusPos = focusNode.center + focusNode.right * focus.lateralOffsetMeters;
    final targetPose = _buildCyclistPoseFromNode(
      node: focusNode,
      worldPos: focusPos,
      leanAngleRad: focus.leanAngleRad,
    );
    final finishNode = sampleRoadAtDistance(_courseTotalMeters);
    cameraRig.update(
      dtSeconds: dtSeconds.clamp(0.001, 0.05),
      targetRiderPose: targetPose,
      pelotonCentroid: focusPos,
      finishLinePosition: finishNode.center,
      finishApproachDirection: finishNode.tangent,
      isSprinting: focus.isSprinting,
      riderSpeedMs: focus.speedMs,
    );
  }

  Cyclist3DPose _buildCyclistPoseFromNode({
    required Peloton3dRoadNode node,
    required Vector3 worldPos,
    required double leanAngleRad,
  }) {
    final rot = Matrix3.columns(node.right, node.normal, node.tangent);
    final mat = Matrix4.identity()
      ..setFromTranslationRotation(worldPos, Quaternion.fromRotation(rot));
    return Cyclist3DPose(
      position: worldPos,
      tangent: node.tangent,
      lateralRight: node.right,
      surfaceNormal: node.normal,
      yaw: math.atan2(node.tangent.x, node.tangent.z),
      pitch: math.asin(node.tangent.y.clamp(-1.0, 1.0)),
      roll: leanAngleRad,
      rotationMatrix: rot,
      transformMatrix: mat,
      orientation: Quaternion.fromRotation(rot),
      frontWheelContact: worldPos + node.tangent * 0.50,
      rearWheelContact: worldPos - node.tangent * 0.50,
      headPosition: worldPos + node.normal * 1.38 + node.tangent * 0.16,
    );
  }

  /// Główna metoda renderująca całą scenę 3D na Canvas Fluttera w 120 FPS.
  Peloton3dFrameStats render(
    Canvas canvas,
    Size size, {
    DynamicSkyboxAndLightingPainter? skyboxPainter,
  }) {
    if (size.width <= 1.0 || size.height <= 1.0) return _lastStats;

    final Stopwatch paintSw = Stopwatch()..start();

    // 1. Aktualizacja macierzy widoku i projekcji 3D w vector_math_64
    projection.updateCamera(
      cameraRig.toCameraConfig(),
      viewportWidth: size.width,
      viewportHeight: size.height,
    );

    // 2. Wyznaczenie linii horyzontu na ekranie
    final Vector3 camForward = (cameraRig.target - cameraRig.position);
    if (camForward.length2 > 1e-6) {
      camForward.normalize();
    } else {
      camForward.setValues(0.0, 0.0, 1.0);
    }
    final Vector3 horizDir = Vector3(camForward.x, 0.0, camForward.z);
    if (horizDir.length2 > 1e-6) horizDir.normalize();
    final projHorizon = projection.worldToScreen(cameraRig.position + horizDir * 1800.0);
    final double horizonY = projHorizon.isInFrontOfCamera
        ? projHorizon.screenY.clamp(size.height * 0.10, size.height * 0.84)
        : size.height * 0.40;

    // 3. Niebo (DynamicSkyboxAndLightingPainter jeśli podany), pasmo górskie w paralaksie i podłoże doliny
    if (skyboxPainter != null) {
      final SunLightState sunState = DynamicSkyboxAndLightingPainter.computeSunLightState(
        timeOfDay: skyboxPainter.timeOfDay,
        weatherCondition: skyboxPainter.weatherCondition,
        elapsedSeconds: skyboxPainter.elapsedSeconds,
      );
      skyboxPainter.renderSkybox(
        canvas: canvas,
        size: size,
        horizonY: horizonY,
        sunState: sunState,
      );
      _drawMountainRidgeAndGround(canvas, size, horizonY);
    } else {
      _drawAtmosphereAndBackdrop(canvas, size, horizonY);
    }

    // 4. Trójwymiarowa wstęga drogi z asfaltem/brukiem, pasami ruchu i barierkami
    final int roadQuadsDrawn = _drawRoadRibbonAndGuardrails(canvas, size);

    // 5. Przygotowanie i sortowanie głębokości obiektów otoczenia (drzewa, skały, bramy)
    final int propsDrawn = config.enableSceneryProps ? _drawSceneryProps(canvas) : 0;

    // 6. Przygotowanie, Frustum Culling, LOD i rysowanie kolarzy 3D
    final _RiderRenderCounts counts = _drawPelotonRiders(canvas);

    paintSw.stop();
    _lastStats = Peloton3dFrameStats(
      totalRiders: _activeRiders.length,
      renderedRiders: counts.rendered,
      culledRiders: counts.culled,
      lod0Count: counts.lod0,
      lod1Count: counts.lod1,
      lod2Count: counts.lod2,
      roadQuadsDrawn: roadQuadsDrawn,
      propsDrawn: propsDrawn,
      stepTimeMicros: _lastStats.stepTimeMicros,
      paintTimeMicros: paintSw.elapsedMicroseconds,
      cameraMode: cameraRig.activeMode,
    );
    return _lastStats;
  }

  // ===========================================================================
  // 1. ATMOSFERA, NIEBO I PASMO GÓRSKIE
  // ===========================================================================

  void _drawAtmosphereAndBackdrop(Canvas canvas, Size size, double horizonY) {
    final double w = size.width;
    final double h = size.height;

    // Gradient nieba alpejskiego dopasowany do estetyki Pro Peloton Manager
    final Rect skyRect = Rect.fromLTWH(0.0, 0.0, w, horizonY + 8.0);
    _fillPaint.shader = ui.Gradient.linear(
      Offset.zero,
      Offset(0.0, horizonY),
      const <Color>[
        Color(0xFF0B1324),
        Color(0xFF1A2C4E),
        Color(0xFF476C9B),
        Color(0xFF93B5D6),
      ],
      const <double>[0.0, 0.35, 0.72, 1.0],
    );
    canvas.drawRect(skyRect, _fillPaint);
    _fillPaint.shader = null;

    // Tarcza słoneczna z poświatą
    final double sunScreenX = w * 0.24;
    final double sunScreenY = (horizonY * 0.34).clamp(28.0, h * 0.35);
    _fillPaint.shader = ui.Gradient.radial(
      Offset(sunScreenX, sunScreenY),
      95.0,
      const <Color>[
        Color(0xCCFFFBEB),
        Color(0x44FDE68A),
        Color(0x00FDE68A),
      ],
      const <double>[0.0, 0.28, 1.0],
    );
    canvas.drawCircle(Offset(sunScreenX, sunScreenY), 95.0, _fillPaint);
    _fillPaint.shader = null;

    _drawMountainRidgeAndGround(canvas, size, horizonY);
  }

  void _drawMountainRidgeAndGround(Canvas canvas, Size size, double horizonY) {
    final double w = size.width;
    final double h = size.height;

    // Pasmo górskie z cieniowaniem kierunkowym (paralaksa od obrotu kamery)
    final double yawOffset = math.atan2(
      cameraRig.target.x - cameraRig.position.x,
      cameraRig.target.z - cameraRig.position.z,
    );
    final double parallax = (yawOffset * 140.0) % w;

    _scratchPath.reset();
    _scratchPath.moveTo(0.0, horizonY);
    const int ridgeSteps = 18;
    for (int i = 0; i <= ridgeSteps; i++) {
      final double x = (i / ridgeSteps) * w;
      final double sample = (x + parallax) * 0.012;
      final double peakH = (math.sin(sample).abs() * 52.0) +
          (math.cos(sample * 2.3).abs() * 24.0) +
          14.0;
      _scratchPath.lineTo(x, horizonY - peakH);
    }
    _scratchPath.lineTo(w, horizonY);
    _scratchPath.close();
    _fillPaint.color = const Color(0xFF1F2B3D);
    canvas.drawPath(_scratchPath, _fillPaint);

    // Podłoże terenu poniżej horyzontu
    _fillPaint.shader = ui.Gradient.linear(
      Offset(0.0, horizonY),
      Offset(0.0, h),
      const <Color>[
        Color(0xFF1D3324),
        Color(0xFF122117),
        Color(0xFF0D1711),
      ],
      const <double>[0.0, 0.45, 1.0],
    );
    canvas.drawRect(Rect.fromLTWH(0.0, horizonY, w, h - horizonY), _fillPaint);
    _fillPaint.shader = null;
  }

  // ===========================================================================
  // 2. WSTĘGA DROGI 3D, TEKSTURA ASFALTU/BRUKU, PASY RUCHU I BARIERKI
  // ===========================================================================

  int _drawRoadRibbonAndGuardrails(Canvas canvas, Size size) {
    final double startDist =
        (_lastFocusDistanceMeters - config.roadBackwardRangeMeters).clamp(0.0, _courseTotalMeters);
    final double endDist =
        (_lastFocusDistanceMeters + config.roadForwardRangeMeters).clamp(0.0, _courseTotalMeters);
    if (endDist <= startDist + 2.0) return 0;

    // Adaptacyjny krok: gęściej blisko kamery, rzadziej w oddali dla 120 FPS
    final List<Peloton3dRoadNode> ribbonNodes = <Peloton3dRoadNode>[];
    double cursorDist = startDist;
    while (cursorDist < endDist) {
      ribbonNodes.add(sampleRoadAtDistance(cursorDist));
      final double distToFocus = (cursorDist - _lastFocusDistanceMeters).abs();
      final double step = distToFocus < 45.0
          ? config.nearRoadStepMeters
          : (distToFocus < 120.0 ? config.nearRoadStepMeters * 2.0 : config.nearRoadStepMeters * 3.5);
      cursorDist += step;
    }
    ribbonNodes.add(sampleRoadAtDistance(endDist));

    int quadsDrawn = 0;

    // Rysowanie od najdalszego segmentu do najbliższego (Painter's Algorithm)
    for (int i = ribbonNodes.length - 2; i >= 0; i--) {
      final a = ribbonNodes[i];
      final b = ribbonNodes[i + 1];

      final double halfWa = a.roadWidthMeters * 0.5;
      final double halfWb = b.roadWidthMeters * 0.5;

      // Pobocze (verge) nieco szersze niż asfalt
      final pALeftVerge = projection.worldToScreen(a.center - a.right * (halfWa + 1.3));
      final pARightVerge = projection.worldToScreen(a.center + a.right * (halfWa + 1.3));
      final pBLeftVerge = projection.worldToScreen(b.center - b.right * (halfWb + 1.3));
      final pBRightVerge = projection.worldToScreen(b.center + b.right * (halfWb + 1.3));

      final pALeft = projection.worldToScreen(a.center - a.right * halfWa);
      final pARight = projection.worldToScreen(a.center + a.right * halfWa);
      final pBLeft = projection.worldToScreen(b.center - b.right * halfWb);
      final pBRight = projection.worldToScreen(b.center + b.right * halfWb);

      if (!pALeft.isInFrontOfCamera &&
          !pARight.isInFrontOfCamera &&
          !pBLeft.isInFrontOfCamera &&
          !pBRight.isInFrontOfCamera) {
        continue;
      }
      if (!pALeft.isInFrontOfCamera ||
          !pARight.isInFrontOfCamera ||
          !pBLeft.isInFrontOfCamera ||
          !pBRight.isInFrontOfCamera) {
        continue;
      }

      // Pobocze trawiaste/żwirowe
      _drawQuad(
        canvas,
        pALeftVerge,
        pARightVerge,
        pBRightVerge,
        pBLeftVerge,
        _isCobblestoneSurface(a.surfaceType)
            ? const Color(0xFF2F2E28)
            : const Color(0xFF233828),
      );

      // Cieniowanie kierunkowe nawierzchni drogi względem wektora słońca
      final double sunDot = a.normal.dot(config.sunDirection).clamp(0.15, 1.0);
      final Color roadColor = _resolveRoadSurfaceColor(
        surfaceType: a.surfaceType,
        segmentIndex: i,
        sunDot: sunDot,
      );

      _drawQuad(canvas, pALeft, pARight, pBRight, pBLeft, roadColor);
      quadsDrawn++;

      // Tekstura bruku lub ziarna asfaltu na bliskim planie
      if (pALeft.depthEye < 65.0) {
        if (_isCobblestoneSurface(a.surfaceType)) {
          _drawCobblestoneRows(canvas, a, b, halfWa, halfWb);
        } else if (i % 2 == 0) {
          // Subtelna faktura asfaltu
          _drawAsphaltGrain(canvas, a, b, halfWa, halfWb);
        }
      }

      // Białe linie krawędziowe (pasy ruchu)
      final double lineWidth = (1.6 * pALeft.perspectiveScale).clamp(0.8, 3.8);
      _strokePaint
        ..color = const Color(0xCCFFFFFF)
        ..strokeWidth = lineWidth;
      canvas.drawLine(
        Offset(pALeft.screenX, pALeft.screenY),
        Offset(pBLeft.screenX, pBLeft.screenY),
        _strokePaint,
      );
      canvas.drawLine(
        Offset(pARight.screenX, pARight.screenY),
        Offset(pBRight.screenX, pBRight.screenY),
        _strokePaint,
      );

      // Przerywana linia środkowa na asfalcie (brak na bruku i szutrze)
      if (!_isCobblestoneSurface(a.surfaceType) &&
          a.surfaceType != SegmentSurfaceType.gravelStrade &&
          ((a.distanceMeters ~/ 8) % 2 == 0)) {
        final pACenter = projection.worldToScreen(a.center + a.normal * 0.01);
        final pBCenter = projection.worldToScreen(b.center + b.normal * 0.01);
        if (pACenter.isInFrontOfCamera && pBCenter.isInFrontOfCamera) {
          _strokePaint
            ..color = const Color(0x99F3F4F6)
            ..strokeWidth = (1.4 * pACenter.perspectiveScale).clamp(0.7, 3.2);
          canvas.drawLine(
            Offset(pACenter.screenX, pACenter.screenY),
            Offset(pBCenter.screenX, pBCenter.screenY),
            _strokePaint,
          );
        }
      }

      // Barierki ochronne (na zakrętach, stromych podjazdach lub w strefie mety)
      if (config.enableGuardrails && pALeft.depthEye < 140.0) {
        final bool nearFinish = (_courseTotalMeters - a.distanceMeters) < 600.0;
        final bool sharpTurn = a.curvature.abs() > 0.0022 || a.gradientPercent.abs() > 5.0;
        if (nearFinish || sharpTurn) {
          _drawGuardrailSpan(canvas, a, b, side: -1.0, isFinishZone: nearFinish);
          _drawGuardrailSpan(canvas, a, b, side: 1.0, isFinishZone: nearFinish);
        }
      }
    }

    return quadsDrawn;
  }

  Color _resolveRoadSurfaceColor({
    required SegmentSurfaceType surfaceType,
    required int segmentIndex,
    required double sunDot,
  }) {
    final double shade = 0.72 + 0.28 * sunDot;
    final Color base;
    switch (surfaceType) {
      case SegmentSurfaceType.smoothAsphalt:
        base = segmentIndex.isEven ? const Color(0xFF262B36) : const Color(0xFF232833);
        break;
      case SegmentSurfaceType.roughAsphalt:
        base = segmentIndex.isEven ? const Color(0xFF2F3542) : const Color(0xFF2B313D);
        break;
      case SegmentSurfaceType.cobblestonesSector1:
      case SegmentSurfaceType.cobblestonesSector2:
      case SegmentSurfaceType.cobblestonesSector3:
      case SegmentSurfaceType.cobblestonesSector4:
      case SegmentSurfaceType.cobblestonesSector5:
        base = segmentIndex.isEven ? const Color(0xFF4B505C) : const Color(0xFF424752);
        break;
      case SegmentSurfaceType.gravelStrade:
        base = segmentIndex.isEven ? const Color(0xFFC2B29B) : const Color(0xFFB5A48C);
        break;
      case SegmentSurfaceType.concrete:
        base = segmentIndex.isEven ? const Color(0xFF565C68) : const Color(0xFF4F5561);
        break;
    }
    return _shadeColor(base, shade);
  }

  void _drawCobblestoneRows(
    Canvas canvas,
    Peloton3dRoadNode a,
    Peloton3dRoadNode b,
    double halfWa,
    double halfWb,
  ) {
    final pMidL = projection.worldToScreen(
      ((a.center + b.center) * 0.5) - a.right * (halfWa * 0.85) + a.normal * 0.015,
    );
    final pMidR = projection.worldToScreen(
      ((a.center + b.center) * 0.5) + a.right * (halfWb * 0.85) + a.normal * 0.015,
    );
    if (!pMidL.isInFrontOfCamera || !pMidR.isInFrontOfCamera) return;

    _strokePaint
      ..color = const Color(0x551F242D)
      ..strokeWidth = (1.8 * pMidL.perspectiveScale).clamp(0.8, 4.0);
    canvas.drawLine(
      Offset(pMidL.screenX, pMidL.screenY),
      Offset(pMidR.screenX, pMidR.screenY),
      _strokePaint,
    );
  }

  void _drawAsphaltGrain(
    Canvas canvas,
    Peloton3dRoadNode a,
    Peloton3dRoadNode b,
    double halfWa,
    double halfWb,
  ) {
    final p1 = projection.worldToScreen(a.center - a.right * (halfWa * 0.35));
    final p2 = projection.worldToScreen(b.center - b.right * (halfWb * 0.35));
    if (!p1.isInFrontOfCamera || !p2.isInFrontOfCamera) return;
    _strokePaint
      ..color = const Color(0x18000000)
      ..strokeWidth = (2.2 * p1.perspectiveScale).clamp(0.6, 4.5);
    canvas.drawLine(Offset(p1.screenX, p1.screenY), Offset(p2.screenX, p2.screenY), _strokePaint);
  }

  void _drawGuardrailSpan(
    Canvas canvas,
    Peloton3dRoadNode a,
    Peloton3dRoadNode b, {
    required double side,
    required bool isFinishZone,
  }) {
    final double offsetA = side * (a.roadWidthMeters * 0.5 + 0.55);
    final double offsetB = side * (b.roadWidthMeters * 0.5 + 0.55);
    const double railHeight = 0.88;

    final pABase = projection.worldToScreen(a.center + a.right * offsetA);
    final pATop = projection.worldToScreen(a.center + a.right * offsetA + a.normal * railHeight);
    final pBBase = projection.worldToScreen(b.center + b.right * offsetB);
    final pBTop = projection.worldToScreen(b.center + b.right * offsetB + b.normal * railHeight);

    if (!pABase.isInFrontOfCamera ||
        !pATop.isInFrontOfCamera ||
        !pBBase.isInFrontOfCamera ||
        !pBTop.isInFrontOfCamera) {
      return;
    }

    // Panel barierki w strefie mety lub stalowa poręcz na trasie
    if (isFinishZone) {
      _drawQuad(
        canvas,
        pABase,
        pBBase,
        pBTop,
        pATop,
        ((a.distanceMeters ~/ 4) % 2 == 0)
            ? const Color(0xCC8E4A49)
            : const Color(0xCC181B22),
      );
      _strokePaint
        ..color = AppColors.goldAccent.withValues(alpha: 0.75)
        ..strokeWidth = (1.2 * pABase.perspectiveScale).clamp(0.7, 2.5);
      canvas.drawLine(
        Offset(pATop.screenX, pATop.screenY),
        Offset(pBTop.screenX, pBTop.screenY),
        _strokePaint,
      );
    } else {
      // Słupki i podwójna stalowa szyna barierki ochronnej
      _strokePaint
        ..color = const Color(0xFF6B7280)
        ..strokeWidth = (2.0 * pABase.perspectiveScale).clamp(0.8, 4.0);
      canvas.drawLine(
        Offset(pABase.screenX, pABase.screenY),
        Offset(pATop.screenX, pATop.screenY),
        _strokePaint,
      );

      final pAMid =
          projection.worldToScreen(a.center + a.right * offsetA + a.normal * (railHeight * 0.62));
      final pBMid =
          projection.worldToScreen(b.center + b.right * offsetB + b.normal * (railHeight * 0.62));
      if (pAMid.isInFrontOfCamera && pBMid.isInFrontOfCamera) {
        _strokePaint
          ..color = const Color(0xFFD1D5DB)
          ..strokeWidth = (2.4 * pAMid.perspectiveScale).clamp(0.8, 5.0);
        canvas.drawLine(
          Offset(pAMid.screenX, pAMid.screenY),
          Offset(pBMid.screenX, pBMid.screenY),
          _strokePaint,
        );
      }
    }
  }

  // ===========================================================================
  // 3. DRZEWA, SKAŁY I BRAMY KILOMETROWE 3D
  // ===========================================================================

  int _drawSceneryProps(Canvas canvas) {
    _propQueue.clear();
    final Vector3 camPos = cameraRig.position;

    for (final prop in _sceneryProps) {
      final double distDiff = (prop.distanceMeters - _lastFocusDistanceMeters).abs();
      if (distDiff > config.maxRenderDistanceMeters) continue;

      final double camDist = (prop.position - camPos).length;
      if (camDist > config.maxRenderDistanceMeters) continue;
      if (!projection.isSphereInFrustum(prop.position, 6.0 * prop.scale)) continue;

      _propQueue.add(_PropQueueItem(prop: prop, cameraDepth: camDist));
    }

    _propQueue.sort((a, b) => b.cameraDepth.compareTo(a.cameraDepth));

    for (final item in _propQueue) {
      final p = item.prop;
      switch (p.type) {
        case Peloton3dPropType.pineTree:
          _drawPineTree3D(canvas, p);
          break;
        case Peloton3dPropType.deciduousTree:
          _drawDeciduousTree3D(canvas, p);
          break;
        case Peloton3dPropType.cypressTree:
          _drawCypressTree3D(canvas, p);
          break;
        case Peloton3dPropType.rockBoulder:
        case Peloton3dPropType.alpineCrag:
          _drawRock3D(canvas, p);
          break;
        case Peloton3dPropType.kilometerGate:
        case Peloton3dPropType.flammeRougeGate:
        case Peloton3dPropType.finishGantry:
          _drawGate3D(canvas, p);
          break;
      }
    }

    return _propQueue.length;
  }

  void _drawPineTree3D(Canvas canvas, Peloton3dSceneryProp prop) {
    final double s = prop.scale;
    final pBase = projection.worldToScreen(prop.position);
    final pTrunkTop = projection.worldToScreen(prop.position + prop.normal * (1.8 * s));
    final pTop = projection.worldToScreen(prop.position + prop.normal * (8.2 * s));
    if (!pBase.isInFrontOfCamera || !pTop.isInFrontOfCamera) return;

    // Cień pod drzewem
    final double shadowR = (1.8 * s * pBase.perspectiveScale * 5.0).clamp(2.0, 26.0);
    _fillPaint.color = const Color(0x44000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pBase.screenX, pBase.screenY),
        width: shadowR * 1.5,
        height: shadowR * 0.65,
      ),
      _fillPaint,
    );

    // Pień
    _strokePaint
      ..color = const Color(0xFF4A2E1B)
      ..strokeWidth = (1.6 * s * pBase.perspectiveScale * 2.2).clamp(1.2, 8.0);
    canvas.drawLine(
      Offset(pBase.screenX, pBase.screenY),
      Offset(pTrunkTop.screenX, pTrunkTop.screenY),
      _strokePaint,
    );

    // 3 piętra korony z cieniowaniem kierunkowym lewa/prawa
    for (int tier = 0; tier < 3; tier++) {
      final double tierBaseH = (1.6 + tier * 1.9) * s;
      final double tierTopH = tierBaseH + 2.8 * s;
      final double tierW = (2.3 - tier * 0.48) * s;

      final pLeft = projection.worldToScreen(
        prop.position + prop.normal * tierBaseH - prop.right * tierW,
      );
      final pRight = projection.worldToScreen(
        prop.position + prop.normal * tierBaseH + prop.right * tierW,
      );
      final pMid = projection.worldToScreen(prop.position + prop.normal * tierBaseH);
      final pApex = projection.worldToScreen(prop.position + prop.normal * tierTopH);
      if (!pLeft.isInFrontOfCamera || !pRight.isInFrontOfCamera || !pApex.isInFrontOfCamera) {
        continue;
      }

      // Oświetlona połowa
      _drawTriangle(
        canvas,
        pLeft,
        pMid,
        pApex,
        Color.lerp(const Color(0xFF1E5631), const Color(0xFF2D7A47), tier * 0.25)!,
      );
      // Zacieniona połowa
      _drawTriangle(
        canvas,
        pMid,
        pRight,
        pApex,
        const Color(0xFF0F361C),
      );
    }
  }

  void _drawDeciduousTree3D(Canvas canvas, Peloton3dSceneryProp prop) {
    final double s = prop.scale;
    final pBase = projection.worldToScreen(prop.position);
    final pCrown = projection.worldToScreen(prop.position + prop.normal * (4.6 * s));
    if (!pBase.isInFrontOfCamera || !pCrown.isInFrontOfCamera) return;

    _strokePaint
      ..color = const Color(0xFF523522)
      ..strokeWidth = (1.8 * s * pBase.perspectiveScale * 2.5).clamp(1.2, 10.0);
    canvas.drawLine(
      Offset(pBase.screenX, pBase.screenY),
      Offset(pCrown.screenX, pCrown.screenY),
      _strokePaint,
    );

    final double radius = (2.3 * s * pCrown.perspectiveScale * 9.0).clamp(3.0, 54.0);
    final Offset center = Offset(pCrown.screenX, pCrown.screenY);
    _fillPaint.shader = ui.Gradient.radial(
      Offset(center.dx - radius * 0.28, center.dy - radius * 0.28),
      radius * 1.15,
      const <Color>[
        Color(0xFF4ADE80),
        Color(0xFF15803D),
        Color(0xFF0B3D1E),
      ],
      const <double>[0.0, 0.55, 1.0],
    );
    canvas.drawCircle(center, radius, _fillPaint);
    _fillPaint.shader = null;
  }

  void _drawCypressTree3D(Canvas canvas, Peloton3dSceneryProp prop) {
    final double s = prop.scale;
    final pBase = projection.worldToScreen(prop.position);
    final pApex = projection.worldToScreen(prop.position + prop.normal * (9.0 * s));
    final pMidL = projection.worldToScreen(
      prop.position + prop.normal * (2.6 * s) - prop.right * (0.95 * s),
    );
    final pMidR = projection.worldToScreen(
      prop.position + prop.normal * (2.6 * s) + prop.right * (0.95 * s),
    );
    if (!pBase.isInFrontOfCamera ||
        !pApex.isInFrontOfCamera ||
        !pMidL.isInFrontOfCamera ||
        !pMidR.isInFrontOfCamera) {
      return;
    }

    _drawTriangle(canvas, pMidL, pBase, pApex, const Color(0xFF1F4E32));
    _drawTriangle(canvas, pBase, pMidR, pApex, const Color(0xFF112E1D));
  }

  void _drawRock3D(Canvas canvas, Peloton3dSceneryProp prop) {
    final double s = prop.scale * (prop.type == Peloton3dPropType.alpineCrag ? 2.1 : 1.0);
    final pL = projection.worldToScreen(prop.position - prop.right * (1.5 * s));
    final pR = projection.worldToScreen(prop.position + prop.right * (1.6 * s));
    final pC = projection.worldToScreen(prop.position + prop.tangent * (0.6 * s));
    final pPeak = projection.worldToScreen(
      prop.position + prop.normal * (2.2 * s) - prop.right * (0.25 * s),
    );
    if (!pL.isInFrontOfCamera ||
        !pR.isInFrontOfCamera ||
        !pC.isInFrontOfCamera ||
        !pPeak.isInFrontOfCamera) {
      return;
    }

    _drawTriangle(canvas, pL, pC, pPeak, const Color(0xFF7D8590));
    _drawTriangle(canvas, pC, pR, pPeak, const Color(0xFF4B525C));
  }

  void _drawGate3D(Canvas canvas, Peloton3dSceneryProp prop) {
    const double halfSpan = 4.2;
    const double height = 4.6;
    final Vector3 leftBase = prop.position - prop.right * halfSpan;
    final Vector3 rightBase = prop.position + prop.right * halfSpan;
    final Vector3 leftTop = leftBase + prop.normal * height;
    final Vector3 rightTop = rightBase + prop.normal * height;
    final Vector3 leftBannerBot = leftBase + prop.normal * (height - 1.05);
    final Vector3 rightBannerBot = rightBase + prop.normal * (height - 1.05);

    final pLB = projection.worldToScreen(leftBase);
    final pRB = projection.worldToScreen(rightBase);
    final pLT = projection.worldToScreen(leftTop);
    final pRT = projection.worldToScreen(rightTop);
    final pLBB = projection.worldToScreen(leftBannerBot);
    final pRBB = projection.worldToScreen(rightBannerBot);

    if (!pLB.isInFrontOfCamera ||
        !pRB.isInFrontOfCamera ||
        !pLT.isInFrontOfCamera ||
        !pRT.isInFrontOfCamera ||
        !pLBB.isInFrontOfCamera ||
        !pRBB.isInFrontOfCamera) {
      return;
    }

    final bool isFlamme = prop.type == Peloton3dPropType.flammeRougeGate;
    final bool isFinish = prop.type == Peloton3dPropType.finishGantry;

    final Color pillarColor = isFlamme
        ? const Color(0xFFDC2626)
        : (isFinish ? AppColors.goldAccent : const Color(0xFF334155));
    final Color bannerColor = isFlamme
        ? const Color(0xFFEF4444)
        : (isFinish ? const Color(0xFF181B22) : AppColors.primaryAccent);

    final double pillarWidth = (3.5 * pLB.perspectiveScale).clamp(2.0, 14.0);
    _strokePaint
      ..color = pillarColor
      ..strokeWidth = pillarWidth;
    canvas.drawLine(Offset(pLB.screenX, pLB.screenY), Offset(pLT.screenX, pLT.screenY), _strokePaint);
    canvas.drawLine(Offset(pRB.screenX, pRB.screenY), Offset(pRT.screenX, pRT.screenY), _strokePaint);

    // Poprzeczny baner bramy
    _drawQuad(canvas, pLBB, pRBB, pRT, pLT, bannerColor);

    if (isFinish) {
      // Złota ramka bramy mety
      _strokePaint
        ..color = AppColors.goldAccent
        ..strokeWidth = (1.8 * pLT.perspectiveScale).clamp(1.0, 3.5);
      canvas.drawLine(Offset(pLT.screenX, pLT.screenY), Offset(pRT.screenX, pRT.screenY), _strokePaint);
      canvas.drawLine(
        Offset(pLBB.screenX, pLBB.screenY),
        Offset(pRBB.screenX, pRBB.screenY),
        _strokePaint,
      );
    }

    // Etykieta na banerze dla bliskich bram
    if (prop.label != null && pLT.depthEye < 140.0) {
      final double midX = (pLT.screenX + pRT.screenX + pLBB.screenX + pRBB.screenX) * 0.25;
      final double midY = (pLT.screenY + pRT.screenY + pLBB.screenY + pRBB.screenY) * 0.25;
      final double fontSize = (11.0 * pLT.perspectiveScale).clamp(7.0, 18.0);
      final tp = TextPainter(
        text: TextSpan(
          text: prop.label!,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: isFinish ? AppColors.goldAccent : AppColors.textPrimary,
            letterSpacing: 0.6,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(midX - tp.width * 0.5, midY - tp.height * 0.5));
    }
  }

  // ===========================================================================
  // 4. PEŁNE BRYŁY 3D KOLARZY I ROWERÓW Z CIENIOWANIEM KIERUNKOWYM
  // ===========================================================================

  _RiderRenderCounts _drawPelotonRiders(Canvas canvas) {
    _riderQueue.clear();
    _projectedHits.clear();
    final Vector3 camPos = cameraRig.position;
    int culled = 0;

    for (final rider in _activeRiders) {
      if (rider.isDnf) {
        culled++;
        continue;
      }

      final node = sampleRoadAtDistance(rider.distanceMeters);
      final Vector3 worldPos = node.center + node.right * rider.lateralOffsetMeters;
      final double camDist = (worldPos - camPos).length;

      if (camDist > config.maxRenderDistanceMeters || camDist < 0.6) {
        culled++;
        continue;
      }
      if (!projection.isSphereInFrustum(worldPos + node.normal * 0.9, 1.4)) {
        culled++;
        continue;
      }

      final Peloton3dLod lod;
      if (camDist <= config.lod0DistanceMeters) {
        lod = Peloton3dLod.full;
      } else if (camDist <= config.lod1DistanceMeters) {
        lod = Peloton3dLod.medium;
      } else {
        lod = Peloton3dLod.distant;
      }

      _riderQueue.add(
        _RiderQueueItem(
          rider: rider,
          roadSample: node,
          worldPos: worldPos,
          cameraDepth: camDist,
          lod: lod,
        ),
      );
    }

    // Painter's Algorithm: najdalsi kolarze rysowani najpierw
    _riderQueue.sort((a, b) => b.cameraDepth.compareTo(a.cameraDepth));

    int lod0 = 0;
    int lod1 = 0;
    int lod2 = 0;

    for (final item in _riderQueue) {
      final pHit = projection.worldToScreen(item.worldPos + item.roadSample.normal * 0.72);
      if (pHit.isInFrontOfCamera) {
        _projectedHits.add(
          Peloton3dProjectedRiderHit(
            riderId: item.rider.riderId,
            screenCenter: Offset(pHit.screenX, pHit.screenY),
            hitRadius: (58.0 * pHit.perspectiveScale).clamp(28.0, 120.0),
            cameraDepth: item.cameraDepth,
          ),
        );
      }

      switch (item.lod) {
        case Peloton3dLod.full:
          lod0++;
          _drawFullDetailCyclist3D(canvas, item);
          break;
        case Peloton3dLod.medium:
          lod1++;
          _drawMediumDetailCyclist3D(canvas, item);
          break;
        case Peloton3dLod.distant:
          lod2++;
          _drawDistantCyclist3D(canvas, item);
          break;
      }
    }

    return _RiderRenderCounts(
      rendered: _riderQueue.length,
      culled: culled,
      lod0: lod0,
      lod1: lod1,
      lod2: lod2,
    );
  }

  /// Rysuje pełną bryłę 3D kolarza i roweru (LOD 0) z cieniowaniem kierunkowym.
  void _drawFullDetailCyclist3D(Canvas canvas, _RiderQueueItem item) {
    final r = item.rider;
    final node = item.roadSample;
    final Vector3 base = item.worldPos;
    final Vector3 fwd = node.tangent;

    // Pochylenie boczne roweru w zakręcie / podczas wyprzedzania Boids
    final double roll = r.leanAngleRad.clamp(-0.38, 0.38);
    final double cosR = math.cos(roll);
    final double sinR = math.sin(roll);
    final Vector3 bikeRight = (node.right * cosR - node.normal * sinR).normalized();
    final Vector3 bikeUp = (node.normal * cosR + node.right * sinR).normalized();

    // Wyróżnienie kolarza gracza subtelnym pierścieniem na asfalcie
    final pContact = projection.worldToScreen(base);
    if (!pContact.isInFrontOfCamera) return;

    // 1. Cień kontaktowy pod rowerem
    final double shadowW = (24.0 * pContact.perspectiveScale).clamp(6.0, 90.0);
    final double shadowH = (9.0 * pContact.perspectiveScale).clamp(2.5, 34.0);
    _fillPaint.color = const Color(0x66000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pContact.screenX + 2.0, pContact.screenY + 1.0),
        width: shadowW,
        height: shadowH,
      ),
      _fillPaint,
    );

    final bool isSelectedRider = r.riderId == selectedRiderId ||
        (selectedRiderId == null && r.isPlayerRider);
    if (config.enableSelectedHighlight && (isSelectedRider || r.isPlayerRider)) {
      if (isSelectedRider) {
        // Złoty pierścień taktyczny (#D4AF37) pod rowerem wybranego kolarza
        _strokePaint
          ..color = AppColors.goldAccent.withValues(alpha: 0.34)
          ..strokeWidth = (4.4 * pContact.perspectiveScale).clamp(2.2, 7.5);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(pContact.screenX, pContact.screenY),
            width: shadowW * 1.48,
            height: shadowH * 1.58,
          ),
          _strokePaint,
        );
      }
      _strokePaint
        ..color = AppColors.goldAccent.withValues(alpha: isSelectedRider ? 0.96 : 0.62)
        ..strokeWidth = ((isSelectedRider ? 2.2 : 1.4) * pContact.perspectiveScale).clamp(1.1, 3.8);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(pContact.screenX, pContact.screenY),
          width: shadowW * (isSelectedRider ? 1.32 : 1.22),
          height: shadowH * (isSelectedRider ? 1.42 : 1.32),
        ),
        _strokePaint,
      );
    }

    // Punkty geometrii roweru w układzie lokalnym 3D
    const double wheelR = 0.34;
    final Vector3 rearHub = base - fwd * 0.50 + bikeUp * wheelR;
    final Vector3 frontHub = base + fwd * 0.52 + bikeUp * wheelR;
    final Vector3 bbPos = base - fwd * 0.05 + bikeUp * 0.30; // Suport
    final Vector3 seatCluster = base - fwd * 0.22 + bikeUp * 0.78; // Węzeł podsiodłowy
    final Vector3 saddlePos = base - fwd * 0.26 + bikeUp * 0.94; // Siodełko
    final Vector3 headTubeTop = base + fwd * 0.36 + bikeUp * 0.86; // Główka ramy
    final Vector3 handlebarPos = base + fwd * 0.45 + bikeUp * 0.89; // Kierownica

    // 2. Koła 3D ze stożkami karbonowymi (35/50/65mm/Dysk) i obracającymi się szprychami
    _drawWheel3D(
      canvas: canvas,
      hubCenter: rearHub,
      forward: fwd,
      up: bikeUp,
      radius: wheelR,
      profile: r.wheelProfile,
      phaseRad: r.wheelPhaseRad,
    );
    _drawWheel3D(
      canvas: canvas,
      hubCenter: frontHub,
      forward: fwd,
      up: bikeUp,
      radius: wheelR,
      profile: r.wheelProfile == WheelProfileType.discRear
          ? WheelProfileType.depth65mm
          : r.wheelProfile,
      phaseRad: r.wheelPhaseRad + 0.35,
    );

    // 3. Trójkąty ramy w kolorze zespołu z cieniowaniem kierunkowym
    final double sunFactor = (0.72 + 0.28 * bikeUp.dot(config.sunDirection).clamp(0.0, 1.0));
    final Color frameLit = _shadeColor(r.frameColor, sunFactor);
    final Color frameDark = _shadeColor(r.frameColor, sunFactor * 0.65);

    _drawTube3D(canvas, rearHub, bbPos, frameDark, 2.2);
    _drawTube3D(canvas, rearHub, seatCluster, frameDark, 2.0);
    _drawTube3D(canvas, bbPos, seatCluster, frameLit, 2.8);
    _drawTube3D(canvas, seatCluster, headTubeTop, frameLit, 3.0);
    _drawTube3D(canvas, bbPos, headTubeTop, frameLit, 3.2);
    _drawTube3D(canvas, headTubeTop, frontHub, frameLit, 2.4);
    _drawTube3D(canvas, seatCluster, saddlePos, const Color(0xFF1F2937), 2.0);
    _drawTube3D(canvas, headTubeTop, handlebarPos, const Color(0xFF111827), 2.2);

    // 4. Dwusegmentowe animowane nogi (lewa i prawa) w rytm kadencji RPM
    final double standingLift = r.isStanding ? 0.11 : 0.0;
    final Vector3 hipCenter = saddlePos + bikeUp * (0.08 + standingLift) + fwd * (r.isStanding ? 0.14 : 0.02);

    // Dalsza noga (lewa) rysowana najpierw, potem bliższa (prawa)
    _drawTwoSegmentLeg3D(
      canvas: canvas,
      hipPos: hipCenter - bikeRight * 0.10,
      bbPos: bbPos - bikeRight * 0.08,
      forward: fwd,
      up: bikeUp,
      crankAngle: r.crankPhaseRad + math.pi,
      isFarLeg: true,
    );

    // 5. Pochylony tułów w koszulce drużynowej lub koszulce lidera
    final double torsoPitch = r.isSprinting ? 0.52 : (r.isStanding ? 0.44 : 0.36);
    final Vector3 shoulderCenter = hipCenter +
        fwd * (0.48 * math.cos(torsoPitch)) +
        bikeUp * (0.46 * math.sin(torsoPitch) + 0.18);

    _drawTorsoAndJersey3D(
      canvas: canvas,
      hipCenter: hipCenter,
      shoulderCenter: shoulderCenter,
      bikeRight: bikeRight,
      bikeUp: bikeUp,
      rider: r,
    );

    // Ręce na kierownicy
    _drawArm3D(
      canvas: canvas,
      shoulder: shoulderCenter - bikeRight * 0.16,
      hand: handlebarPos - bikeRight * 0.17,
      jerseyColor: _resolveEffectiveJerseyBaseColor(r),
    );
    _drawArm3D(
      canvas: canvas,
      shoulder: shoulderCenter + bikeRight * 0.16,
      hand: handlebarPos + bikeRight * 0.17,
      jerseyColor: _resolveEffectiveJerseyBaseColor(r),
    );

    // Bliższa noga (prawa) na pierwszym planie
    _drawTwoSegmentLeg3D(
      canvas: canvas,
      hipPos: hipCenter + bikeRight * 0.10,
      bbPos: bbPos + bikeRight * 0.08,
      forward: fwd,
      up: bikeUp,
      crankAngle: r.crankPhaseRad,
      isFarLeg: false,
    );

    // 6. Głowa w kasku aero i okularach z cieniowaniem kierunkowym
    final Vector3 headPos = shoulderCenter + fwd * 0.12 + bikeUp * 0.18;
    _drawHelmetAndSunglasses3D(
      canvas: canvas,
      headPos: headPos,
      forward: fwd,
      up: bikeUp,
      right: bikeRight,
      rider: r,
    );
  }

  /// Rysuje obracające się koło 3D ze stożkiem karbonowym (35/50/65mm/Dysk).
  void _drawWheel3D({
    required Canvas canvas,
    required Vector3 hubCenter,
    required Vector3 forward,
    required Vector3 up,
    required double radius,
    required WheelProfileType profile,
    required double phaseRad,
  }) {
    const int segments = 16;
    final List<Offset> outerPts = <Offset>[];
    final List<Offset> innerPts = <Offset>[];
    final double innerR = math.max(0.04, radius - profile.rimDepthMeters);

    for (int i = 0; i < segments; i++) {
      final double a = (i / segments) * 2.0 * math.pi;
      final double ca = math.cos(a);
      final double sa = math.sin(a);
      final Vector3 dir = forward * ca + up * sa;
      final pOut = projection.worldToScreen(hubCenter + dir * radius);
      final pIn = projection.worldToScreen(hubCenter + dir * innerR);
      if (!pOut.isInFrontOfCamera || !pIn.isInFrontOfCamera) return;
      outerPts.add(Offset(pOut.screenX, pOut.screenY));
      innerPts.add(Offset(pIn.screenX, pIn.screenY));
    }

    final pHub = projection.worldToScreen(hubCenter);
    if (!pHub.isInFrontOfCamera) return;

    if (profile.isDisc) {
      // Pełny dysk karbonowy z kierunkowym połyskiem
      _scratchPath
        ..reset()
        ..addPolygon(outerPts, true);
      _fillPaint.shader = ui.Gradient.linear(
        outerPts[0],
        outerPts[segments >> 1],
        const <Color>[
          Color(0xFF1F2937),
          Color(0xFF4B5563),
          Color(0xFF111827),
        ],
        const <double>[0.0, 0.45, 1.0],
      );
      canvas.drawPath(_scratchPath, _fillPaint);
      _fillPaint.shader = null;
    } else {
      // Obręcz karbonowa o głębokości 35/50/65mm
      _scratchPath
        ..reset()
        ..addPolygon(outerPts, true)
        ..addPolygon(innerPts.reversed.toList(), true);
      _scratchPath.fillType = PathFillType.evenOdd;
      _fillPaint.color = const Color(0xFF1E222B);
      canvas.drawPath(_scratchPath, _fillPaint);

      // Obracające się szprychy i błysk wentyla
      _strokePaint
        ..color = const Color(0x889CA3AF)
        ..strokeWidth = (0.9 * pHub.perspectiveScale).clamp(0.5, 1.6);
      for (int s = 0; s < profile.spokeCount; s++) {
        final double ang = phaseRad + (s / profile.spokeCount) * 2.0 * math.pi;
        final Vector3 tip = hubCenter + (forward * math.cos(ang) + up * math.sin(ang)) * innerR;
        final pTip = projection.worldToScreen(tip);
        if (pTip.isInFrontOfCamera) {
          canvas.drawLine(
            Offset(pHub.screenX, pHub.screenY),
            Offset(pTip.screenX, pTip.screenY),
            _strokePaint,
          );
        }
      }
    }

    // Opona zewnętrzna
    _scratchPath
      ..reset()
      ..addPolygon(outerPts, true);
    _strokePaint
      ..color = const Color(0xFF0B0E14)
      ..strokeWidth = (2.1 * pHub.perspectiveScale).clamp(1.0, 4.5);
    canvas.drawPath(_scratchPath, _strokePaint);

    // Piasta
    _fillPaint.color = const Color(0xFFD1D5DB);
    canvas.drawCircle(
      Offset(pHub.screenX, pHub.screenY),
      (1.8 * pHub.perspectiveScale).clamp(1.0, 3.5),
      _fillPaint,
    );
  }

  void _drawTube3D(
    Canvas canvas,
    Vector3 a,
    Vector3 b,
    Color color,
    double baseThickness,
  ) {
    final pA = projection.worldToScreen(a);
    final pB = projection.worldToScreen(b);
    if (!pA.isInFrontOfCamera || !pB.isInFrontOfCamera) return;
    _strokePaint
      ..color = color
      ..strokeWidth = (baseThickness * pA.perspectiveScale).clamp(1.0, 7.0);
    canvas.drawLine(Offset(pA.screenX, pA.screenY), Offset(pB.screenX, pB.screenY), _strokePaint);
  }

  /// Animowana dwusegmentowa noga: udo (spodenki) + łydka + biała skarpetka aero + but.
  void _drawTwoSegmentLeg3D({
    required Canvas canvas,
    required Vector3 hipPos,
    required Vector3 bbPos,
    required Vector3 forward,
    required Vector3 up,
    required double crankAngle,
    required bool isFarLeg,
  }) {
    const double crankRadius = 0.1725;
    final Vector3 footPos =
        bbPos + forward * (math.cos(crankAngle) * crankRadius) - up * (math.sin(crankAngle) * crankRadius);

    // Analityczne rozwiązanie 2-bone IK w płaszczyźnie (forward, up) dla kolana
    final Vector3 hipToFoot = footPos - hipPos;
    final double dist = hipToFoot.length.clamp(0.20, 0.80);
    const double thighLen = 0.42;
    const double calfLen = 0.41;

    final double cosAngle =
        ((thighLen * thighLen + dist * dist - calfLen * calfLen) / (2.0 * thighLen * dist))
            .clamp(-0.98, 0.98);
    final double bendAngle = math.acos(cosAngle);
    final Vector3 dir = hipToFoot.normalized();
    // Kolano zgina się do przodu (w kierunku forward)
    final Vector3 kneeBendDir = (forward - dir * forward.dot(dir)).normalized();
    final Vector3 kneePos = hipPos +
        dir * (thighLen * math.cos(bendAngle)) +
        kneeBendDir * (thighLen * math.sin(bendAngle));

    final pHip = projection.worldToScreen(hipPos);
    final pKnee = projection.worldToScreen(kneePos);
    final pFoot = projection.worldToScreen(footPos);
    if (!pHip.isInFrontOfCamera || !pKnee.isInFrontOfCamera || !pFoot.isInFrontOfCamera) return;

    final double scale = pKnee.perspectiveScale;
    final double dim = isFarLeg ? 0.72 : 1.0;

    // 1. Udo (ciemne spodenki kolarskie)
    _strokePaint
      ..color = _shadeColor(const Color(0xFF1A1D24), dim)
      ..strokeWidth = (6.8 * scale).clamp(2.2, 16.0);
    canvas.drawLine(Offset(pHip.screenX, pHip.screenY), Offset(pKnee.screenX, pKnee.screenY), _strokePaint);

    // 2. Górna część łydki (skóra z cieniowaniem)
    final Vector3 sockTopPos = kneePos + (footPos - kneePos) * 0.56;
    final pSockTop = projection.worldToScreen(sockTopPos);
    if (!pSockTop.isInFrontOfCamera) return;

    _strokePaint
      ..color = _shadeColor(const Color(0xFFD9A787), dim)
      ..strokeWidth = (5.0 * scale).clamp(1.8, 12.0);
    canvas.drawLine(
      Offset(pKnee.screenX, pKnee.screenY),
      Offset(pSockTop.screenX, pSockTop.screenY),
      _strokePaint,
    );

    // 3. Biała skarpetka aero
    _strokePaint
      ..color = _shadeColor(const Color(0xFFF8FAFC), dim)
      ..strokeWidth = (4.6 * scale).clamp(1.6, 11.0);
    canvas.drawLine(
      Offset(pSockTop.screenX, pSockTop.screenY),
      Offset(pFoot.screenX, pFoot.screenY),
      _strokePaint,
    );

    // 4. But kolarski (karbonowa podeszwa i czubek)
    final pShoeTip = projection.worldToScreen(footPos + forward * 0.13);
    if (pShoeTip.isInFrontOfCamera) {
      _strokePaint
        ..color = _shadeColor(const Color(0xFFF1F5F9), dim)
        ..strokeWidth = (4.2 * scale).clamp(1.5, 10.0);
      canvas.drawLine(
        Offset(pFoot.screenX, pFoot.screenY),
        Offset(pShoeTip.screenX, pShoeTip.screenY),
        _strokePaint,
      );
    }
  }

  Color _resolveEffectiveJerseyBaseColor(Peloton3dRiderRenderData r) {
    switch (r.leaderJersey) {
      case LeaderJerseyType.yellow:
        return const Color(0xFFFACC15);
      case LeaderJerseyType.green:
        return const Color(0xFF10B981);
      case LeaderJerseyType.polkaDot:
      case LeaderJerseyType.rainbow:
      case LeaderJerseyType.white:
        return const Color(0xFFF8FAFC);
      case LeaderJerseyType.none:
        return r.jerseyColor;
    }
  }

  /// Rysuje pochylony tułów z cieniowaniem kierunkowym oraz wzorem koszulki lidera.
  void _drawTorsoAndJersey3D({
    required Canvas canvas,
    required Vector3 hipCenter,
    required Vector3 shoulderCenter,
    required Vector3 bikeRight,
    required Vector3 bikeUp,
    required Peloton3dRiderRenderData rider,
  }) {
    final Vector3 hL = hipCenter - bikeRight * 0.14;
    final Vector3 hR = hipCenter + bikeRight * 0.14;
    final Vector3 sL = shoulderCenter - bikeRight * 0.19;
    final Vector3 sR = shoulderCenter + bikeRight * 0.19;

    final pHL = projection.worldToScreen(hL);
    final pHR = projection.worldToScreen(hR);
    final pSL = projection.worldToScreen(sL);
    final pSR = projection.worldToScreen(sR);
    if (!pHL.isInFrontOfCamera ||
        !pHR.isInFrontOfCamera ||
        !pSL.isInFrontOfCamera ||
        !pSR.isInFrontOfCamera) {
      return;
    }

    final double sunFactor = (0.74 + 0.26 * bikeUp.dot(config.sunDirection).clamp(0.0, 1.0));
    final Color baseJersey = _shadeColor(_resolveEffectiveJerseyBaseColor(rider), sunFactor);
    final Color darkJersey = _shadeColor(baseJersey, 0.72);

    // Gradient kierunkowy na korpusie
    _scratchPath
      ..reset()
      ..moveTo(pHL.screenX, pHL.screenY)
      ..lineTo(pHR.screenX, pHR.screenY)
      ..lineTo(pSR.screenX, pSR.screenY)
      ..lineTo(pSL.screenX, pSL.screenY)
      ..close();

    _fillPaint.shader = ui.Gradient.linear(
      Offset(pSL.screenX, pSL.screenY),
      Offset(pHR.screenX, pHR.screenY),
      <Color>[baseJersey, darkJersey],
    );
    canvas.drawPath(_scratchPath, _fillPaint);
    _fillPaint.shader = null;

    // Detale koszulek specjalnych (grochy KOM lub tęczowe pasy UCI)
    final double midX = (pHL.screenX + pHR.screenX + pSL.screenX + pSR.screenX) * 0.25;
    final double midY = (pHL.screenY + pHR.screenY + pSL.screenY + pSR.screenY) * 0.25;
    final double scale = pSL.perspectiveScale;

    if (rider.leaderJersey == LeaderJerseyType.polkaDot) {
      _fillPaint.color = const Color(0xFFEF4444);
      final double dotR = (2.2 * scale).clamp(1.0, 5.0);
      canvas.drawCircle(Offset(midX - 3.5 * scale, midY - 2.0 * scale), dotR, _fillPaint);
      canvas.drawCircle(Offset(midX + 3.2 * scale, midY + 1.5 * scale), dotR, _fillPaint);
      canvas.drawCircle(Offset(midX - 0.5 * scale, midY + 4.0 * scale), dotR, _fillPaint);
    } else if (rider.leaderJersey == LeaderJerseyType.rainbow) {
      const List<Color> uciColors = <Color>[
        Color(0xFF2563EB),
        Color(0xFFEF4444),
        Color(0xFF111827),
        Color(0xFFFACC15),
        Color(0xFF16A34A),
      ];
      final double bandW = (10.0 * scale).clamp(4.0, 24.0);
      final double bandH = (1.3 * scale).clamp(0.7, 3.0);
      for (int c = 0; c < uciColors.length; c++) {
        _fillPaint.color = uciColors[c];
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(midX, midY + (c - 2) * bandH),
            width: bandW,
            height: bandH,
          ),
          _fillPaint,
        );
      }
    }
  }

  void _drawArm3D({
    required Canvas canvas,
    required Vector3 shoulder,
    required Vector3 hand,
    required Color jerseyColor,
  }) {
    final Vector3 elbow = ((shoulder + hand) * 0.5) - Vector3(0.0, 0.08, 0.0);
    final pS = projection.worldToScreen(shoulder);
    final pE = projection.worldToScreen(elbow);
    final pH = projection.worldToScreen(hand);
    if (!pS.isInFrontOfCamera || !pE.isInFrontOfCamera || !pH.isInFrontOfCamera) return;

    final double scale = pS.perspectiveScale;
    _strokePaint
      ..color = jerseyColor
      ..strokeWidth = (4.2 * scale).clamp(1.5, 10.0);
    canvas.drawLine(Offset(pS.screenX, pS.screenY), Offset(pE.screenX, pE.screenY), _strokePaint);

    _strokePaint
      ..color = const Color(0xFFD9A787)
      ..strokeWidth = (3.4 * scale).clamp(1.2, 8.0);
    canvas.drawLine(Offset(pE.screenX, pE.screenY), Offset(pH.screenX, pH.screenY), _strokePaint);
  }

  /// Głowa w kasku aero i okularach z cieniowaniem kierunkowym.
  void _drawHelmetAndSunglasses3D({
    required Canvas canvas,
    required Vector3 headPos,
    required Vector3 forward,
    required Vector3 up,
    required Vector3 right,
    required Peloton3dRiderRenderData rider,
  }) {
    final pHead = projection.worldToScreen(headPos);
    final pHelmetTail = projection.worldToScreen(headPos - forward * 0.16 + up * 0.03);
    final pGlasses = projection.worldToScreen(headPos + forward * 0.11 - up * 0.02);
    if (!pHead.isInFrontOfCamera || !pHelmetTail.isInFrontOfCamera || !pGlasses.isInFrontOfCamera) {
      return;
    }

    final double r = (6.2 * pHead.perspectiveScale).clamp(2.2, 18.0);
    final Offset headCenter = Offset(pHead.screenX, pHead.screenY);

    // Twarz / skóra
    _fillPaint.color = const Color(0xFFD9A787);
    canvas.drawCircle(headCenter, r * 0.85, _fillPaint);

    // Kask aero (kolor zespołu lub biały/złoty dla lidera)
    final Color helmetBase = rider.leaderJersey == LeaderJerseyType.yellow
        ? const Color(0xFFFACC15)
        : (rider.leaderJersey == LeaderJerseyType.rainbow
            ? const Color(0xFFF8FAFC)
            : Color.lerp(_resolveEffectiveJerseyBaseColor(rider), Colors.white, 0.25)!);

    _fillPaint.shader = ui.Gradient.radial(
      Offset(headCenter.dx - r * 0.3, headCenter.dy - r * 0.45),
      r * 1.3,
      <Color>[
        Color.lerp(helmetBase, Colors.white, 0.35)!,
        helmetBase,
        _shadeColor(helmetBase, 0.55),
      ],
      const <double>[0.0, 0.55, 1.0],
    );

    _scratchPath
      ..reset()
      ..addOval(
        Rect.fromCenter(
          center: Offset(
            (headCenter.dx + pHelmetTail.screenX) * 0.5,
            headCenter.dy - r * 0.32,
          ),
          width: r * 2.2,
          height: r * 1.25,
        ),
      );
    canvas.drawPath(_scratchPath, _fillPaint);
    _fillPaint.shader = null;

    // Okulary kolarskie aero z lustrzanym odbiciem
    final pGLeft = projection.worldToScreen(headPos + forward * 0.11 - right * 0.06 - up * 0.02);
    final pGRight = projection.worldToScreen(headPos + forward * 0.11 + right * 0.06 - up * 0.02);
    if (pGLeft.isInFrontOfCamera && pGRight.isInFrontOfCamera) {
      _strokePaint
        ..color = const Color(0xFF0F172A)
        ..strokeWidth = (2.6 * pHead.perspectiveScale).clamp(1.0, 6.0);
      canvas.drawLine(
        Offset(pGLeft.screenX, pGLeft.screenY),
        Offset(pGRight.screenX, pGRight.screenY),
        _strokePaint,
      );
      _strokePaint
        ..color = AppColors.cyanAccent.withValues(alpha: 0.7)
        ..strokeWidth = (1.0 * pHead.perspectiveScale).clamp(0.5, 2.2);
      canvas.drawLine(
        Offset(pGLeft.screenX, pGLeft.screenY - 0.5),
        Offset(pGRight.screenX, pGRight.screenY - 0.5),
        _strokePaint,
      );
    }
  }

  /// Średni detal (LOD 1: 36-105m) — sylwetka roweru, koła, tułów i kask.
  void _drawMediumDetailCyclist3D(Canvas canvas, _RiderQueueItem item) {
    final r = item.rider;
    final node = item.roadSample;
    final Vector3 base = item.worldPos;
    final pRear = projection.worldToScreen(base - node.tangent * 0.45 + node.normal * 0.32);
    final pFront = projection.worldToScreen(base + node.tangent * 0.45 + node.normal * 0.32);
    final pTorso = projection.worldToScreen(base + node.normal * 1.05);
    final pHead = projection.worldToScreen(base + node.normal * 1.38 + node.tangent * 0.15);
    if (!pRear.isInFrontOfCamera ||
        !pFront.isInFrontOfCamera ||
        !pTorso.isInFrontOfCamera ||
        !pHead.isInFrontOfCamera) {
      return;
    }

    final double s = pTorso.perspectiveScale;
    final double wheelR = (6.0 * s).clamp(2.0, 14.0);

    if (r.riderId == selectedRiderId && config.enableSelectedHighlight) {
      final pBase = projection.worldToScreen(base);
      if (pBase.isInFrontOfCamera) {
        final double ringW = (24.0 * s).clamp(10.0, 56.0);
        final double ringH = (9.0 * s).clamp(4.0, 20.0);
        _strokePaint
          ..color = AppColors.goldAccent.withValues(alpha: 0.92)
          ..strokeWidth = (2.0 * s).clamp(1.2, 3.2);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(pBase.screenX, pBase.screenY),
            width: ringW,
            height: ringH,
          ),
          _strokePaint,
        );
      }
    }

    _strokePaint
      ..color = const Color(0xFF111827)
      ..strokeWidth = (1.8 * s).clamp(0.8, 3.5);
    canvas.drawCircle(Offset(pRear.screenX, pRear.screenY), wheelR, _strokePaint);
    canvas.drawCircle(Offset(pFront.screenX, pFront.screenY), wheelR, _strokePaint);

    _strokePaint
      ..color = r.frameColor
      ..strokeWidth = (2.0 * s).clamp(1.0, 4.0);
    canvas.drawLine(Offset(pRear.screenX, pRear.screenY), Offset(pFront.screenX, pFront.screenY), _strokePaint);

    _strokePaint
      ..color = _resolveEffectiveJerseyBaseColor(r)
      ..strokeWidth = (7.5 * s).clamp(2.5, 16.0);
    canvas.drawLine(
      Offset(pRear.screenX, pRear.screenY - wheelR * 0.6),
      Offset(pTorso.screenX, pTorso.screenY),
      _strokePaint,
    );

    _fillPaint.color = const Color(0xFFF3F4F6);
    canvas.drawCircle(Offset(pHead.screenX, pHead.screenY), (3.6 * s).clamp(1.4, 8.0), _fillPaint);
  }

  /// Daleki plan (LOD 2: >105m) — szybka bryła kapsułowa z cieniem.
  void _drawDistantCyclist3D(Canvas canvas, _RiderQueueItem item) {
    final pBase = projection.worldToScreen(item.worldPos);
    final pTop = projection.worldToScreen(item.worldPos + item.roadSample.normal * 1.35);
    if (!pBase.isInFrontOfCamera || !pTop.isInFrontOfCamera) return;

    final double s = pBase.perspectiveScale;
    _strokePaint
      ..color = _resolveEffectiveJerseyBaseColor(item.rider)
      ..strokeWidth = (5.0 * s).clamp(1.6, 8.0);
    canvas.drawLine(Offset(pBase.screenX, pBase.screenY), Offset(pTop.screenX, pTop.screenY), _strokePaint);
  }

  // ===========================================================================
  // NARZĘDZIA GEOMETRYCZNE I KOLORYSTYCZNE (ZERO-GC)
  // ===========================================================================

  void _drawQuad(
    Canvas canvas,
    ProjectedPoint3D p1,
    ProjectedPoint3D p2,
    ProjectedPoint3D p3,
    ProjectedPoint3D p4,
    Color color,
  ) {
    _scratchPath2
      ..reset()
      ..moveTo(p1.screenX, p1.screenY)
      ..lineTo(p2.screenX, p2.screenY)
      ..lineTo(p3.screenX, p3.screenY)
      ..lineTo(p4.screenX, p4.screenY)
      ..close();
    _fillPaint.color = color;
    canvas.drawPath(_scratchPath2, _fillPaint);
  }

  void _drawTriangle(
    Canvas canvas,
    ProjectedPoint3D p1,
    ProjectedPoint3D p2,
    ProjectedPoint3D p3,
    Color color,
  ) {
    _scratchPath2
      ..reset()
      ..moveTo(p1.screenX, p1.screenY)
      ..lineTo(p2.screenX, p2.screenY)
      ..lineTo(p3.screenX, p3.screenY)
      ..close();
    _fillPaint.color = color;
    canvas.drawPath(_scratchPath2, _fillPaint);
  }

  static bool _isCobblestoneSurface(SegmentSurfaceType surface) {
    return surface == SegmentSurfaceType.cobblestonesSector1 ||
        surface == SegmentSurfaceType.cobblestonesSector2 ||
        surface == SegmentSurfaceType.cobblestonesSector3 ||
        surface == SegmentSurfaceType.cobblestonesSector4 ||
        surface == SegmentSurfaceType.cobblestonesSector5;
  }

  static Color _shadeColor(Color base, double factor) {
    final double f = factor.clamp(0.15, 1.25);
    final int r = ((base.r * 255.0) * f).round().clamp(0, 255);
    final int g = ((base.g * 255.0) * f).round().clamp(0, 255);
    final int b = ((base.b * 255.0) * f).round().clamp(0, 255);
    final int a = (base.a * 255.0).round().clamp(0, 255);
    return Color.fromARGB(a, r, g, b);
  }
}

class _RiderRenderCounts {
  final int rendered;
  final int culled;
  final int lod0;
  final int lod1;
  final int lod2;

  const _RiderRenderCounts({
    required this.rendered,
    required this.culled,
    required this.lod0,
    required this.lod1,
    required this.lod2,
  });
}

/// CustomPainter delegujący rysowanie do [Peloton3dCanvasEngine].
class Peloton3dCanvasPainter extends CustomPainter {
  final Peloton3dCanvasEngine engine;
  final DynamicSkyboxAndLightingPainter? skyboxPainter;
  final int repaintToken;

  const Peloton3dCanvasPainter({
    required this.engine,
    this.skyboxPainter,
    this.repaintToken = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    engine.render(canvas, size, skyboxPainter: skyboxPainter);
  }

  @override
  bool shouldRepaint(covariant Peloton3dCanvasPainter oldDelegate) {
    return oldDelegate.engine != engine ||
        oldDelegate.skyboxPainter != skyboxPainter ||
        oldDelegate.repaintToken != repaintToken;
  }
}

/// Gotowy, responsywny widget widoku 3D z obsługą kamer (`ChaseCam`, `MotoTvCam`, `HeliCam`, `FinishLineCam`),
/// gestów obrotu/przybliżenia oraz pełnymi stanami `hover`/`active`/`disabled`/`focus`.
class Peloton3dViewportWidget extends StatefulWidget {
  final Peloton3dCanvasEngine engine;
  final List<RiderPositionSnapshot> snapshots;
  final String? focusRiderId;
  final StageSegment? activeSegment;
  final double windSpeedKmh;
  final bool showCameraControls;

  const Peloton3dViewportWidget({
    super.key,
    required this.engine,
    required this.snapshots,
    this.focusRiderId,
    this.activeSegment,
    this.windSpeedKmh = 0.0,
    this.showCameraControls = true,
  });

  @override
  State<Peloton3dViewportWidget> createState() => _Peloton3dViewportWidgetState();
}

class _Peloton3dViewportWidgetState extends State<Peloton3dViewportWidget>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  int _frameCounter = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final double dt = _lastElapsed == Duration.zero
        ? (1.0 / 60.0)
        : ((elapsed - _lastElapsed).inMicroseconds / 1000000.0).clamp(0.001, 0.05);
    _lastElapsed = elapsed;

    if (widget.snapshots.isNotEmpty) {
      widget.engine.stepFrame(
        dtSeconds: dt,
        snapshots: widget.snapshots,
        focusRiderId: widget.focusRiderId,
        activeSegment: widget.activeSegment,
        windSpeedKmh: widget.windSpeedKmh,
      );
    }
    if (mounted) {
      setState(() {
        _frameCounter++;
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 640.0;
        final activeMode = widget.engine.cameraRig.activeMode;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppColors.cardBorder, width: 1.0),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                GestureDetector(
                  onPanUpdate: (details) {
                    widget.engine.addCameraOrbit(
                      deltaYaw: details.delta.dx * 0.006,
                      deltaPitch: details.delta.dy * 0.005,
                    );
                  },
                  onDoubleTap: widget.engine.resetCameraOrbit,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: Peloton3dCanvasPainter(
                        engine: widget.engine,
                        repaintToken: _frameCounter,
                      ),
                    ),
                  ),
                ),
                if (widget.showCameraControls)
                  Positioned(
                    left: 12.0,
                    right: 12.0,
                    bottom: 12.0,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: RaceCameraMode.values.map((mode) {
                          final bool isSelected = mode == activeMode;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: _CameraModeButton(
                              label: isCompact ? mode.shortLabel : mode.label,
                              isSelected: isSelected,
                              onPressed: () {
                                setState(() {
                                  widget.engine.switchCameraMode(mode);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CameraModeButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onPressed;

  const _CameraModeButton({
    required this.label,
    required this.isSelected,
    this.onPressed,
  });

  @override
  State<_CameraModeButton> createState() => _CameraModeButtonState();
}

class _CameraModeButtonState extends State<_CameraModeButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null;
    final Color bgColor;
    if (!isEnabled) {
      bgColor = AppColors.surface.withValues(alpha: 0.45);
    } else if (widget.isSelected) {
      bgColor = AppColors.primaryAccent;
    } else if (_isPressed) {
      bgColor = AppColors.surfaceLight;
    } else if (_isHovered) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.92);
    } else {
      bgColor = AppColors.surface.withValues(alpha: 0.88);
    }

    final Color borderColor = _isFocused
        ? AppColors.goldAccent
        : (widget.isSelected ? AppColors.goldAccent : AppColors.cardBorder);

    return FocusableActionDetector(
      enabled: isEnabled,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      mouseCursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.0,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: -0.2,
              color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
