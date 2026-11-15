// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/events/race_incident_engine.dart';
import '../../engine/peloton/drafting_grid_system.dart';
import '../../engine/peloton/rider_race_state.dart';
import '../../engine/rendering3d/camera_rig_controller.dart';
import '../../engine/rendering3d/crash_and_mechanical_visuals.dart';
import '../../engine/rendering3d/dynamic_skybox_and_lighting_painter.dart';
import '../../engine/rendering3d/environment_scenery_spawner.dart';
import '../../engine/rendering3d/glb_asset_loader_service.dart';
import '../../engine/rendering3d/on_bike_computer_hud_widget.dart';
import '../../engine/rendering3d/peloton_instanced_renderer.dart';
import '../../engine/rendering3d/photo_finish_replay_widget.dart';
import '../../engine/rendering3d/rider_floating_labels_overlay.dart';
import '../../engine/rendering3d/road_furniture_3d_renderer.dart';
import '../../engine/rendering3d/road_ribbon_mesh_builder.dart';
import '../../engine/rendering3d/support_vehicles_3d_renderer.dart';
import '../../engine/rendering3d/scene_3d_math_projection.dart';
import '../../engine/rendering3d/weather_particles_renderer.dart';
import '../../engine/rendering3d/wind_streamlines_visualizer.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../state/race_simulation_notifier.dart';

// Stałe kolorystyczne wirtualnego silnika 3D Zwift / MyWhoosh
const Color _goldPlayerAccent = Color(0xFFFFD700);
const Color _emeraldPower = Color(0xFF10B981);

/// Dostępne tryby kamer wirtualnego silnika 3D w interfejsie użytkownika.
enum ViewportCameraMode {
  chasePlayerRider(
    label: 'Kamera zza Pleców',
    shortLabel: 'Za Plecami',
    icon: Icons.person_outline_rounded,
    description: 'Dynamiczne ujęcie zza pleców kolarza z widoczną pracą w korbach i strugą aero.',
  ),
  droneOverhead(
    label: 'Dron nad Peletonem',
    shortLabel: 'Dron Peletonu',
    icon: Icons.videocam_rounded,
    description: 'Wysoka perspektywa z góry ukazująca cały szyk grupy i wachlarze na wietrze.',
  ),
  motoTvLead(
    label: 'Motocykl TV z Przodu',
    shortLabel: 'Motocykl TV',
    icon: Icons.two_wheeler_rounded,
    description: 'Dynamiczne ujęcie telewizyjne z motocykla jadącego 8 m przed czołem grupy.',
  ),
  finishLineGantry(
    label: 'Kamera na Kreskę Mety',
    shortLabel: 'Kreska Mety',
    icon: Icons.flag_rounded,
    description: 'Statyczna kamera z bramy mety ze zbliżeniem teleobiektywowym na finisz etapu.',
  );

  final String label;
  final String shortLabel;
  final IconData icon;
  final String description;

  const ViewportCameraMode({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.description,
  });

  /// Mapowanie na tryb silnika [RaceCameraMode] w kontrolerze kamer 3D.
  RaceCameraMode toRigMode() {
    switch (this) {
      case ViewportCameraMode.chasePlayerRider:
        return RaceCameraMode.chaseCam;
      case ViewportCameraMode.droneOverhead:
        return RaceCameraMode.heliCam;
      case ViewportCameraMode.motoTvLead:
        return RaceCameraMode.motoTvCam;
      case ViewportCameraMode.finishLineGantry:
        return RaceCameraMode.finishLineCam;
    }
  }
}

/// Wewnętrzny stan interpolacji pojedynczego kolarza w przestrzeni 3D (60/120 FPS).
class _InterpolatedRiderState {
  final String riderId;
  final String riderName;
  final int bibNumber;
  final String teamJerseyHex;
  final bool isPlayerRider;

  // Pozycje i dynamika w świecie 3D
  double currentDistanceMeters;
  double targetDistanceMeters;

  double currentLateralOffsetMeters;
  double targetLateralOffsetMeters;

  double currentSpeedKmh;
  double targetSpeedKmh;

  int currentWatts;
  int targetWatts;

  double currentWattsPerKg;
  double targetWattsPerKg;

  int currentCadenceRpm;
  int targetCadenceRpm;

  // Kąt obrotu korby i pedałowania [rad]
  double crankAngleRadians = 0.0;

  // Aerodynamika i drafting
  bool isDrafting;
  double draftingSavingsPercent;
  bool isPulling;

  // Status incydentów losowych i defektów
  bool hasDefect;
  IncidentType? defectType;
  bool isCrashed;
  bool isDnf;

  _InterpolatedRiderState({
    required this.riderId,
    required this.riderName,
    required this.bibNumber,
    required this.teamJerseyHex,
    required this.isPlayerRider,
    required this.currentDistanceMeters,
    required this.targetDistanceMeters,
    required this.currentLateralOffsetMeters,
    required this.targetLateralOffsetMeters,
    required this.currentSpeedKmh,
    required this.targetSpeedKmh,
    required this.currentWatts,
    required this.targetWatts,
    required this.currentWattsPerKg,
    required this.targetWattsPerKg,
    required this.currentCadenceRpm,
    required this.targetCadenceRpm,
    this.isDrafting = false,
    this.draftingSavingsPercent = 0.0,
    this.isPulling = false,
    this.hasDefect = false,
    this.defectType,
    this.isCrashed = false,
    this.isDnf = false,
  });

  void updateTarget({
    required double newDistanceMeters,
    required double newLateralOffsetMeters,
    required double newSpeedKmh,
    required int newWatts,
    required double newWattsPerKg,
    required int newCadenceRpm,
    required bool newIsDrafting,
    required double newDraftingSavingsPercent,
    required bool newIsPulling,
    bool? newHasDefect,
    IncidentType? newDefectType,
    bool? newIsCrashed,
    bool? newIsDnf,
  }) {
    targetDistanceMeters = newDistanceMeters;
    targetLateralOffsetMeters = newLateralOffsetMeters;
    targetSpeedKmh = newSpeedKmh;
    targetWatts = newWatts;
    targetWattsPerKg = newWattsPerKg;
    targetCadenceRpm = newCadenceRpm;
    isDrafting = newIsDrafting;
    draftingSavingsPercent = newDraftingSavingsPercent;
    isPulling = newIsPulling;
    if (newHasDefect != null) hasDefect = newHasDefect;
    if (newDefectType != null) defectType = newDefectType;
    if (newIsCrashed != null) isCrashed = newIsCrashed;
    if (newIsDnf != null) isDnf = newIsDnf;
  }

  void stepSimulation(double dtSeconds) {
    // 1. Płynna interpolacja dystansu wzdłuż szosy
    final double distLerpFactor = (dtSeconds * 4.5).clamp(0.0, 1.0);
    currentDistanceMeters += (targetDistanceMeters - currentDistanceMeters) * distLerpFactor;

    // 2. Płynna interpolacja pozycji poprzecznej na szosie
    final double latLerpFactor = (dtSeconds * 6.0).clamp(0.0, 1.0);
    currentLateralOffsetMeters += (targetLateralOffsetMeters - currentLateralOffsetMeters) * latLerpFactor;

    // 3. Wygładzanie parametrów mocy i prędkości
    final double metricLerpFactor = (dtSeconds * 5.0).clamp(0.0, 1.0);
    currentSpeedKmh += (targetSpeedKmh - currentSpeedKmh) * metricLerpFactor;
    currentWatts += ((targetWatts - currentWatts) * metricLerpFactor).round();
    currentWattsPerKg += (targetWattsPerKg - currentWattsPerKg) * metricLerpFactor;
    currentCadenceRpm += ((targetCadenceRpm - currentCadenceRpm) * metricLerpFactor).round();

    // 4. Fizyka obrotu korby: θ = (cadence * 2π / 60) * dt
    final double cadence = (currentCadenceRpm > 10) ? currentCadenceRpm.toDouble() : 85.0;
    final double angularVelocity = (cadence * 2.0 * math.pi) / 60.0;
    crankAngleRadians = (crankAngleRadians + angularVelocity * dtSeconds) % (2.0 * math.pi);
  }

  /// Konwertuje stan interpolowany kolarza na [RiderPositionSnapshot] dla renderera instancyjnego.
  RiderPositionSnapshot toSnapshot({
    double elevationMeters = 0.0,
    double gradientPercent = 0.0,
    int segmentIndex = 0,
  }) {
    return RiderPositionSnapshot(
      riderId: riderId,
      riderName: riderName,
      bibNumber: bibNumber,
      teamId: 'team_$bibNumber',
      teamName: 'PPM Team',
      teamJerseyHexColor: teamJerseyHex,
      isPlayerRider: isPlayerRider,
      distanceCoveredMeters: currentDistanceMeters,
      kilometerMark: currentDistanceMeters / 1000.0,
      elevationMeters: elevationMeters,
      currentGradientPercent: gradientPercent,
      currentSegmentIndex: segmentIndex,
      speedMs: currentSpeedKmh / 3.6,
      speedKmh: currentSpeedKmh,
      powerWatts: currentWatts,
      wattsPerKg: currentWattsPerKg,
      cadenceRpm: currentCadenceRpm,
      heartRateBpm: 155,
      wPrimePercentage: 0.85,
      wPrimeJoules: 18000.0,
      glycogenPercentage: 0.75,
      glycogenGrams: 350.0,
      hydrationPercent: 0.90,
      bidonsLeft: 2,
      gelsLeft: 3,
      activeTacticalOrder: TacticalOrder.holdPosition,
      groupIndex: 0,
      groupType: GroupType.peloton,
      timeGapToLeaderSeconds: 0.0,
      lateralPositionRoad: (currentLateralOffsetMeters / 3.6).clamp(-1.0, 1.0),
      lateralOffsetRoadMeters: currentLateralOffsetMeters,
      isDrafting: isDrafting,
      draftingSavingsPercent: draftingSavingsPercent,
      isPulling: isPulling,
      hasDefect: hasDefect,
      defectType: defectType,
      isCrashed: isCrashed,
      isDnf: isDnf,
    );
  }
}

/// Zaawansowany widget renderujący pełną symulację 3D wyścigu kolarskiego w stylu Zwift/MyWhoosh.
///
/// Zintegrowany z kompletnym silnikiem 3D Pro Peloton Manager:
/// - Kontroler kamer wyścigowych [CameraRigController] (ChaseCam, HeliCam, MotoTvCam, FinishLineCam)
///   ze sprężysto-tłumioną interpolacją SmoothDamp i płynnymi przejściami Blend Transition,
/// - Silnik rzutowania perspektywicznego [Scene3DMathProjection],
/// - Realistyczny generator geometrii wstęgi szosy 3D [RoadRibbonMeshBuilder] z krzywymi Catmull-Rom,
///   przechyłem jezdni w wirażach, PBR dla asfaltu/bruku/szutru i malowanymi napisami kibiców na asfalcie,
/// - Spawner proceduralnego otoczenia trasy [EnvironmentScenerySpawner] zależny od wysokości n.p.m. i regionu,
/// - Renderer peletonu [PelotonInstancedRenderer] obsługujący 176 kolarzy w 120 FPS z 3-poziomowym LOD,
///   sortowaniem głębokości Painter's Algorithm, strugami aerodynamicznymi i etykietami watów,
/// - Asynchroniczny menedżer modeli GLB [GlbAssetLoaderService] z zerokraszowym fallbackiem proceduralnym.
class Race3DViewportWidget extends ConsumerStatefulWidget {
  final RaceStage? stage;
  final List<RiderPositionSnapshot>? riderSnapshots;
  final Map<String, RiderRaceState>? riderStates;
  final List<String> playerRiderIds;
  final String? selectedRiderId;
  final ViewportCameraMode initialCameraMode;
  final ValueChanged<String>? onRiderSelected;
  final ValueChanged<ViewportCameraMode>? onCameraModeChanged;
  final bool showCameraControls;
  final bool showBroadcastHud;
  final bool showOnBikeComputer;
  final BikeComputerModel bikeComputerModel;
  final bool showDraftingStreams;
  final bool showRiderLabels;
  final bool showIncidentVisuals;
  final bool initialAeroVision;

  const Race3DViewportWidget({
    super.key,
    this.stage,
    this.riderSnapshots,
    this.riderStates,
    this.playerRiderIds = const [],
    this.selectedRiderId,
    this.initialCameraMode = ViewportCameraMode.chasePlayerRider,
    this.onRiderSelected,
    this.onCameraModeChanged,
    this.showCameraControls = true,
    this.showBroadcastHud = true,
    this.showOnBikeComputer = true,
    this.bikeComputerModel = BikeComputerModel.garminEdge,
    this.showDraftingStreams = true,
    this.showRiderLabels = true,
    this.showIncidentVisuals = true,
    this.initialAeroVision = false,
  });

  @override
  ConsumerState<Race3DViewportWidget> createState() => _Race3DViewportWidgetState();
}

class _Race3DViewportWidgetState extends ConsumerState<Race3DViewportWidget>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastFrameTime = Duration.zero;

  late ViewportCameraMode _cameraMode;
  String? _currentSelectedRiderId;

  // Moduły wirtualnego silnika 3D
  late final CameraRigController _cameraRigController;
  late final Scene3DMathProjection _projection;
  late final RoadRibbonMeshBuilder _roadRibbonBuilder;
  late final EnvironmentScenerySpawner _scenerySpawner;
  late final PelotonInstancedRenderer _pelotonRenderer;
  late final WeatherParticlesRenderer _weatherRenderer;
  late final RiderFloatingLabelsOverlay _riderLabelsOverlay;
  late final RoadFurniture3DRenderer _roadFurnitureRenderer;
  late final SupportVehicles3DRenderer _supportVehiclesRenderer;
  late final CrashAndMechanicalVisualsRenderer _crashVisualsRenderer;
  late final WindStreamlinesVisualizer _windVisualizer;
  late bool _isAeroVisionActive;

  // Rozmiar rzutni i telemetria pogodowa
  Size _viewportSize = const Size(1280.0, 720.0);
  WeatherSystemTelemetry? _lastWeatherTelemetry;

  // Aktywne bufory geometrii i instancji
  RoadRibbonMesh? _currentRoadMesh;
  double _lastRoadMeshUpdateDist = -9999.0;

  List<SceneryInstance3D> _currentSceneryInstances = [];
  double _lastSceneryUpdateDist = -9999.0;

  List<RoadFurnitureInstance3D> _currentFurnitureInstances = [];
  List<SupportVehicleInstance3D> _currentSupportVehicles = [];

  List<PelotonRenderItem> _currentPelotonRenderItems = [];

  // Pula interpolowanych kolarzy
  final Map<String, _InterpolatedRiderState> _riderPool = {};

  // Czas trwania animacji
  double _elapsedAnimSeconds = 0.0;

  // Stan gestów interaktywnych (Orbit, Pinch-to-zoom, Tap picking)
  double _baseZoomScale = 1.0;
  String? _tacticalFeedbackMessage;
  Timer? _tacticalFeedbackTimer;

  @override
  void initState() {
    super.initState();
    _cameraMode = widget.initialCameraMode;
    _currentSelectedRiderId = widget.selectedRiderId;

    // 1. Kontroler kamer 3D
    _cameraRigController = CameraRigController(
      initialMode: _cameraMode.toRigMode(),
    );

    // 2. Silnik rzutowania matematycznego 3D
    _projection = Scene3DMathProjection();

    // 3. Moduły renderujące
    _roadRibbonBuilder = const RoadRibbonMeshBuilder();
    _scenerySpawner = EnvironmentScenerySpawner();
    _pelotonRenderer = PelotonInstancedRenderer();
    _weatherRenderer = WeatherParticlesRenderer();
    _riderLabelsOverlay = RiderFloatingLabelsOverlay();
    _roadFurnitureRenderer = RoadFurniture3DRenderer();
    _supportVehiclesRenderer = SupportVehicles3DRenderer();
    _crashVisualsRenderer = CrashAndMechanicalVisualsRenderer();
    _isAeroVisionActive = widget.initialAeroVision;
    _windVisualizer = WindStreamlinesVisualizer(
      config: WindStreamlinesConfig(aeroVisionActive: _isAeroVisionActive),
    );

    // 4. Wstępne rozgrzanie i załadowanie modeli GLB w tle
    GlbAssetLoaderService.instance.preloadEssentialAssets();

    // 5. Inicjalizacja bazy kolarzy przed pierwszą klatką
    _synchronizeRiderData();

    // 6. Wstępna konfiguracja geometrii kamery i listy kolarzy przed pierwszą klatką
    final initialStage = widget.stage ?? _generateDemoStage();
    final initialSegments = initialStage.segments.isNotEmpty ? initialStage.segments : _generateDemoSegments();
    _stepCameraRig(0.016, initialSegments, initialStage);
    final double initW = _viewportSize.width > 0 ? _viewportSize.width : 1280.0;
    final double initH = _viewportSize.height > 0 ? _viewportSize.height : 720.0;
    _projection.updateCamera(
      _cameraRigController.toCameraConfig(),
      viewportWidth: initW,
      viewportHeight: initH,
    );
    _preparePelotonRenderList(initialSegments, 0.016);

    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void didUpdateWidget(covariant Race3DViewportWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedRiderId != null && widget.selectedRiderId != _currentSelectedRiderId) {
      setState(() {
        _currentSelectedRiderId = widget.selectedRiderId;
      });
    }
    if (widget.initialAeroVision != oldWidget.initialAeroVision &&
        widget.initialAeroVision != _isAeroVisionActive) {
      setState(() {
        _isAeroVisionActive = widget.initialAeroVision;
        _windVisualizer.setAeroVisionActive(_isAeroVisionActive);
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tacticalFeedbackTimer?.cancel();
    super.dispose();
  }

  void _onTick(Duration currentDuration) {
    if (_lastFrameTime == Duration.zero) {
      _lastFrameTime = currentDuration;
      return;
    }

    final double dt = (currentDuration - _lastFrameTime).inMicroseconds / 1000000.0;
    _lastFrameTime = currentDuration;

    if (dt <= 0.0 || dt > 0.1) return; // Zabezpieczenie przed skokami klatek

    _elapsedAnimSeconds += dt;

    // 1. Synchronizacja i aktualizacja danych kolarzy
    _synchronizeRiderData();

    // 2. Krok fizyki interpolacji dla każdego kolarza
    for (final rider in _riderPool.values) {
      rider.stepSimulation(dt);
    }

    // 3. Pobranie aktywnego etapu i segmentów
    final activeStage = widget.stage ??
        ref.read(raceSimulationProvider).simulationState?.stage ??
        _generateDemoStage();
    final segments = activeStage.segments.isNotEmpty ? activeStage.segments : _generateDemoSegments();

    // 4. Krok kontrolera kamery 3D (Spring-Damper)
    _stepCameraRig(dt, segments, activeStage);

    // 4b. Aktualizacja geometrii rzutowania kamery 3D
    final double vpW = _viewportSize.width > 0 ? _viewportSize.width : 1280.0;
    final double vpH = _viewportSize.height > 0 ? _viewportSize.height : 720.0;
    _projection.updateCamera(
      _cameraRigController.toCameraConfig(),
      viewportWidth: vpW,
      viewportHeight: vpH,
    );

    // 5. Dynamiczne odświeżenie wstęgi drogi i otoczenia wokół kamery
    _updateRoadAndScenery(segments, activeStage);

    // 6. Przygotowanie listy renderowania peletonu (Painter's algorithm Back-to-Front + LOD)
    _preparePelotonRenderList(segments, dt);

    // 6b. Aktualizacja pojazdów towarzyszących (wozy techniczne, motocykle TV, serwis neutralny)
    _currentSupportVehicles = _supportVehiclesRenderer.updateAndBuildVehicles(
      activeRiders: _currentPelotonRenderItems,
      segments: segments,
      dtSeconds: dt,
      elapsedAnimSeconds: _elapsedAnimSeconds,
    );

    // 6c. Aktualizacja zdarzeń losowych (defekty sprzętowe, zjazd na pobocze, wymiana koła, kraksy)
    _crashVisualsRenderer.updateIncidents(
      activeRiders: _currentPelotonRenderItems,
      segments: segments,
      dtSeconds: dt,
    );

    // 7. Aktualizacja symulatora pogody i cząsteczek atmosferycznych (deszcz, mgła, woda z kół, pył)
    _updateWeatherSystem(dt, activeStage, segments);

    // 7b. Aktualizacja tunelu aerodynamicznego i strug wiatru ("Aero Vision Mode")
    _windVisualizer.updatePhysics(
      activeRiders: _currentPelotonRenderItems,
      activeStage: activeStage,
      segments: segments,
      dtSeconds: dt,
      elapsedAnimSeconds: _elapsedAnimSeconds,
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _synchronizeRiderData() {
    // Źródło 1: Bezpośrednie snapshots przekazane przez widget
    if (widget.riderSnapshots != null && widget.riderSnapshots!.isNotEmpty) {
      for (final s in widget.riderSnapshots!) {
        final existing = _riderPool[s.riderId];
        if (existing == null) {
          _riderPool[s.riderId] = _InterpolatedRiderState(
            riderId: s.riderId,
            riderName: s.riderName,
            bibNumber: s.bibNumber,
            teamJerseyHex: s.teamJerseyHexColor,
            isPlayerRider: s.isPlayerRider,
            currentDistanceMeters: s.distanceCoveredMeters,
            targetDistanceMeters: s.distanceCoveredMeters,
            currentLateralOffsetMeters: s.lateralOffsetRoadMeters,
            targetLateralOffsetMeters: s.lateralOffsetRoadMeters,
            currentSpeedKmh: s.speedKmh,
            targetSpeedKmh: s.speedKmh,
            currentWatts: s.powerWatts,
            targetWatts: s.powerWatts,
            currentWattsPerKg: s.wattsPerKg,
            targetWattsPerKg: s.wattsPerKg,
            currentCadenceRpm: s.cadenceRpm,
            targetCadenceRpm: s.cadenceRpm,
            isDrafting: s.isDrafting,
            draftingSavingsPercent: s.draftingSavingsPercent,
            isPulling: s.isPulling,
            hasDefect: s.hasDefect,
            defectType: s.defectType,
            isCrashed: s.isCrashed,
            isDnf: s.isDnf,
          );
        } else {
          existing.updateTarget(
            newDistanceMeters: s.distanceCoveredMeters,
            newLateralOffsetMeters: s.lateralOffsetRoadMeters,
            newSpeedKmh: s.speedKmh,
            newWatts: s.powerWatts,
            newWattsPerKg: s.wattsPerKg,
            newCadenceRpm: s.cadenceRpm,
            newIsDrafting: s.isDrafting,
            newDraftingSavingsPercent: s.draftingSavingsPercent,
            newIsPulling: s.isPulling,
            newHasDefect: s.hasDefect,
            newDefectType: s.defectType,
            newIsCrashed: s.isCrashed,
            newIsDnf: s.isDnf,
          );
        }
      }
      return;
    }

    // Źródło 2: Aktywny stan z Riverpod RaceSimulationNotifier
    final simState = ref.read(raceSimulationProvider);
    if (simState.riderPositions.isNotEmpty) {
      for (final s in simState.riderPositions) {
        final existing = _riderPool[s.riderId];
        if (existing == null) {
          _riderPool[s.riderId] = _InterpolatedRiderState(
            riderId: s.riderId,
            riderName: s.riderName,
            bibNumber: s.bibNumber,
            teamJerseyHex: s.teamJerseyHexColor,
            isPlayerRider: s.isPlayerRider,
            currentDistanceMeters: s.distanceCoveredMeters,
            targetDistanceMeters: s.distanceCoveredMeters,
            currentLateralOffsetMeters: s.lateralOffsetRoadMeters,
            targetLateralOffsetMeters: s.lateralOffsetRoadMeters,
            currentSpeedKmh: s.speedKmh,
            targetSpeedKmh: s.speedKmh,
            currentWatts: s.powerWatts,
            targetWatts: s.powerWatts,
            currentWattsPerKg: s.wattsPerKg,
            targetWattsPerKg: s.wattsPerKg,
            currentCadenceRpm: s.cadenceRpm,
            targetCadenceRpm: s.cadenceRpm,
            isDrafting: s.isDrafting,
            draftingSavingsPercent: s.draftingSavingsPercent,
            isPulling: s.isPulling,
            hasDefect: s.hasDefect,
            defectType: s.defectType,
            isCrashed: s.isCrashed,
            isDnf: s.isDnf,
          );
        } else {
          existing.updateTarget(
            newDistanceMeters: s.distanceCoveredMeters,
            newLateralOffsetMeters: s.lateralOffsetRoadMeters,
            newSpeedKmh: s.speedKmh,
            newWatts: s.powerWatts,
            newWattsPerKg: s.wattsPerKg,
            newCadenceRpm: s.cadenceRpm,
            newIsDrafting: s.isDrafting,
            newDraftingSavingsPercent: s.draftingSavingsPercent,
            newIsPulling: s.isPulling,
            newHasDefect: s.hasDefect,
            newDefectType: s.defectType,
            newIsCrashed: s.isCrashed,
            newIsDnf: s.isDnf,
          );
        }
      }
      return;
    }

    // Źródło 3: Tryb demonstracyjny (gdy brak aktywnej symulacji wyścigu)
    _ensureDemoRidersInitialized();
  }

  void _ensureDemoRidersInitialized() {
    if (_riderPool.isNotEmpty) return;

    final demoRiders = [
      ('demo_leader', 'T. Pogacar', 1, '#D4AF37', true, 18500.0, 0.2, 44.5, 435, 6.6, 92),
      ('demo_rival', 'J. Vingegaard', 11, '#EF4444', false, 18496.5, 0.4, 44.5, 410, 6.8, 96),
      ('demo_domestique', 'R. Majka', 2, '#38BDF8', true, 18492.0, -0.6, 44.2, 380, 5.7, 88),
      ('demo_sprinter', 'J. Philipsen', 21, '#10B981', false, 18485.0, 1.2, 44.0, 320, 4.4, 85),
      ('demo_chaser', 'W. Van Aert', 12, '#F59E0B', false, 18480.0, -0.2, 44.2, 450, 5.8, 94),
      ('demo_helper', 'M. Soler', 3, '#8B5CF6', true, 18475.0, -1.1, 43.8, 360, 5.1, 86),
      ('demo_gc4', 'R. Evenepoel', 31, '#0284C7', false, 18472.0, 0.5, 43.8, 415, 6.4, 94),
      ('demo_gc5', 'P. Roglic', 41, '#DC2626', false, 18468.0, -0.4, 43.6, 400, 6.2, 90),
    ];

    for (final d in demoRiders) {
      _riderPool[d.$1] = _InterpolatedRiderState(
        riderId: d.$1,
        riderName: d.$2,
        bibNumber: d.$3,
        teamJerseyHex: d.$4,
        isPlayerRider: d.$5,
        currentDistanceMeters: d.$6,
        targetDistanceMeters: d.$6 + 45.0,
        currentLateralOffsetMeters: d.$7,
        targetLateralOffsetMeters: d.$7,
        currentSpeedKmh: d.$8,
        targetSpeedKmh: d.$8,
        currentWatts: d.$9,
        targetWatts: d.$9,
        currentWattsPerKg: d.$10,
        targetWattsPerKg: d.$10,
        currentCadenceRpm: d.$11,
        targetCadenceRpm: d.$11,
        isDrafting: d.$1 != 'demo_leader',
        draftingSavingsPercent: 0.32,
      );
    }
  }

  void _stepCameraRig(double dt, List<StageSegment> segments, RaceStage activeStage) {
    if (_riderPool.isEmpty) return;

    final targetRiderId = _currentSelectedRiderId ??
        _riderPool.values.firstWhere((r) => r.isPlayerRider, orElse: () => _riderPool.values.first).riderId;
    final targetRider = _riderPool[targetRiderId] ?? _riderPool.values.first;

    final double targetElevation = _calculateElevationAt(targetRider.currentDistanceMeters, segments);
    final double targetGradient = _calculateGradientAt(targetRider.currentDistanceMeters, segments);

    final targetPose = Scene3DMathProjection.courseToCyclistPose(
      coursePosition: CoursePosition(
        distanceMeters: targetRider.currentDistanceMeters,
        lateralOffsetMeters: targetRider.currentLateralOffsetMeters,
        elevationMeters: targetElevation,
      ),
      roadGeometry: RoadGeometryParameters(
        turningRadiusMeters: double.infinity,
        gradientPercent: targetGradient,
        speedMs: targetRider.currentSpeedKmh / 3.6,
      ),
    );

    // Obliczenie centroidu peletonu (dla HeliCam)
    double sumDist = 0.0;
    for (final r in _riderPool.values) {
      sumDist += r.currentDistanceMeters;
    }
    final double avgDist = sumDist / _riderPool.length;
    final centroidPose = Scene3DMathProjection.courseToCyclistPose(
      coursePosition: CoursePosition(
        distanceMeters: avgDist,
        lateralOffsetMeters: 0.0,
        elevationMeters: _calculateElevationAt(avgDist, segments),
      ),
      roadGeometry: RoadGeometryParameters(
        turningRadiusMeters: double.infinity,
        gradientPercent: _calculateGradientAt(avgDist, segments),
        speedMs: 12.5,
      ),
    );

    // Pozycja bramy mety
    final double finishDist = activeStage.totalDistanceKm * 1000.0;
    final finishPose = Scene3DMathProjection.courseToCyclistPose(
      coursePosition: CoursePosition(
        distanceMeters: finishDist,
        lateralOffsetMeters: 0.0,
        elevationMeters: _calculateElevationAt(finishDist, segments),
      ),
      roadGeometry: const RoadGeometryParameters(
        turningRadiusMeters: double.infinity,
        gradientPercent: 0.0,
      ),
    );

    _cameraRigController.update(
      dtSeconds: dt,
      targetRiderPose: targetPose,
      pelotonCentroid: centroidPose.position,
      pelotonSpreadRadius: 20.0,
      finishLinePosition: finishPose.position,
      finishApproachDirection: finishPose.tangent,
      isSprinting: targetRider.currentWatts > 750,
      isAttacking: targetRider.isPulling && targetRider.currentWatts > 450,
      riderSpeedMs: targetRider.currentSpeedKmh / 3.6,
    );
  }

  void _updateRoadAndScenery(List<StageSegment> segments, RaceStage activeStage) {
    if (_riderPool.isEmpty) return;

    final targetRiderId = _currentSelectedRiderId ??
        _riderPool.values.firstWhere((r) => r.isPlayerRider, orElse: () => _riderPool.values.first).riderId;
    final targetRider = _riderPool[targetRiderId] ?? _riderPool.values.first;

    final double currentDist = targetRider.currentDistanceMeters;

    // Odświeżanie wstęgi drogi co 15 metrów
    if ((currentDist - _lastRoadMeshUpdateDist).abs() > 15.0 || _currentRoadMesh == null) {
      _lastRoadMeshUpdateDist = currentDist;
      final double windowStart = math.max(0.0, currentDist - 40.0);
      _currentRoadMesh = _roadRibbonBuilder.buildRoadRibbonMesh(
        segments: segments,
        windowStartMeters: windowStart,
        windowLengthMeters: 450.0,
      );
    }

    // Odświeżanie instancji otoczenia co 15 metrów
    if ((currentDist - _lastSceneryUpdateDist).abs() > 15.0 || _currentSceneryInstances.isEmpty) {
      _lastSceneryUpdateDist = currentDist;
      _currentSceneryInstances = _scenerySpawner.spawnSceneryInWindow(
        cameraDistanceMeters: currentDist,
        segments: segments,
        projection: _projection,
        stageSeed: activeStage.stageNumber * 37 + 101,
        totalStageLengthKm: activeStage.totalDistanceKm,
      );

      // Odświeżanie instancji infrastruktury szosowej (bramy, barierki, tablice)
      final allFurniture = _roadFurnitureRenderer.spawnFurnitureForStage(
        stage: activeStage,
        segments: segments,
      );
      _currentFurnitureInstances = _roadFurnitureRenderer.getFurnitureInWindow(
        allFurniture: allFurniture,
        cameraDistanceMeters: currentDist,
      );
    }
  }

  void _preparePelotonRenderList(List<StageSegment> segments, double dt) {
    final double vpW = _viewportSize.width > 0 ? _viewportSize.width : 1280.0;
    final double vpH = _viewportSize.height > 0 ? _viewportSize.height : 720.0;
    _projection.updateCamera(
      _cameraRigController.toCameraConfig(),
      viewportWidth: vpW,
      viewportHeight: vpH,
    );

    final snapshots = _riderPool.values.map((r) {
      final elev = _calculateElevationAt(r.currentDistanceMeters, segments);
      final grad = _calculateGradientAt(r.currentDistanceMeters, segments);
      return r.toSnapshot(elevationMeters: elev, gradientPercent: grad);
    }).toList();

    _currentPelotonRenderItems = _pelotonRenderer.prepareDrawList(
      riders: snapshots,
      projection: _projection,
      cameraController: _cameraRigController,
      segments: segments,
      dtSeconds: dt,
    );
  }

  void _updateWeatherSystem(double dt, RaceStage activeStage, List<StageSegment> segments) {
    final telemetry = _buildWeatherTelemetry(dt: dt, activeStage: activeStage, segments: segments);
    _lastWeatherTelemetry = telemetry;

    _weatherRenderer.update(
      telemetry: telemetry,
      viewportWidth: _viewportSize.width,
      viewportHeight: _viewportSize.height,
      activeRiders: _currentPelotonRenderItems,
    );
  }

  WeatherSystemTelemetry _buildWeatherTelemetry({
    required double dt,
    required RaceStage activeStage,
    required List<StageSegment> segments,
  }) {
    if (_riderPool.isEmpty) {
      return WeatherSystemTelemetry(
        weatherCondition: activeStage.weatherCondition,
        windSpeedKmh: activeStage.windSpeedKmh,
        windDirectionDegrees: 180.0,
        dtSeconds: dt,
        elapsedSeconds: _elapsedAnimSeconds,
      );
    }

    final targetRiderId = _currentSelectedRiderId ??
        _riderPool.values.firstWhere((r) => r.isPlayerRider, orElse: () => _riderPool.values.first).riderId;
    final targetRider = _riderPool[targetRiderId] ?? _riderPool.values.first;

    final double currentDist = targetRider.currentDistanceMeters;
    final double elevation = _calculateElevationAt(currentDist, segments);

    final currentKm = currentDist / 1000.0;
    StageSegment? currentSeg;
    for (final seg in segments) {
      if (currentKm >= seg.startKm && currentKm <= seg.endKm) {
        currentSeg = seg;
        break;
      }
    }
    currentSeg ??= segments.isNotEmpty ? segments.first : null;

    final isHc = currentSeg?.sprintOrKomClassification == SegmentClassification.horsCategorie;
    final surfaceType = currentSeg?.surfaceType ?? SegmentSurfaceType.smoothAsphalt;
    final windSpeed = activeStage.windSpeedKmh;
    final windDirection = currentSeg?.windDirectionDegrees ?? 180.0;

    final forward = (_cameraRigController.target - _cameraRigController.position);
    final bearingRad = (forward.length2 > 1e-6) ? math.atan2(forward.x, forward.z) : 0.0;

    return WeatherSystemTelemetry(
      weatherCondition: activeStage.weatherCondition,
      windSpeedKmh: windSpeed,
      windDirectionDegrees: windDirection,
      cameraBearingRadians: bearingRad,
      currentElevationMeters: elevation,
      isHorsCategorie: isHc,
      currentSurfaceType: surfaceType,
      dtSeconds: dt,
      elapsedSeconds: _elapsedAnimSeconds,
    );
  }

  double _calculateElevationAt(double distMeters, List<StageSegment> segments) {
    if (segments.isEmpty) return 450.0;
    final km = distMeters / 1000.0;
    for (final seg in segments) {
      if (km >= seg.startKm && km <= seg.endKm) {
        final len = math.max(0.001, seg.endKm - seg.startKm);
        final t = ((km - seg.startKm) / len).clamp(0.0, 1.0);
        return seg.startElevationM + (seg.endElevationM - seg.startElevationM) * t;
      }
    }
    return segments.last.endElevationM;
  }

  double _calculateGradientAt(double distMeters, List<StageSegment> segments) {
    if (segments.isEmpty) return 4.5;
    final km = distMeters / 1000.0;
    for (final seg in segments) {
      if (km >= seg.startKm && km <= seg.endKm) {
        return seg.gradientPercent;
      }
    }
    return segments.last.gradientPercent;
  }

  void _switchCameraMode(ViewportCameraMode newMode) {
    setState(() {
      _cameraMode = newMode;
    });
    _cameraRigController.switchMode(newMode.toRigMode());
    _cameraRigController.resetManualOrbit();
    widget.onCameraModeChanged?.call(newMode);
  }

  /// Wykrywa kliknięcie 3D na kolarza w peletonie (Screen Raycast / Hit-Testing).
  PelotonRenderItem? _hitTestRider(Offset tapPosition) {
    PelotonRenderItem? bestMatch;
    double minWeightedDist = double.infinity;

    for (final item in _currentPelotonRenderItems) {
      if (!item.projectedCenter.isInFrontOfCamera) continue;

      final pX = item.projectedCenter.screenX;
      final pY = item.projectedCenter.screenY;

      // Obszar kliknięcia dopasowany do perspektywicznej skali kolarza na ekranie (35px - 140px)
      final double hitRadius = (60.0 * item.screenScale).clamp(35.0, 140.0);
      final double screenDist = (Offset(pX, pY) - tapPosition).distance;

      if (screenDist <= hitRadius) {
        // Ważona odległość: kolarze znajdujący się bliżej kamery w 3D mają priorytet kliknięcia
        final double weightedDist = screenDist + (item.cameraDistance * 0.75);
        if (weightedDist < minWeightedDist) {
          minWeightedDist = weightedDist;
          bestMatch = item;
        }
      }
    }

    // Fallback: Jeśli kliknięcie nastąpiło w pobliżu kolarza śledzonego przez kamerę
    if (bestMatch == null && _currentPelotonRenderItems.isNotEmpty) {
      final tracked = _currentPelotonRenderItems.firstWhere(
        (it) => it.snapshot.riderId == _currentSelectedRiderId,
        orElse: () => _currentPelotonRenderItems.first,
      );
      final pX = tracked.projectedCenter.screenX;
      final pY = tracked.projectedCenter.screenY;
      if ((Offset(pX, pY) - tapPosition).distance < 220.0) {
        bestMatch = tracked;
      }
    }

    return bestMatch;
  }

  void _handleViewportTap(BuildContext context, Offset tapPosition) {
    final hitRider = _hitTestRider(tapPosition);
    if (hitRider != null) {
      final selectedId = hitRider.snapshot.riderId;
      setState(() {
        _currentSelectedRiderId = selectedId;
      });
      widget.onRiderSelected?.call(selectedId);

      _showRiderTacticalSheet(context, hitRider.snapshot);
    }
  }

  void _issueTacticalOrder(RiderPositionSnapshot rider, TacticalOrder order) {
    // 1. Zapis polecenia w głównym kontrolerze symulacji wyścigu
    try {
      ref.read(raceSimulationProvider.notifier).setRiderTacticalOrder(rider.riderId, order);
    } catch (_) {}

    // 2. Natychmiastowa reakcja w lokalnej puli kolarzy 3D
    final localRider = _riderPool[rider.riderId];
    if (localRider != null) {
      switch (order) {
        case TacticalOrder.attack:
          localRider.updateTarget(
            newDistanceMeters: localRider.targetDistanceMeters,
            newLateralOffsetMeters: localRider.targetLateralOffsetMeters,
            newSpeedKmh: localRider.targetSpeedKmh + 4.8,
            newWatts: 620,
            newWattsPerKg: 8.8,
            newCadenceRpm: 106,
            newIsDrafting: false,
            newDraftingSavingsPercent: 0.0,
            newIsPulling: true,
          );
          break;
        case TacticalOrder.pullGroup:
          localRider.updateTarget(
            newDistanceMeters: localRider.targetDistanceMeters,
            newLateralOffsetMeters: 0.0,
            newSpeedKmh: localRider.targetSpeedKmh + 1.5,
            newWatts: 460,
            newWattsPerKg: 6.5,
            newCadenceRpm: 96,
            newIsDrafting: false,
            newDraftingSavingsPercent: 0.0,
            newIsPulling: true,
          );
          break;
        case TacticalOrder.saveEnergy:
          localRider.updateTarget(
            newDistanceMeters: localRider.targetDistanceMeters,
            newLateralOffsetMeters: localRider.targetLateralOffsetMeters,
            newSpeedKmh: localRider.targetSpeedKmh,
            newWatts: 240,
            newWattsPerKg: 3.4,
            newCadenceRpm: 84,
            newIsDrafting: true,
            newDraftingSavingsPercent: 0.38,
            newIsPulling: false,
          );
          break;
        case TacticalOrder.fetchBidonsFromCar:
          localRider.updateTarget(
            newDistanceMeters: localRider.targetDistanceMeters - 12.0,
            newLateralOffsetMeters: 2.2,
            newSpeedKmh: localRider.targetSpeedKmh - 3.0,
            newWatts: 280,
            newWattsPerKg: 4.0,
            newCadenceRpm: 88,
            newIsDrafting: false,
            newDraftingSavingsPercent: 0.0,
            newIsPulling: false,
          );
          break;
        case TacticalOrder.protectLeader:
        case TacticalOrder.followWheels:
        case TacticalOrder.holdPosition:
          localRider.updateTarget(
            newDistanceMeters: localRider.targetDistanceMeters,
            newLateralOffsetMeters: localRider.targetLateralOffsetMeters,
            newSpeedKmh: localRider.targetSpeedKmh,
            newWatts: 350,
            newWattsPerKg: 5.0,
            newCadenceRpm: 90,
            newIsDrafting: true,
            newDraftingSavingsPercent: 0.28,
            newIsPulling: false,
          );
          break;
      }
    }

    // 3. Wyświetlenie informacji zwrotnej na HUD
    setState(() {
      _tacticalFeedbackMessage = 'Rozkaz: ${order.label.toUpperCase()} (#${rider.bibNumber} ${rider.riderName})';
    });

    _tacticalFeedbackTimer?.cancel();
    _tacticalFeedbackTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _tacticalFeedbackMessage = null;
        });
      }
    });
  }

  void _showRiderTacticalSheet(BuildContext context, RiderPositionSnapshot rider) {
    final bool isPlayer = rider.isPlayerRider || widget.playerRiderIds.contains(rider.riderId);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _RiderTacticalBottomSheet(
        rider: rider,
        isPlayerTeam: isPlayer,
        onOrderSelected: (order) {
          Navigator.of(ctx).pop();
          _issueTacticalOrder(rider, order);
        },
        onTrackWithCamera: () {
          Navigator.of(ctx).pop();
          setState(() {
            _currentSelectedRiderId = rider.riderId;
          });
          widget.onRiderSelected?.call(rider.riderId);
        },
      ),
    );
  }

  Widget _buildCameraOrbitIndicator() {
    final yawDeg = (_cameraRigController.manualOrbitYaw * 180.0 / math.pi) % 360.0;
    final zoom = _cameraRigController.manualZoomScale;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F121C).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.6), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sync_rounded, size: 14, color: AppColors.cyanAccent),
          const SizedBox(width: 6),
          Text(
            'ORBIT: ${yawDeg.round()}° • ${zoom.toStringAsFixed(1)}x',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              setState(() {
                _cameraRigController.resetManualOrbit();
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.cyanAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'RESET',
                style: TextStyle(
                  color: AppColors.cyanAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalFeedbackBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            _tacticalFeedbackMessage!,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeStage = widget.stage ??
        ref.watch(raceSimulationProvider).simulationState?.stage ??
        _generateDemoStage();

    if (_riderPool.isEmpty) {
      _synchronizeRiderData();
    }

    final trackedRider = _riderPool[_currentSelectedRiderId] ??
        (_riderPool.isNotEmpty
            ? _riderPool.values.firstWhere((r) => r.isPlayerRider, orElse: () => _riderPool.values.first)
            : null);

    if (trackedRider == null) {
      return const ColoredBox(color: Colors.black);
    }

    final segments = activeStage.segments.isNotEmpty ? activeStage.segments : _generateDemoSegments();
    final weatherTelemetry = _lastWeatherTelemetry ??
        _buildWeatherTelemetry(dt: 0.016, activeStage: activeStage, segments: segments);

    final bool isManualOrbitActive = _cameraRigController.manualOrbitYaw.abs() > 0.04 ||
        _cameraRigController.manualOrbitPitch.abs() > 0.04 ||
        (_cameraRigController.manualZoomScale - 1.0).abs() > 0.04;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Główny Canvas 3D renderujący pełną scenę wyścigu z gestami myszy i dotyku
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.hasBoundedWidth && constraints.hasBoundedHeight) {
                _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
              }
              return Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    final double deltaZoom = event.scrollDelta.dy * 0.0012;
                    setState(() {
                      _cameraRigController.addManualOrbit(deltaZoom: deltaZoom);
                    });
                  }
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: (details) {
                    _baseZoomScale = _cameraRigController.manualZoomScale;
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      if (details.pointerCount == 1) {
                        // Obracanie kamery wokół kolarza (Drag to Orbit Yaw & Pitch)
                        final double deltaX = details.focalPointDelta.dx;
                        final double deltaY = details.focalPointDelta.dy;
                        _cameraRigController.addManualOrbit(
                          deltaYaw: -deltaX * 0.007,
                          deltaPitch: -deltaY * 0.005,
                        );
                      } else if (details.pointerCount >= 2) {
                        // Przybliżanie szczypaniem (Pinch-to-zoom)
                        _cameraRigController.setManualOrbit(
                          zoomScale: _baseZoomScale / details.scale,
                        );
                      }
                    });
                  },
                  onTapUp: (details) {
                    _handleViewportTap(context, details.localPosition);
                  },
                  onDoubleTap: () {
                    setState(() {
                      _cameraRigController.resetManualOrbit();
                    });
                  },
                  child: CustomPaint(
                    painter: _ZwiftStyle3DViewportPainter(
                      stage: activeStage,
                      cameraRigController: _cameraRigController,
                      projection: _projection,
                      roadMesh: _currentRoadMesh,
                      scenerySpawner: _scenerySpawner,
                      sceneryInstances: _currentSceneryInstances,
                      roadFurnitureRenderer: _roadFurnitureRenderer,
                      furnitureInstances: _currentFurnitureInstances,
                      supportVehiclesRenderer: _supportVehiclesRenderer,
                      supportVehicles: _currentSupportVehicles,
                      pelotonRenderer: _pelotonRenderer,
                      pelotonRenderItems: _currentPelotonRenderItems,
                      crashVisualsRenderer: _crashVisualsRenderer,
                      showIncidentVisuals: widget.showIncidentVisuals,
                      windVisualizer: _windVisualizer,
                      isAeroVisionActive: _isAeroVisionActive,
                      weatherRenderer: _weatherRenderer,
                      weatherTelemetry: weatherTelemetry,
                      riderLabelsOverlay: _riderLabelsOverlay,
                      selectedRiderId: trackedRider.riderId,
                      playerRiderIds: widget.playerRiderIds,
                      elapsedAnimSeconds: _elapsedAnimSeconds,
                      showDraftingStreams: widget.showDraftingStreams,
                      showRiderLabels: widget.showRiderLabels,
                    ),
                    size: Size.infinite,
                  ),
                ),
              );
            },
          ),

          // 2. Transmisja TV / Telemetria Wyścigu (Broadcast HUD Overlay)
          if (widget.showBroadcastHud)
            Positioned(
              top: 16,
              left: 16,
              child: _buildBroadcastHudCard(activeStage, trackedRider),
            ),

          // 3. Wskaźnik ręcznego obrotu kamery (Orbit / Zoom Indicator z przyciskiem RESET)
          if (isManualOrbitActive)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: _buildCameraOrbitIndicator(),
              ),
            ),

          // 4. Pasek powiadomienia o wydanym rozkazie taktycznym
          if (_tacticalFeedbackMessage != null)
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Center(
                child: _buildTacticalFeedbackBanner(),
              ),
            ),

          // 5. Pasek Przełączania Kamer i Trybu Aero Vision
          if (widget.showCameraControls)
            Positioned(
              bottom: 16,
              right: 16,
              child: _buildCameraAndAeroControlsHud(activeStage),
            ),

          // 6. Komputer Rowerowy Kolarza Gracza (Garmin Edge / Wahoo Elemnt HUD)
          if (widget.showOnBikeComputer &&
              (trackedRider.isPlayerRider || widget.playerRiderIds.contains(trackedRider.riderId)))
            Positioned(
              bottom: 16,
              left: 16,
              child: OnBikeComputerHudWidget(
                riderSnapshot: trackedRider.toSnapshot(
                  elevationMeters: _calculateElevationAt(trackedRider.currentDistanceMeters, segments),
                  gradientPercent: _calculateGradientAt(trackedRider.currentDistanceMeters, segments),
                ),
                stage: activeStage,
                segments: segments,
                model: widget.bikeComputerModel,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBroadcastHudCard(RaceStage stage, _InterpolatedRiderState rider) {
    final double distRemainingKm = math.max(0.0, stage.totalDistanceKm - (rider.currentDistanceMeters / 1000.0));
    final double gradient = (stage.segments.isNotEmpty)
        ? stage.segments.first.gradientPercent
        : 4.5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F121C).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'LIVE BROADCAST 3D',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${_cameraMode.shortLabel.toUpperCase()}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '#${rider.bibNumber} ${rider.riderName}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _emeraldPower.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${rider.currentWatts} W (${rider.currentWattsPerKg.toStringAsFixed(1)} W/kg)',
                  style: const TextStyle(color: _emeraldPower, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Prędkość: ${rider.currentSpeedKmh.toStringAsFixed(1)} km/h • Kadencja: ${rider.currentCadenceRpm} RPM',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
              const SizedBox(width: 10),
              Text(
                'Do mety: ${distRemainingKm.toStringAsFixed(1)} km • Nachylenie: +${gradient.toStringAsFixed(1)}%',
                style: const TextStyle(color: _goldPlayerAccent, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraAndAeroControlsHud(RaceStage activeStage) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Przełącznik kamer
        _buildCameraSwitcherHud(),
        const SizedBox(width: 8),
        // Przycisk przełączania trybu Aero Vision ("Tunel Aerodynamiczny na żywo")
        _buildAeroVisionToggleButton(),
        const SizedBox(width: 8),
        // Przycisk Photo Finish
        _buildPhotoFinishButton(activeStage),
      ],
    );
  }

  Widget _buildPhotoFinishButton(RaceStage activeStage) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F121C).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF003B).withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showPhotoFinishReplayDialog(
              context,
              data: PhotoFinishData.demoSprintFinish(
                stageName: activeStage.name,
                stageNumber: activeStage.stageNumber,
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.camera_alt_rounded,
                  size: 15,
                  color: Color(0xFFFF003B),
                ),
                SizedBox(width: 6),
                Text(
                  'PHOTO FINISH',
                  style: TextStyle(
                    color: Color(0xFFFF003B),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAeroVisionToggleButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F121C).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isAeroVisionActive ? AppColors.cyanAccent : AppTheme.borderColor,
          width: _isAeroVisionActive ? 1.5 : 1.0,
        ),
        boxShadow: _isAeroVisionActive
            ? [
                BoxShadow(
                  color: AppColors.cyanAccent.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isAeroVisionActive = !_isAeroVisionActive;
              _windVisualizer.setAeroVisionActive(_isAeroVisionActive);
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.air_rounded,
                  size: 16,
                  color: _isAeroVisionActive ? AppColors.cyanAccent : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'AERO VISION',
                  style: TextStyle(
                    color: _isAeroVisionActive ? AppColors.cyanAccent : AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                if (_isAeroVisionActive) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cyanAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraSwitcherHud() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F121C).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ViewportCameraMode.values.map((mode) {
          final isSelected = _cameraMode == mode;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () => _switchCameraMode(mode),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.goldAccent : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      mode.icon,
                      color: isSelected ? Colors.black : AppColors.textSecondary,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      mode.shortLabel,
                      style: TextStyle(
                        color: isSelected ? Colors.black : AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  RaceStage _generateDemoStage() {
    return const RaceStage(
      id: 'demo_stage_alpe',
      stageNumber: 14,
      name: 'Bourg d\'Oisans > Alpe d\'Huez',
      stageType: StageType.summitFinish,
      segments: [],
      baseTemperatureCelsius: 22.0,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 14.0,
    );
  }

  List<StageSegment> _generateDemoSegments() {
    return const [
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 6.0,
        startElevationM: 450.0,
        endElevationM: 570.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 20.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 45.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 1,
        startKm: 6.0,
        lengthKm: 5.0,
        startElevationM: 570.0,
        endElevationM: 980.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 55.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 60.0,
        sprintOrKomClassification: SegmentClassification.cat2,
      ),
      StageSegment(
        index: 2,
        startKm: 11.0,
        lengthKm: 5.5,
        startElevationM: 980.0,
        endElevationM: 1540.0,
        surfaceType: SegmentSurfaceType.roughAsphalt,
        technicalDifficulty: 75.0,
        windDirectionDegrees: 210.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.cat1,
      ),
      StageSegment(
        index: 3,
        startKm: 16.5,
        lengthKm: 4.5,
        startElevationM: 1540.0,
        endElevationM: 1860.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 85.0,
        windDirectionDegrees: 240.0,
        roadBearingDegrees: 75.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      ),
    ];
  }
}

/// Główny Painter Perspektywy 3D Szosy, Kolarzy, Strugi Aero i Otoczenia (Zwift Engine).
class _ZwiftStyle3DViewportPainter extends CustomPainter {
  final RaceStage stage;
  final CameraRigController cameraRigController;
  final Scene3DMathProjection projection;
  final RoadRibbonMesh? roadMesh;
  final EnvironmentScenerySpawner scenerySpawner;
  final List<SceneryInstance3D> sceneryInstances;
  final RoadFurniture3DRenderer roadFurnitureRenderer;
  final List<RoadFurnitureInstance3D> furnitureInstances;
  final SupportVehicles3DRenderer supportVehiclesRenderer;
  final List<SupportVehicleInstance3D> supportVehicles;
  final PelotonInstancedRenderer pelotonRenderer;
  final List<PelotonRenderItem> pelotonRenderItems;
  final CrashAndMechanicalVisualsRenderer? crashVisualsRenderer;
  final WindStreamlinesVisualizer? windVisualizer;
  final WeatherParticlesRenderer weatherRenderer;
  final WeatherSystemTelemetry weatherTelemetry;
  final RiderFloatingLabelsOverlay riderLabelsOverlay;
  final String selectedRiderId;
  final List<String> playerRiderIds;
  final double elapsedAnimSeconds;
  final bool showDraftingStreams;
  final bool showRiderLabels;
  final bool showIncidentVisuals;
  final bool isAeroVisionActive;

  // Statyczne bufory farb malarskich
  static final Paint _groundPaint = Paint()
    ..color = const Color(0xFF131D16)
    ..style = PaintingStyle.fill;

  static final Paint _roadPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _vergePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFF1B2E1E);
  static final Paint _vergeAltPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFF142416);
  static final Paint _edgeLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xD9FFFFFF);
  static final Paint _centerLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xB3FFFFFF);
  static final Paint _wetSheenPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0x10FFFFFF);

  _ZwiftStyle3DViewportPainter({
    required this.stage,
    required this.cameraRigController,
    required this.projection,
    required this.roadMesh,
    required this.scenerySpawner,
    required this.sceneryInstances,
    required this.roadFurnitureRenderer,
    required this.furnitureInstances,
    required this.supportVehiclesRenderer,
    required this.supportVehicles,
    required this.pelotonRenderer,
    required this.pelotonRenderItems,
    this.crashVisualsRenderer,
    this.windVisualizer,
    required this.weatherRenderer,
    required this.weatherTelemetry,
    required this.riderLabelsOverlay,
    required this.selectedRiderId,
    required this.playerRiderIds,
    required this.elapsedAnimSeconds,
    required this.showDraftingStreams,
    required this.showRiderLabels,
    this.showIncidentVisuals = true,
    this.isAeroVisionActive = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Konfiguracja geometrii rzutowania 3D
    projection.updateCamera(
      cameraRigController.toCameraConfig(),
      viewportWidth: w,
      viewportHeight: h,
    );

    // 2. Analityczne wyznaczenie linii horyzontu na ekranie
    final forwardDir = (cameraRigController.target - cameraRigController.position);
    if (forwardDir.length2 > 1e-6) forwardDir.normalize();
    final horizTarget = Vector3(forwardDir.x, 0.0, forwardDir.z);
    if (horizTarget.length2 > 1e-6) horizTarget.normalize();
    final farPoint = cameraRigController.position + (horizTarget * 2000.0);
    final projHorizon = projection.worldToScreen(farPoint);

    final double horizonY = projHorizon.isInFrontOfCamera
        ? projHorizon.screenY.clamp(h * 0.15, h * 0.85)
        : h * 0.44;

    final double totalStageMeters = stage.totalDistanceKm > 0.1
        ? stage.totalDistanceKm * 1000.0
        : 21000.0;
    final double leaderDistMeters = pelotonRenderItems.isNotEmpty
        ? pelotonRenderItems.first.snapshot.distanceCoveredMeters
        : 0.0;
    final double stageProgress = (leaderDistMeters / totalStageMeters).clamp(0.0, 1.0);
    final StageTimeOfDay stageTime = StageTimeOfDay.forStageProgress(
      stageType: stage.stageType,
      progressRatio: stageProgress,
      stageName: stage.name,
    );
    final SunLightState sunState = DynamicSkyboxAndLightingPainter.computeSunLightState(
      timeOfDay: stageTime,
      weatherCondition: weatherTelemetry.weatherCondition,
      elapsedSeconds: elapsedAnimSeconds,
    );
    final lightingPainter = DynamicSkyboxAndLightingPainter(
      timeOfDay: stageTime,
      weatherCondition: weatherTelemetry.weatherCondition,
      cameraBearingRadians: weatherTelemetry.cameraBearingRadians,
      elapsedSeconds: elapsedAnimSeconds,
      projection: projection,
      pelotonRenderItems: pelotonRenderItems,
      supportVehicles: supportVehicles,
      roadMesh: roadMesh,
    );

    // 3. Rysowanie proceduralnego nieba, słońca, chmur burzowych i latarni (Dynamic Skybox)
    lightingPainter.renderSkybox(
      canvas: canvas,
      size: size,
      horizonY: horizonY,
      sunState: sunState,
    );

    // 4. Rysowanie pasma górskiego w paralaksie (Parallax Mountains)
    _drawParallaxMountains(canvas, w, horizonY);

    // 5. Podłoże doliny / trawa poniżej horyzontu
    canvas.drawRect(Rect.fromLTWH(0, horizonY, w, h - horizonY), _groundPaint);

    // 6. Mgła wysokogórska i pasma chmur na szczytach Hors Categorie
    weatherRenderer.renderAlpineFog(
      canvas: canvas,
      size: size,
      elevationMeters: weatherTelemetry.currentElevationMeters,
      isHorsCategorie: weatherTelemetry.isHorsCategorie,
      elapsedSeconds: elapsedAnimSeconds,
      horizonY: horizonY,
    );

    // 7. Rysowanie wstęgi szosy 3D (Road Ribbon, Cobblestones, Edge Lines & Fan Graffiti)
    if (roadMesh != null) {
      _drawRoadMesh(canvas, roadMesh!, projection);
      if (sunState.isWetSurface) {
        lightingPainter.renderWetRoadSpecularReflections(
          canvas: canvas,
          size: size,
          projection: projection,
          pelotonItems: pelotonRenderItems,
          supportVehicles: supportVehicles,
          sunState: sunState,
        );
      }
    }

    // 8. Rysowanie obiektów krajobrazu i kibiców (Environment Scenery Spawner)
    if (sceneryInstances.isNotEmpty) {
      scenerySpawner.renderSceneryInstances(
        canvas: canvas,
        projection: projection,
        instances: sceneryInstances,
        animSeconds: elapsedAnimSeconds,
      );
    }

    // 8b. Rysowanie infrastruktury szosowej (bramy Flamme Rouge, KOM, sprint, mety, barierki, tablice km)
    if (furnitureInstances.isNotEmpty) {
      roadFurnitureRenderer.renderRoadFurniture(
        canvas: canvas,
        projection: projection,
        instances: furnitureInstances,
        elapsedAnimSeconds: elapsedAnimSeconds,
      );
    }

    // 8c. Rysowanie pojazdów towarzyszących (wozy techniczne z rowerami na dachu, motocykle TV, neutralny serwis)
    if (supportVehicles.isNotEmpty) {
      supportVehiclesRenderer.renderSupportVehicles(
        canvas: canvas,
        projection: projection,
        vehicles: supportVehicles,
        elapsedAnimSeconds: elapsedAnimSeconds,
      );
    }

    // 9. Rysowanie rzutowanych cieni kolarzy na asfalt oraz samych kolarzy (LOD 0/1/2)
    if (pelotonRenderItems.isNotEmpty) {
      lightingPainter.renderProjectedDropShadows(
        canvas: canvas,
        projection: projection,
        pelotonItems: pelotonRenderItems,
        sunState: sunState,
      );
      pelotonRenderer.renderPeloton(
        canvas: canvas,
        size: size,
        projection: projection,
        renderItems: pelotonRenderItems,
      );
    }

    // 9b. Wizualizacja zdarzeń losowych w 3D (awarie sprzętowe, wymiana kół, kraksy i podnoszenie się kolarzy)
    if (showIncidentVisuals && crashVisualsRenderer != null) {
      crashVisualsRenderer!.renderIncidentVisuals(
        canvas: canvas,
        projection: projection,
        animSeconds: elapsedAnimSeconds,
      );
    }

    // 9c. Wizualizacja tunelu aerodynamicznego na żywo ("Aero Vision Mode" - strefy cienia, wiatr boczny, kompas)
    if (isAeroVisionActive && windVisualizer != null) {
      windVisualizer!.renderAeroVision(
        canvas: canvas,
        size: size,
        projection: projection,
        elapsedAnimSeconds: elapsedAnimSeconds,
      );
    }

    // 10. Trójwymiarowe pióropusze wody spod kół (spray) i chmury pyłu (Strade/Bruk)
    weatherRenderer.renderWorldParticles(
      canvas: canvas,
      projection: projection,
    );

    // 11. Efekty ekranowe (deszcz, wyładowania burzowe, krople na obiektywie kamery TV)
    weatherRenderer.renderScreenWeather(
      canvas: canvas,
      size: size,
      telemetry: weatherTelemetry,
    );

    // 12. Pływające etykiety kolarzy (Zwift-Style Nameplates: Flaga, Nazwisko, W/kg, Koszulki, Atak/Tarcza)
    if (showRiderLabels && pelotonRenderItems.isNotEmpty) {
      riderLabelsOverlay.renderFloatingLabels(
        canvas: canvas,
        size: size,
        projection: projection,
        renderItems: pelotonRenderItems,
        selectedRiderId: selectedRiderId,
        playerRiderIds: playerRiderIds,
        animSeconds: elapsedAnimSeconds,
      );
    }
  }

  // ===========================================================================
  // 2. PARALAKSA GÓRSKA
  // ===========================================================================

  void _drawParallaxMountains(Canvas canvas, double w, double horizonY) {
    final mountainPaintFar = Paint()..color = const Color(0xFF1C2C42);
    final mountainPaintNear = Paint()..color = const Color(0xFF152233);
    final snowcapPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);

    final double panShift = (cameraRigController.position.x * 2.5 + cameraRigController.position.z * 0.05) % w;

    // Pasmo dalekie
    final pathFar = Path()..moveTo(0, horizonY);
    for (double x = -100; x <= w + 100; x += 120) {
      final double peakY = horizonY - 60 - math.sin((x + panShift) * 0.01) * 45;
      pathFar.lineTo(x + 60, peakY);
      pathFar.lineTo(x + 120, horizonY);
    }
    pathFar.lineTo(w, horizonY);
    pathFar.close();
    canvas.drawPath(pathFar, mountainPaintFar);

    // Pasmo bliskie z ośnieżonymi szczytami
    final pathNear = Path()..moveTo(0, horizonY);
    for (double x = -80; x <= w + 80; x += 160) {
      final double peakY = horizonY - 45 - math.cos((x - panShift) * 0.015) * 35;
      pathNear.lineTo(x + 80, peakY);

      // Śnieg na szczycie
      final snowPath = Path()
        ..moveTo(x + 65, peakY + 12)
        ..lineTo(x + 80, peakY)
        ..lineTo(x + 95, peakY + 12)
        ..close();
      canvas.drawPath(snowPath, snowcapPaint);

      pathNear.lineTo(x + 160, horizonY);
    }
    pathNear.lineTo(w, horizonY);
    pathNear.close();
    canvas.drawPath(pathNear, mountainPaintNear);
  }

  // ===========================================================================
  // 3. WSTĘGA SZOSY 3D, BRUK, LINIE I NAPISY KIBICÓW (ROAD RIBBON)
  // ===========================================================================

  void _drawRoadMesh(Canvas canvas, RoadRibbonMesh mesh, Scene3DMathProjection proj) {
    final slices = mesh.slices;
    if (slices.length < 2) return;

    final eyePos = cameraRigController.position;
    final surfaceProps = mesh.materialProperties;
    final bool isWet = surfaceProps.isWet;

    final Color baseAsphalt = _parseHexColor(surfaceProps.baseColorHex, const Color(0xFF1E2430));
    final Color darkerAsphalt = Color.lerp(baseAsphalt, Colors.black, 0.14)!;

    // Sortowanie segmentów szosy w porządku Back-to-Front (najdalsze najpierw)
    final quads = <(int, double)>[];
    for (int i = 0; i < slices.length - 1; i++) {
      final midDist = (slices[i].center - eyePos).length;
      quads.add((i, midDist));
    }
    quads.sort((a, b) => b.$2.compareTo(a.$2));

    for (final entry in quads) {
      final int i = entry.$1;
      final slice0 = slices[i];
      final slice1 = slices[i + 1];

      final pLeftVerge0 = proj.worldToScreen(slice0.leftVerge);
      final pLeftRoad0 = proj.worldToScreen(slice0.leftRoadEdge);
      final pCenter0 = proj.worldToScreen(slice0.center);
      final pRightRoad0 = proj.worldToScreen(slice0.rightRoadEdge);
      final pRightVerge0 = proj.worldToScreen(slice0.rightVerge);

      final pLeftVerge1 = proj.worldToScreen(slice1.leftVerge);
      final pLeftRoad1 = proj.worldToScreen(slice1.leftRoadEdge);
      final pCenter1 = proj.worldToScreen(slice1.center);
      final pRightRoad1 = proj.worldToScreen(slice1.rightRoadEdge);
      final pRightVerge1 = proj.worldToScreen(slice1.rightVerge);

      // Pomijanie fragmentów całkowicie znajdujących się za plecami kamery
      if (!pCenter0.isInFrontOfCamera && !pCenter1.isInFrontOfCamera) continue;

      // Obcinanie marginesów ekranu
      if ((pCenter0.screenY < -240 && pCenter1.screenY < -240) ||
          (pCenter0.screenY > proj.viewportHeight + 240 && pCenter1.screenY > proj.viewportHeight + 240)) {
        continue;
      }

      final bool isAlt = (i % 2 == 0);

      // 1. Lewe pobocze
      final leftVergePath = Path()
        ..moveTo(pLeftVerge0.screenX, pLeftVerge0.screenY)
        ..lineTo(pLeftVerge1.screenX, pLeftVerge1.screenY)
        ..lineTo(pLeftRoad1.screenX, pLeftRoad1.screenY)
        ..lineTo(pLeftRoad0.screenX, pLeftRoad0.screenY)
        ..close();
      canvas.drawPath(leftVergePath, isAlt ? _vergePaint : _vergeAltPaint);

      // 2. Prawe pobocze
      final rightVergePath = Path()
        ..moveTo(pRightRoad0.screenX, pRightRoad0.screenY)
        ..lineTo(pRightRoad1.screenX, pRightRoad1.screenY)
        ..lineTo(pRightVerge1.screenX, pRightVerge1.screenY)
        ..lineTo(pRightVerge0.screenX, pRightVerge0.screenY)
        ..close();
      canvas.drawPath(rightVergePath, isAlt ? _vergePaint : _vergeAltPaint);

      // 3. Nawierzchnia jezdni (asfalt / bruk)
      _roadPaint.color = isAlt ? baseAsphalt : darkerAsphalt;
      final roadPath = Path()
        ..moveTo(pLeftRoad0.screenX, pLeftRoad0.screenY)
        ..lineTo(pLeftRoad1.screenX, pLeftRoad1.screenY)
        ..lineTo(pRightRoad1.screenX, pRightRoad1.screenY)
        ..lineTo(pRightRoad0.screenX, pRightRoad0.screenY)
        ..close();
      canvas.drawPath(roadPath, _roadPaint);

      // Mokry asfalt z odbiciami świetlnymi
      if (isWet) {
        canvas.drawPath(roadPath, _wetSheenPaint);
      }

      // 4. Białe linie krawędziowe jezdni
      final double lineWidth = (pCenter0.perspectiveScale * 3.2).clamp(1.0, 4.5);
      _edgeLinePaint.strokeWidth = lineWidth;
      canvas.drawLine(
        Offset(pLeftRoad0.screenX, pLeftRoad0.screenY),
        Offset(pLeftRoad1.screenX, pLeftRoad1.screenY),
        _edgeLinePaint,
      );
      canvas.drawLine(
        Offset(pRightRoad0.screenX, pRightRoad0.screenY),
        Offset(pRightRoad1.screenX, pRightRoad1.screenY),
        _edgeLinePaint,
      );

      // 5. Przerywana oś jezdni (co drugi segment, pomijana na brukach)
      if (isAlt && !surfaceProps.surfaceType.name.contains('cobble')) {
        _centerLinePaint.strokeWidth = lineWidth * 0.85;
        canvas.drawLine(
          Offset(pCenter0.screenX, pCenter0.screenY),
          Offset(pCenter1.screenX, pCenter1.screenY),
          _centerLinePaint,
        );
      }
    }

    // 6. Rysowanie malowanych haseł kibiców na asfalcie
    _drawGraffitiDecals(canvas, mesh.graffitiDecals, proj, eyePos);
  }

  void _drawGraffitiDecals(
    Canvas canvas,
    List<RoadMarkingDecal> decals,
    Scene3DMathProjection proj,
    Vector3 eyePos,
  ) {
    for (final decal in decals) {
      final dist = (decal.positionWorld - eyePos).length;
      if (dist > 140.0) continue;

      final pCenter = proj.worldToScreen(decal.positionWorld);
      if (!pCenter.isInFrontOfCamera || !pCenter.isInViewport) continue;

      final double scale = (pCenter.perspectiveScale * 14.0).clamp(0.4, 3.2);
      final Color decalColor = _parseHexColor(decal.colorHex, Colors.white).withValues(alpha: 0.85);

      final textSpan = TextSpan(
        text: decal.text,
        style: TextStyle(
          color: decalColor,
          fontSize: (11.0 * scale).clamp(8.0, 22.0),
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 2.0,
            ),
          ],
        ),
      );

      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(pCenter.screenX, pCenter.screenY);
      tp.paint(canvas, Offset(-tp.width * 0.5, -tp.height * 0.5));
      canvas.restore();
    }
  }

  Color _parseHexColor(String hexString, Color fallback) {
    try {
      String hex = hexString.replaceAll('#', '').trim();
      if (hex.length == 6) hex = 'FF$hex';
      if (hex.length == 8) return Color(int.parse(hex, radix: 16));
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  bool shouldRepaint(covariant _ZwiftStyle3DViewportPainter oldDelegate) {
    return true; // Płynne odświeżanie 60/120 FPS kontrolowane przez Ticker
  }
}

// =============================================================================
// MODALNY PANEL TELEMETRII I ROZKAZÓW TAKTYCZNYCH DLA KLIKNIĘTEGO KOLARZA
// =============================================================================

/// Dolny panel telemetrii i wydawania rozkazów taktycznych aktywowany kliknięciem
/// bezpośrednio na dowolnego kolarza w przestrzeni 3D.
class _RiderTacticalBottomSheet extends StatelessWidget {
  final RiderPositionSnapshot rider;
  final bool isPlayerTeam;
  final ValueChanged<TacticalOrder> onOrderSelected;
  final VoidCallback onTrackWithCamera;

  const _RiderTacticalBottomSheet({
    required this.rider,
    required this.isPlayerTeam,
    required this.onOrderSelected,
    required this.onTrackWithCamera,
  });

  @override
  Widget build(BuildContext context) {
    final powerZone = ((rider.powerWatts / 400.0) * 5.0).round().clamp(1, 7);
    final zoneColor = AppColors.getPowerZoneColor(powerZone);

    return Container(
      constraints: const BoxConstraints(maxWidth: 620),
      margin: const EdgeInsets.only(top: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF0F121C).withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: isPlayerTeam ? AppColors.goldAccent : AppColors.cardBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Uchwyt przesuwania (Drag handle)
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Nagłówek kolarza
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isPlayerTeam ? AppColors.goldAccent : const Color(0xFF262C3A),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isPlayerTeam ? Colors.white : Colors.white30,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        '#${rider.bibNumber}',
                        style: TextStyle(
                          color: isPlayerTeam ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                rider.riderName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isPlayerTeam
                                      ? AppColors.goldAccent.withValues(alpha: 0.2)
                                      : Colors.white10,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isPlayerTeam ? AppColors.goldAccent : Colors.white24,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  isPlayerTeam ? 'TWÓJ ZAWODNIK' : 'RYWAL',
                                  style: TextStyle(
                                    color: isPlayerTeam ? AppColors.goldAccent : Colors.white70,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rider.teamName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white60),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFF262C3A), height: 1),
                const SizedBox(height: 14),

                // Kafelki telemetrii na żywo (Live Stats Grid)
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.bolt_rounded,
                        label: 'MOC (COGGAN)',
                        value: '${rider.powerWatts} W',
                        subValue: '${rider.wattsPerKg.toStringAsFixed(1)} W/kg',
                        valueColor: zoneColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.speed_rounded,
                        label: 'PRĘDKOŚĆ',
                        value: '${rider.speedKmh.toStringAsFixed(1)} km/h',
                        subValue: '${rider.cadenceRpm} RPM',
                        valueColor: AppColors.cyanAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.favorite_rounded,
                        label: 'TĘTNO',
                        value: '${rider.heartRateBpm} bpm',
                        subValue: rider.isDrafting
                            ? '-${(rider.draftingSavingsPercent * 100).round()}% draft'
                            : 'Wiatr czołowy',
                        valueColor: rider.isDrafting ? const Color(0xFF10B981) : Colors.redAccent,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Paski energii: W' (beztlenowa) i Glikogen
                _buildPhysiologyBar(
                  label: 'ENERGIA BEZTLENOWA (W\')',
                  valuePercent: rider.wPrimePercentage,
                  valueText: '${(rider.wPrimeJoules / 1000.0).toStringAsFixed(1)} kJ (${(rider.wPrimePercentage * 100).round()}%)',
                  barColor: const Color(0xFF38BDF8),
                ),
                const SizedBox(height: 10),
                _buildPhysiologyBar(
                  label: 'ZAPAS GLIKOGENU',
                  valuePercent: rider.glycogenPercentage,
                  valueText: '${rider.glycogenGrams.round()} g (${(rider.glycogenPercentage * 100).round()}%)',
                  barColor: const Color(0xFF10B981),
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFF262C3A), height: 1),
                const SizedBox(height: 14),

                // Sekcja rozkazów taktycznych
                if (isPlayerTeam) ...[
                  const Text(
                    'ROZKAZY DYREKTORA SPORTOWEGO:',
                    style: TextStyle(
                      color: AppColors.goldAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TacticalOrder.values.map((order) {
                      final isActive = rider.activeTacticalOrder == order;
                      return _buildTacticalOrderButton(order, isActive);
                    }).toList(),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AKTUALNE ZACHOWANIE RYWALA:',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rider.activeTacticalOrder.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: onTrackWithCamera,
                        icon: const Icon(Icons.videocam_rounded, size: 16),
                        label: const Text('ŚLEDŹ KAMERĄ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyanAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required String subValue,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF161A26),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF262C3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: valueColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPhysiologyBar({
    required String label,
    required double valuePercent,
    required String valueText,
    required Color barColor,
  }) {
    final clamped = valuePercent.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              valueText,
              style: TextStyle(
                color: barColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clamped,
            backgroundColor: const Color(0xFF161A26),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildTacticalOrderButton(TacticalOrder order, bool isActive) {
    IconData icon;
    switch (order) {
      case TacticalOrder.attack:
        icon = Icons.flash_on_rounded;
        break;
      case TacticalOrder.pullGroup:
        icon = Icons.speed_rounded;
        break;
      case TacticalOrder.protectLeader:
        icon = Icons.shield_rounded;
        break;
      case TacticalOrder.followWheels:
        icon = Icons.track_changes_rounded;
        break;
      case TacticalOrder.fetchBidonsFromCar:
        icon = Icons.local_drink_rounded;
        break;
      case TacticalOrder.saveEnergy:
        icon = Icons.battery_charging_full_rounded;
        break;
      case TacticalOrder.holdPosition:
        icon = Icons.lock_clock_rounded;
        break;
    }

    return InkWell(
      onTap: () => onOrderSelected(order),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.goldAccent.withValues(alpha: 0.25) : const Color(0xFF161A26),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.goldAccent : const Color(0xFF2E3440),
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.goldAccent : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              order.label,
              style: TextStyle(
                color: isActive ? AppColors.goldAccent : Colors.white,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
