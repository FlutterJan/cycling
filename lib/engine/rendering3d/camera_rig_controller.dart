// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

import 'scene_3d_math_projection.dart';

/// Dostępne tryby kamer wyścigowych 3D.
enum RaceCameraMode {
  /// Kamera zza pleców wybranego kolarza (Zwift / MyWhoosh style).
  ///
  /// Dynamicznie obniża się i przybliża w trakcie sprintu i ataku, potęgując
  /// wrażenie pędu, pracy nóg w korbach i agresywnej sylwetki aerodynamicznej.
  chaseCam(
    label: 'Kamera zza Pleców (Chase Cam)',
    shortLabel: 'Za Plecami',
    description: 'Dynamiczne ujęcie zza pleców kolarza z widoczną pracą w korbach i obniżeniem w sprincie.',
  ),

  /// Kamera telewizyjna z motocykla transmisyjnego jadącego 8 metrów przed ucieczką lub peletonem.
  ///
  /// Kamera skierowana jest wstecz, filmując z bliska twarze, wysiłek i grymasy kolarzy.
  motoTvCam(
    label: 'Motocykl TV z Przodu (Moto TV Cam)',
    shortLabel: 'Motocykl TV',
    description: 'Dynamiczne ujęcie telewizyjne z motocykla jadącego 8 m przed czołem grupy.',
  ),

  /// Kamera panoramiczna z helikoptera realizatora transmisji (Heli Cam).
  ///
  /// Pokazuje z góry formowanie wachlarzy (echelons) na bocznych wiatrach i cały peleton.
  heliCam(
    label: 'Helikopter TV (Heli Cam)',
    shortLabel: 'Helikopter',
    description: 'Szeroka perspektywa z helikoptera ukazująca formowanie wachlarzy na wietrze.',
  ),

  /// Statyczna kamera na bramie mety (Finish Line Cam) ze zbliżeniem (zoom).
  ///
  /// Umieszczona na kratownicy bramy finiszowej, dynamicznie zawęża kąt widzenia (teleobiektyw)
  /// w miarę zbliżania się finiszujących sprinterów do kreski.
  finishLineCam(
    label: 'Brama Mety (Finish Line Cam)',
    shortLabel: 'Kreska Mety',
    description: 'Statyczna kamera na bramie mety z teleobiektywowym zoomem na finiszujących sprinterów.',
  );

  final String label;
  final String shortLabel;
  final String description;

  const RaceCameraMode({
    required this.label,
    required this.shortLabel,
    required this.description,
  });
}

/// Parametry konfiguracyjne kamery śledzącej zza pleców ([RaceCameraMode.chaseCam]).
class ChaseCamParameters {
  /// Dystans kamery za kolarzem w pozycji standardowej [m].
  final double distanceBack;

  /// Wysokość kamery nad pozycją kolarza w pozycji standardowej [m].
  final double heightAboveRider;

  /// Punkt skupienia wzroku kamery w przód przed kolarza [m].
  final double lookAheadDistance;

  /// Obniżenie pozycji kamery w trakcie sprintu / ataku [m].
  final double sprintHeightDrop;

  /// Zbliżenie kamery do kolarza w trakcie sprintu [m].
  final double sprintDistanceTuck;

  /// Zwiększenie kąta widzenia (FOV) podczas sprintu tworzące efekt prędkości [stopnie].
  final double sprintFovBoostDegrees;

  /// Boczne odsunięcie kamery (dla ujęć z ukosa) [m].
  final double lateralOffset;

  /// Czas wygładzania pozycji kamery w sekundach (Smooth Time).
  final double smoothTimeSeconds;

  const ChaseCamParameters({
    this.distanceBack = 4.6,
    this.heightAboveRider = 0.65,
    this.lookAheadDistance = 6.2,
    this.sprintHeightDrop = 0.35,
    this.sprintDistanceTuck = 0.70,
    this.sprintFovBoostDegrees = 4.5,
    this.lateralOffset = 0.0,
    this.smoothTimeSeconds = 0.18,
  });
}

/// Parametry konfiguracyjne motocykla TV ([RaceCameraMode.motoTvCam]).
class MotoTvCamParameters {
  /// Odległość motocykla przed czołowym kolarzem w metrach [m] (domyślnie 8.0m).
  final double leadDistanceMeters;

  /// Wysokość obiektywu motocykla nad asfaltem [m].
  final double heightMeters;

  /// Boczne odsunięcie motocykla, by nie zasłaniał centralnej osi kolarza [m].
  final double lateralOffsetMeters;

  /// Amplituda mikrodrgań kamery od pracy silnika motocykla i nierówności asfaltu [m].
  final double engineVibrationAmplitude;

  /// Czas wygładzania ruchu kamery [s].
  final double smoothTimeSeconds;

  const MotoTvCamParameters({
    this.leadDistanceMeters = 8.0,
    this.heightMeters = 1.65,
    this.lateralOffsetMeters = 1.25,
    this.engineVibrationAmplitude = 0.015,
    this.smoothTimeSeconds = 0.22,
  });
}

/// Parametry konfiguracyjne helikoptera ([RaceCameraMode.heliCam]).
class HeliCamParameters {
  /// Wysokość lotu helikoptera nad terenem [m].
  final double altitudeMeters;

  /// Promień orbity krążenia helikoptera wokół peletonu [m].
  final double orbitRadiusMeters;

  /// Prędkość kątowa krążenia wokół centrum grupy [rad/s].
  final double orbitAngularVelocity;

  /// Bazowy pionowy kąt widzenia obiektywu szerokokątnego [stopnie].
  final double baseFovDegrees;

  /// Czas wygładzania pozycji kamery [s].
  final double smoothTimeSeconds;

  const HeliCamParameters({
    this.altitudeMeters = 65.0,
    this.orbitRadiusMeters = 85.0,
    this.orbitAngularVelocity = 0.045,
    this.baseFovDegrees = 52.0,
    this.smoothTimeSeconds = 0.40,
  });
}

/// Parametry konfiguracyjne kamery na bramie mety ([RaceCameraMode.finishLineCam]).
class FinishLineCamParameters {
  /// Wysokość montażu obiektywu na kratownicy bramy mety [m].
  final double gantryHeightMeters;

  /// Dystans przed linią mety, w którym rozpoczyna się dynamiczne zbliżenie teleobiektywowe [m].
  final double zoomTriggerDistanceMeters;

  /// Szeroki kąt widzenia, gdy kolarze są daleko od mety [stopnie].
  final double wideFovDegrees;

  /// Wąski kąt teleobiektywowy (zoom) w kulminacyjnym momencie rzutu roweru na kreskę [stopnie].
  final double telephotoZoomFovDegrees;

  /// Czas wygładzania zbliżenia [s].
  final double smoothTimeSeconds;

  const FinishLineCamParameters({
    this.gantryHeightMeters = 5.6,
    this.zoomTriggerDistanceMeters = 180.0,
    this.wideFovDegrees = 44.0,
    this.telephotoZoomFovDegrees = 18.0,
    this.smoothTimeSeconds = 0.25,
  });
}

/// Kompletny kontroler kamer wyścigowych 3D (Camera Rig Controller).
///
/// Zarządza fizyką i interpolacją kamer wyścigu:
/// - Zapewnia płynne, krytycznie tłumione wygładzanie ruchu (Critically Damped Spring-Damper / SmoothDamp),
/// - Eliminuje mikrozacięcia, szarpania i niestabilności przy zmiennym FPS,
/// - Płynnie interpoluje przejścia (Blend Transition) między różnymi trybami kamer,
/// - Reaguje w locie na dynamikę sprintu i ataków kolarzy,
/// - Realizuje telewizyjny teleobiektyw (dynamic zoom) na kresce finiszowej.
class CameraRigController {
  RaceCameraMode _activeMode;
  RaceCameraMode? _previousMode;

  // Konfiguracje poszczególnych kamer
  ChaseCamParameters chaseParams;
  MotoTvCamParameters motoParams;
  HeliCamParameters heliParams;
  FinishLineCamParameters finishParams;

  // Bieżący stan wygładzonej kamery (Camera State)
  Vector3 _currentPosition = Vector3(0.0, 2.0, -10.0);
  Vector3 _currentTarget = Vector3(0.0, 1.2, 0.0);
  Vector3 _currentUp = Vector3(0.0, 1.0, 0.0);
  double _currentFovDegrees = 58.0;

  // Prędkości w układzie tłumionym Spring-Damper (Velocity State)
  final Vector3 _positionVelocity = Vector3.zero();
  final Vector3 _targetVelocity = Vector3.zero();
  double _fovVelocity = 0.0;

  // Stan płynnego przełączania trybów (Camera Mode Blend Transition)
  double _transitionProgress = 1.0; // 1.0 = brak aktywnego przejścia
  double _transitionDurationSeconds = 0.85;
  final Vector3 _transitionSourcePosition = Vector3.zero();
  final Vector3 _transitionSourceTarget = Vector3.zero();
  double _transitionSourceFov = 58.0;

  // Wewnętrzny stan rotacji i animacji helikoptera oraz wibracji silnika
  double _heliOrbitAngle = 0.0;
  double _engineVibrationPhase = 0.0;
  bool _isInitialized = false;

  // Ręczne obracanie i przybliżanie kamery gestami myszy i dotyku (Orbit & Pinch-to-Zoom)
  double _manualOrbitYaw = 0.0;
  double _manualOrbitPitch = 0.0;
  double _manualZoomScale = 1.0;

  CameraRigController({
    RaceCameraMode initialMode = RaceCameraMode.chaseCam,
    this.chaseParams = const ChaseCamParameters(),
    this.motoParams = const MotoTvCamParameters(),
    this.heliParams = const HeliCamParameters(),
    this.finishParams = const FinishLineCamParameters(),
    Vector3? initialPosition,
    Vector3? initialTarget,
    double initialFovDegrees = 58.0,
  })  : _activeMode = initialMode,
        _currentFovDegrees = initialFovDegrees {
    if (initialPosition != null) _currentPosition.setFrom(initialPosition);
    if (initialTarget != null) _currentTarget.setFrom(initialTarget);
  }

  // ===========================================================================
  // GETTERY STANU KAMERY
  // ===========================================================================

  /// Aktualnie aktywny tryb kamery.
  RaceCameraMode get activeMode => _activeMode;

  /// Poprzedni tryb przed rozpoczęciem płynnego przejścia (lub null).
  RaceCameraMode? get previousMode => _previousMode;

  /// Czy trwa płynna zmiana ujęcia (Camera Blend Transition).
  bool get isTransitioning => _transitionProgress < 1.0;

  /// Postęp przejścia między kamerami $[0.0, 1.0]$.
  double get transitionProgress => _transitionProgress;

  /// Wygładzona trójwymiarowa pozycja oka kamery $(X, Y, Z)$ [m].
  Vector3 get position => _currentPosition;

  /// Wygładzony punkt skupienia wzroku kamery (Look-At Target) $(X, Y, Z)$ [m].
  Vector3 get target => _currentTarget;

  /// Wektor kierunku góry kamery (Up Vector).
  Vector3 get up => _currentUp;

  /// Bieżący pionowy kąt widzenia w stopniach (Vertical Field of View).
  double get fovDegrees => _currentFovDegrees;

  /// Bieżący kąt widzenia w radianach.
  double get fovRadians => _currentFovDegrees * math.pi / 180.0;

  /// Generuje gotowy obiekt [Camera3DConfig] do przekazania do [Scene3DMathProjection].
  Camera3DConfig toCameraConfig({double nearPlane = 0.2, double farPlane = 3500.0}) {
    return Camera3DConfig(
      position: _currentPosition,
      target: _currentTarget,
      up: _currentUp,
      fovYDegrees: _currentFovDegrees,
      nearPlane: nearPlane,
      farPlane: farPlane,
    );
  }

  // ===========================================================================
  // INTERAKTYWNA KONTROLA GESTAMI (ORBIT, PAN, PINCH-TO-ZOOM)
  // ===========================================================================

  /// Kąt obrotu kamery w poziomie wokół kolarza w radianach (Yaw).
  double get manualOrbitYaw => _manualOrbitYaw;

  /// Kąt uniesienia kamery w pionie w radianach (Pitch).
  double get manualOrbitPitch => _manualOrbitPitch;

  /// Współczynnik powiększenia / przybliżenia kamery (Zoom Scale).
  double get manualZoomScale => _manualZoomScale;

  /// Dodaje przesunięcie kątowe obrotu i przybliżenia (np. z gestów myszy i dotyku).
  void addManualOrbit({
    double deltaYaw = 0.0,
    double deltaPitch = 0.0,
    double deltaZoom = 0.0,
  }) {
    _manualOrbitYaw = (_manualOrbitYaw + deltaYaw) % (2.0 * math.pi);
    _manualOrbitPitch = (_manualOrbitPitch + deltaPitch).clamp(-0.45, 0.65);
    _manualZoomScale = (_manualZoomScale + deltaZoom).clamp(0.40, 3.0);
  }

  /// Mnoży współczynnik powiększenia (np. z gestu szczypania / pinch-to-zoom).
  void multiplyZoom(double factor) {
    if (factor <= 0.0) return;
    _manualZoomScale = (_manualZoomScale * factor).clamp(0.40, 3.0);
  }

  /// Ustawia bezpośrednio parametry manualnego obrotu i zoomu.
  void setManualOrbit({
    double? yawRadians,
    double? pitchRadians,
    double? zoomScale,
  }) {
    if (yawRadians != null) _manualOrbitYaw = yawRadians % (2.0 * math.pi);
    if (pitchRadians != null) _manualOrbitPitch = pitchRadians.clamp(-0.45, 0.65);
    if (zoomScale != null) _manualZoomScale = zoomScale.clamp(0.40, 3.0);
  }

  /// Resetuje obrót i przybliżenie do domyślnej pozycji za plecami kolarza.
  void resetManualOrbit() {
    _manualOrbitYaw = 0.0;
    _manualOrbitPitch = 0.0;
    _manualZoomScale = 1.0;
  }

  // ===========================================================================
  // PRZEŁĄCZANIE TRYBÓW KAMERY
  // ===========================================================================

  /// Zmienia aktywny tryb kamery.
  ///
  /// - [newMode]: Docelowy tryb kamery.
  /// - [immediate]: Jeśli true, natychmiast przenosi kamerę bez animacji płynnego przejścia.
  /// - [transitionDurationSeconds]: Czas trwania przejścia w sekundach (domyślnie 0.85s).
  void switchMode(
    RaceCameraMode newMode, {
    bool immediate = false,
    double transitionDurationSeconds = 0.85,
  }) {
    if (newMode == _activeMode && !isTransitioning) return;

    if (immediate) {
      _activeMode = newMode;
      _previousMode = null;
      _transitionProgress = 1.0;
      _positionVelocity.setZero();
      _targetVelocity.setZero();
      _fovVelocity = 0.0;
      return;
    }

    _previousMode = _activeMode;
    _activeMode = newMode;
    _transitionProgress = 0.0;
    _transitionDurationSeconds = math.max(0.05, transitionDurationSeconds);

    // Zapamiętanie punktu startowego przejścia
    _transitionSourcePosition.setFrom(_currentPosition);
    _transitionSourceTarget.setFrom(_currentTarget);
    _transitionSourceFov = _currentFovDegrees;
  }

  /// Natychmiastowe ustawienie stanu kamery bez interpolacji (np. przy resecie wyścigu).
  void snapTo({
    required Vector3 position,
    required Vector3 target,
    Vector3? up,
    double? fovDegrees,
  }) {
    _currentPosition.setFrom(position);
    _currentTarget.setFrom(target);
    if (up != null) _currentUp.setFrom(up);
    if (fovDegrees != null) _currentFovDegrees = fovDegrees;

    _positionVelocity.setZero();
    _targetVelocity.setZero();
    _fovVelocity = 0.0;
    _transitionProgress = 1.0;
    _isInitialized = true;
  }

  // ===========================================================================
  // GŁÓWNA PĘTLA AKTUALIZACJI FIZYKI KAMERY (TICK / UPDATE)
  // ===========================================================================

  /// Aktualizuje stan kamery o krok czasowy [dtSeconds].
  ///
  /// Parametry wejściowe:
  /// - [dtSeconds]: Krok czasowy klatki w sekundach (np. 0.016 dla 60 FPS).
  /// - [targetRiderPose]: Pozycja i wektory bazy wybranego kolarza (dla ChaseCam i MotoTvCam).
  /// - [pelotonCentroid]: Środek ciężkości grupy peletonu (dla HeliCam).
  /// - [pelotonSpreadRadius]: Promień rozproszenia peletonu na szosie [m].
  /// - [finishLinePosition]: Pozycja bramy mety etapu (dla FinishLineCam).
  /// - [finishApproachDirection]: Wektor kierunku dojazdu do mety (np. [0, 0, 1]).
  /// - [isSprinting]: Czy obserwowany kolarz wykonuje maksymalny sprint finiszowy.
  /// - [isAttacking]: Czy kolarz jedzie agresywnym atakiem z ucieczki.
  /// - [riderSpeedMs]: Bieżąca prędkość kolarza w m/s (domyślnie 12.5 m/s ~ 45 km/h).
  void update({
    required double dtSeconds,
    required Cyclist3DPose targetRiderPose,
    Vector3? pelotonCentroid,
    double pelotonSpreadRadius = 15.0,
    Vector3? finishLinePosition,
    Vector3? finishApproachDirection,
    bool isSprinting = false,
    bool isAttacking = false,
    double riderSpeedMs = 12.5,
  }) {
    if (dtSeconds <= 0.0) return;
    // Ochrona przed dużymi przeskokami czasowymi przy zatrzymaniu okna
    final double safeDt = dtSeconds.clamp(0.001, 0.1);

    // 1. Obliczenie docelowej geometrii kamery dla wybranego trybu
    final targetRig = _computeTargetRigTransform(
      mode: _activeMode,
      targetRiderPose: targetRiderPose,
      pelotonCentroid: pelotonCentroid ?? targetRiderPose.position,
      pelotonSpreadRadius: pelotonSpreadRadius,
      finishLinePosition: finishLinePosition ?? (targetRiderPose.position + Vector3(0, 0, 500)),
      finishApproachDirection: finishApproachDirection ?? targetRiderPose.tangent,
      isSprinting: isSprinting,
      isAttacking: isAttacking,
      riderSpeedMs: riderSpeedMs,
      dtSeconds: safeDt,
    );

    // Błyskawiczna inicjalizacja na pierwszej klatce (brak szarpnięć przy starcie)
    if (!_isInitialized) {
      _currentPosition.setFrom(targetRig.position);
      _currentTarget.setFrom(targetRig.target);
      _currentUp.setFrom(targetRig.up);
      _currentFovDegrees = targetRig.fovYDegrees;
      _positionVelocity.setZero();
      _targetVelocity.setZero();
      _fovVelocity = 0.0;
      _isInitialized = true;
      return;
    }

    // 2. Obsługa płynnego przejścia między trybami (Camera Blend Transition)
    Vector3 desiredEye = targetRig.position;
    Vector3 desiredTarget = targetRig.target;
    Vector3 desiredUp = targetRig.up;
    double desiredFov = targetRig.fovYDegrees;
    double activeSmoothTime = targetRig.smoothTimeSeconds;

    if (_transitionProgress < 1.0) {
      _transitionProgress = (_transitionProgress + (safeDt / _transitionDurationSeconds)).clamp(0.0, 1.0);
      // Płynna krzywa Quintic Ease-In-Out: 6t^5 - 15t^4 + 10t^3
      final double t = _transitionProgress;
      final double smoothT = t * t * t * (t * (t * 6.0 - 15.0) + 10.0);

      desiredEye = _vectorLerp(_transitionSourcePosition, desiredEye, smoothT);
      desiredTarget = _vectorLerp(_transitionSourceTarget, desiredTarget, smoothT);
      desiredFov = _scalarLerp(_transitionSourceFov, desiredFov, smoothT);
    }

    // 3. Wygładzanie ruchu przy użyciu krytycznie tłumionego układu sprężyna-tłumik (SmoothDamp)
    _currentPosition = _smoothDampVector(
      current: _currentPosition,
      target: desiredEye,
      velocity: _positionVelocity,
      smoothTime: activeSmoothTime,
      dt: safeDt,
    );

    _currentTarget = _smoothDampVector(
      current: _currentTarget,
      target: desiredTarget,
      velocity: _targetVelocity,
      smoothTime: activeSmoothTime * 0.85, // Punkt skupienia podąża nieco szybciej
      dt: safeDt,
    );

    _currentFovDegrees = _smoothDampScalar(
      current: _currentFovDegrees,
      target: desiredFov,
      velocityRef: _fovVelocity,
      onVelocityUpdated: (newVel) => _fovVelocity = newVel,
      smoothTime: activeSmoothTime * 1.2,
      dt: safeDt,
    );

    // Płynna interpolacja wektora Up
    _currentUp = (_currentUp + (desiredUp - _currentUp) * (safeDt * 6.0).clamp(0.0, 1.0))..normalize();
  }

  // ===========================================================================
  // DEDYKOWANE OBLICZENIA TRANSFORMACJI DLA POSZCZEGÓLNYCH KAMER
  // ===========================================================================

  _RigGoal _computeTargetRigTransform({
    required RaceCameraMode mode,
    required Cyclist3DPose targetRiderPose,
    required Vector3 pelotonCentroid,
    required double pelotonSpreadRadius,
    required Vector3 finishLinePosition,
    required Vector3 finishApproachDirection,
    required bool isSprinting,
    required bool isAttacking,
    required double riderSpeedMs,
    required double dtSeconds,
  }) {
    switch (mode) {
      case RaceCameraMode.chaseCam:
        return _computeChaseCam(
          riderPose: targetRiderPose,
          isSprinting: isSprinting,
          isAttacking: isAttacking,
          speedMs: riderSpeedMs,
        );

      case RaceCameraMode.motoTvCam:
        return _computeMotoTvCam(
          riderPose: targetRiderPose,
          dtSeconds: dtSeconds,
        );

      case RaceCameraMode.heliCam:
        return _computeHeliCam(
          pelotonCentroid: pelotonCentroid,
          pelotonSpreadRadius: pelotonSpreadRadius,
          dtSeconds: dtSeconds,
        );

      case RaceCameraMode.finishLineCam:
        return _computeFinishLineCam(
          leadRiderPosition: targetRiderPose.position,
          finishLinePosition: finishLinePosition,
          approachDirection: finishApproachDirection,
        );
    }
  }

  /// 1. CHASE CAM: Kamera zza pleców kolarza z obniżeniem w sprincie i ataku.
  _RigGoal _computeChaseCam({
    required Cyclist3DPose riderPose,
    required bool isSprinting,
    required bool isAttacking,
    required double speedMs,
  }) {
    final Vector3 pos = riderPose.position;
    final Vector3 tangent = riderPose.tangent;
    final Vector3 normal = riderPose.surfaceNormal;
    final Vector3 right = riderPose.lateralRight;

    final bool isAggressiveMode = isSprinting || isAttacking || speedMs > 15.5; // > ~56 km/h

    // Dynamiczne obniżenie kamery i przybliżenie do ramy z uwzględnieniem zoomu
    final double baseDist = isAggressiveMode
        ? (chaseParams.distanceBack - chaseParams.sprintDistanceTuck)
        : chaseParams.distanceBack;
    final double distBack = baseDist * _manualZoomScale.clamp(0.40, 3.0);

    final double heightAbove = (isAggressiveMode
        ? (chaseParams.heightAboveRider - chaseParams.sprintHeightDrop)
        : chaseParams.heightAboveRider) + (_manualOrbitPitch * 2.2);

    // Podbicie FOV dla uczucia prędkości (speed zoom)
    final double targetFov = 58.0 + (isAggressiveMode ? chaseParams.sprintFovBoostDegrees : 0.0);

    // Dynamiczny obrót kamery wokół kolarza (manual orbit yaw)
    final double cosYaw = math.cos(_manualOrbitYaw);
    final double sinYaw = math.sin(_manualOrbitYaw);
    final Vector3 rotatedDir = (-tangent * cosYaw) + (right * sinYaw);

    // Pozycja oka kamery z uwzględnieniem ewentualnego przesunięcia bocznego
    final Vector3 eye = pos + (rotatedDir * distBack) + (normal * (1.10 + heightAbove)) + (right * chaseParams.lateralOffset);

    // Punkt skupienia wzroku (kierownica / głowa z wyprzedzeniem wzroku w przód)
    final double lookAhead = isAggressiveMode ? (chaseParams.lookAheadDistance + 1.5) : chaseParams.lookAheadDistance;
    final Vector3 target = pos + (tangent * lookAhead) + (normal * 0.90);

    return _RigGoal(
      position: eye,
      target: target,
      up: normal,
      fovYDegrees: targetFov,
      smoothTimeSeconds: chaseParams.smoothTimeSeconds,
    );
  }

  /// 2. MOTO TV CAM: Kamera z motocykla telewizyjnego jadącego 8 metrów przed ucieczką.
  _RigGoal _computeMotoTvCam({
    required Cyclist3DPose riderPose,
    required double dtSeconds,
  }) {
    final Vector3 pos = riderPose.position;
    final Vector3 tangent = riderPose.tangent;
    final Vector3 normal = riderPose.surfaceNormal;
    final Vector3 right = riderPose.lateralRight;

    // Przesunięcie motocykla: dokładnie 8 metrów z przodu wzdłuż wektora jazdy
    final double leadDist = motoParams.leadDistanceMeters;
    final double height = motoParams.heightMeters;
    final double latOffset = motoParams.lateralOffsetMeters;

    // Generowanie subtelnych drgań kamery od pracy silnika motocykla i chropowatości szosy
    _engineVibrationPhase = (_engineVibrationPhase + (dtSeconds * 28.0)) % (2.0 * math.pi);
    final double vibY = math.sin(_engineVibrationPhase) * motoParams.engineVibrationAmplitude;
    final double vibX = math.cos(_engineVibrationPhase * 1.5) * (motoParams.engineVibrationAmplitude * 0.6);

    final Vector3 eye = pos + (tangent * leadDist) + (normal * (height + vibY)) + (right * (latOffset + vibX));

    // Kamera patrzy wstecz na klatkę piersiową i twarz kolarza
    final Vector3 target = pos + (normal * 1.18);

    return _RigGoal(
      position: eye,
      target: target,
      up: normal,
      fovYDegrees: 54.0, // Lekko węższy obiektyw telewizyjny
      smoothTimeSeconds: motoParams.smoothTimeSeconds,
    );
  }

  /// 3. HELI CAM: Panoramiczna perspektywa z helikoptera ukazująca formowanie wachlarzy.
  _RigGoal _computeHeliCam({
    required Vector3 pelotonCentroid,
    required double pelotonSpreadRadius,
    required double dtSeconds,
  }) {
    // Ciągły powolny obrót helikoptera po orbicie
    _heliOrbitAngle = (_heliOrbitAngle + (heliParams.orbitAngularVelocity * dtSeconds)) % (2.0 * math.pi);

    final double radius = math.max(heliParams.orbitRadiusMeters, pelotonSpreadRadius * 2.2);
    final double altitude = heliParams.altitudeMeters;

    final double eyeX = pelotonCentroid.x + (math.sin(_heliOrbitAngle) * radius);
    final double eyeZ = pelotonCentroid.z + (math.cos(_heliOrbitAngle) * radius);
    final double eyeY = pelotonCentroid.y + altitude;

    final Vector3 eye = Vector3(eyeX, eyeY, eyeZ);
    // Punkt skupienia na środku formacji peletonu / wachlarza
    final Vector3 target = pelotonCentroid + Vector3(0.0, 1.0, 0.0);

    return _RigGoal(
      position: eye,
      target: target,
      up: Vector3(0.0, 1.0, 0.0),
      fovYDegrees: heliParams.baseFovDegrees,
      smoothTimeSeconds: heliParams.smoothTimeSeconds,
    );
  }

  /// 4. FINISH LINE CAM: Statyczna kamera na bramie mety z teleobiektywowym zoomem.
  _RigGoal _computeFinishLineCam({
    required Vector3 leadRiderPosition,
    required Vector3 finishLinePosition,
    required Vector3 approachDirection,
  }) {
    final normApproach = Vector3.copy(approachDirection)..normalize();

    // Kamera zamontowana centralnie na kratownicy bramy mety, lekko wysunięta w stronę dojazdu
    final double gantryH = finishParams.gantryHeightMeters;
    final Vector3 eye = finishLinePosition + Vector3(0.0, gantryH, 0.0) + (normApproach * 0.4);

    // Odległość kolarzy od linii mety
    final double distanceToFinish = (leadRiderPosition - finishLinePosition).length;

    // Teleobiektywowy zoom: w miarę jak kolarze zbliżają się do kreski, FOV maleje z 44° do 18°
    final double zoomProgress = (1.0 - (distanceToFinish / finishParams.zoomTriggerDistanceMeters)).clamp(0.0, 1.0);
    final double dynamicFov = _scalarLerp(
      finishParams.wideFovDegrees,
      finishParams.telephotoZoomFovDegrees,
      zoomProgress,
    );

    // Cel kamery śledzi zbliżającego się sprintera z rzutem roweru na kreskę
    final Vector3 target = leadRiderPosition + Vector3(0.0, 0.95, 0.0);

    return _RigGoal(
      position: eye,
      target: target,
      up: Vector3(0.0, 1.0, 0.0),
      fovYDegrees: dynamicFov,
      smoothTimeSeconds: finishParams.smoothTimeSeconds,
    );
  }

  // ===========================================================================
  // MATEMATYKA WYGŁADZANIA RUCHU (CRITICALLY DAMPED SPRING-DAMPER)
  // ===========================================================================

  /// Analityczne rozwiązanie równania ruchu układu krytycznie tłumionego dla Vector3 (SmoothDamp).
  ///
  /// Zapewnia zero oscylacji (brak przestrzeliwania celu) i stabilność numeryczną.
  static Vector3 _smoothDampVector({
    required Vector3 current,
    required Vector3 target,
    required Vector3 velocity,
    required double smoothTime,
    required double dt,
  }) {
    final double safeSmoothTime = math.max(0.0001, smoothTime);
    final double omega = 2.0 / safeSmoothTime;
    final double x = omega * dt;
    final double exp = 1.0 / (1.0 + x + (0.48 * x * x) + (0.235 * x * x * x));

    final Vector3 change = current - target;
    final Vector3 temp = (velocity + (change * omega)) * dt;

    velocity.setFrom((velocity - (temp * omega)) * exp);
    return target + ((change + temp) * exp);
  }

  /// Wygładzanie pojedynczej wielkości skalarnej (np. kąta FOV).
  static double _smoothDampScalar({
    required double current,
    required double target,
    required double velocityRef,
    required void Function(double newVel) onVelocityUpdated,
    required double smoothTime,
    required double dt,
  }) {
    final double safeSmoothTime = math.max(0.0001, smoothTime);
    final double omega = 2.0 / safeSmoothTime;
    final double x = omega * dt;
    final double exp = 1.0 / (1.0 + x + (0.48 * x * x) + (0.235 * x * x * x));

    final double change = current - target;
    final double temp = (velocityRef + (omega * change)) * dt;
    final double newVelocity = (velocityRef - (omega * temp)) * exp;
    onVelocityUpdated(newVelocity);

    return target + ((change + temp) * exp);
  }

  static Vector3 _vectorLerp(Vector3 a, Vector3 b, double t) {
    return Vector3(
      a.x + (b.x - a.x) * t,
      a.y + (b.y - a.y) * t,
      a.z + (b.z - a.z) * t,
    );
  }

  static double _scalarLerp(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

/// Pomocnicza struktura reprezentująca cel docelowy kamery przed wygładzeniem.
class _RigGoal {
  final Vector3 position;
  final Vector3 target;
  final Vector3 up;
  final double fovYDegrees;
  final double smoothTimeSeconds;

  const _RigGoal({
    required this.position,
    required this.target,
    required this.up,
    required this.fovYDegrees,
    required this.smoothTimeSeconds,
  });
}
