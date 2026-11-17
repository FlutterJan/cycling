// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../rendering3d/camera_rig_controller.dart';
import 'procedural_cycling_audio_engine.dart';

/// Kategoria przestrzennego źródła dźwięku w wyścigu kolarskim 3D.
enum SpatialAudioSourceCategory {
  /// Szum kół karbonowych, bębenki wolnobiegu i oddechy peletonu.
  peloton(
    label: 'Peleton',
    shortLabel: 'PEL',
    accentColor: AppColors.accentBlue,
    defaultReferenceDistance: 6.0,
    defaultMaxDistance: 180.0,
    defaultRolloff: 1.15,
    defaultSpreadRadius: 7.5,
  ),

  /// Wozy techniczne dyrektorów sportowych i neutralne wsparcie Shimano/Mavic.
  teamCar(
    label: 'Wóz techniczny',
    shortLabel: 'CAR',
    accentColor: AppColors.goldAccent,
    defaultReferenceDistance: 5.0,
    defaultMaxDistance: 220.0,
    defaultRolloff: 1.10,
    defaultSpreadRadius: 2.2,
  ),

  /// Motocykle transmisyjne TV oraz sędziowskie.
  motoCamera(
    label: 'Motocykl TV',
    shortLabel: 'MOTO',
    accentColor: AppColors.cyanAccent,
    defaultReferenceDistance: 4.5,
    defaultMaxDistance: 160.0,
    defaultRolloff: 1.25,
    defaultSpreadRadius: 1.8,
  ),

  /// Kibice przy barierkach, szpalery górskie i dzwonki krów na poboczu.
  spectatorCrowd(
    label: 'Kibice i barierki',
    shortLabel: 'FAN',
    accentColor: AppColors.primaryAccent,
    defaultReferenceDistance: 8.0,
    defaultMaxDistance: 260.0,
    defaultRolloff: 0.95,
    defaultSpreadRadius: 12.0,
  ),

  /// Śmigłowiec realizatora transmisji TV krążący nad trasą.
  helicopter(
    label: 'Helikopter TV',
    shortLabel: 'HELI',
    accentColor: AppColors.statusSuccess,
    defaultReferenceDistance: 22.0,
    defaultMaxDistance: 420.0,
    defaultRolloff: 0.75,
    defaultSpreadRadius: 18.0,
  );

  final String label;
  final String shortLabel;
  final Color accentColor;
  final double defaultReferenceDistance;
  final double defaultMaxDistance;
  final double defaultRolloff;
  final double defaultSpreadRadius;

  const SpatialAudioSourceCategory({
    required this.label,
    required this.shortLabel,
    required this.accentColor,
    required this.defaultReferenceDistance,
    required this.defaultMaxDistance,
    required this.defaultRolloff,
    required this.defaultSpreadRadius,
  });
}

/// Prawo panoramowania stereo używane przy mapowaniu kąta azymutu na kanały L/R.
enum SpatialPanningLaw {
  /// Stała moc ($L^2 + R^2 = 1$, krzywa $\cos/\sin$) — naturalne brzmienie w słuchawkach i na głośnikach.
  equalPower('Equal Power (-3 dB)'),

  /// Liniowe przejście między kanałami ($L = (1 - p)/2, R = (1 + p)/2$).
  linear('Liniowe (-6 dB)'),

  /// Krzywa pierwiastkowa ($\sqrt{(1 \mp p)/2}$) dla gęstych źródeł tłumu.
  sqrtPower('Pierwiastkowe (Sqrt)');

  final String label;
  const SpatialPanningLaw(this.label);
}

/// Trójwymiarowa konfiguracja słuchacza powiązana z pozycją i orientacją kamery 3D.
class SpatialAudioListener3D {
  /// Pozycja oka kamery / mikrofonu w przestrzeni świata $(X, Y, Z)$ [m].
  final Vector3 position;

  /// Znormalizowany wektor kierunku patrzenia kamery (Forward).
  final Vector3 forward;

  /// Znormalizowany wektor prawej strony kamery (Right).
  final Vector3 right;

  /// Znormalizowany wektor góry kamery (Up).
  final Vector3 up;

  /// Wektor prędkości kamery [m/s] (do obliczeń efektu Dopplera).
  final Vector3 velocity;

  /// Aktywny tryb kamery wyścigowej wpływający na profil akustyczny.
  final RaceCameraMode cameraMode;

  /// Pionowy kąt widzenia kamery [stopnie].
  final double fovDegrees;

  const SpatialAudioListener3D._({
    required this.position,
    required this.forward,
    required this.right,
    required this.up,
    required this.velocity,
    required this.cameraMode,
    required this.fovDegrees,
  });

  /// Buduje słuchacza na podstawie punktu kamery oraz punktu skupienia wzroku (`lookAt`).
  factory SpatialAudioListener3D.fromLookAt({
    required Vector3 position,
    required Vector3 target,
    Vector3? up,
    Vector3? velocity,
    RaceCameraMode cameraMode = RaceCameraMode.chaseCam,
    double fovDegrees = 58.0,
  }) {
    final worldUp = (up != null && up.length2 > 1e-8)
        ? up.normalized()
        : Vector3(0.0, 1.0, 0.0);

    final rawForward = target - position;
    final Vector3 fwd = rawForward.length2 > 1e-8
        ? rawForward.normalized()
        : Vector3(0.0, 0.0, 1.0);

    // W układzie prawoskrętnym: right = forward x worldUp
    Vector3 rgt = fwd.cross(worldUp);
    if (rgt.length2 <= 1e-8) {
      // Kamera patrzy niemal pionowo w dół/górę (np. Heli Cam nad peletonem)
      rgt = fwd.cross(Vector3(0.0, 0.0, 1.0));
      if (rgt.length2 <= 1e-8) {
        rgt = Vector3(1.0, 0.0, 0.0);
      }
    }
    rgt.normalize();

    final orthoUp = rgt.cross(fwd).normalized();

    return SpatialAudioListener3D._(
      position: position.clone(),
      forward: fwd,
      right: rgt,
      up: orthoUp,
      velocity: velocity?.clone() ?? Vector3.zero(),
      cameraMode: cameraMode,
      fovDegrees: fovDegrees.clamp(12.0, 120.0),
    );
  }

  /// Tworzy słuchacza bezpośrednio z kontrolera kamery [CameraRigController].
  factory SpatialAudioListener3D.fromCameraRig(
    CameraRigController rig, {
    Vector3? velocity,
  }) {
    return SpatialAudioListener3D.fromLookAt(
      position: rig.position,
      target: rig.target,
      up: rig.up,
      velocity: velocity,
      cameraMode: rig.activeMode,
      fovDegrees: rig.fovDegrees,
    );
  }

  SpatialAudioListener3D copyWith({
    Vector3? position,
    Vector3? target,
    Vector3? up,
    Vector3? velocity,
    RaceCameraMode? cameraMode,
    double? fovDegrees,
  }) {
    if (target != null || position != null || up != null) {
      return SpatialAudioListener3D.fromLookAt(
        position: position ?? this.position,
        target: target ?? (this.position + forward),
        up: up ?? this.up,
        velocity: velocity ?? this.velocity,
        cameraMode: cameraMode ?? this.cameraMode,
        fovDegrees: fovDegrees ?? this.fovDegrees,
      );
    }
    return SpatialAudioListener3D._(
      position: this.position.clone(),
      forward: forward.clone(),
      right: right.clone(),
      up: this.up.clone(),
      velocity: velocity?.clone() ?? this.velocity.clone(),
      cameraMode: cameraMode ?? this.cameraMode,
      fovDegrees: (fovDegrees ?? this.fovDegrees).clamp(12.0, 120.0),
    );
  }
}

/// Definicja źródła dźwięku w przestrzeni 3D wyścigu.
class SpatialAudioSource3D {
  final String id;
  final String label;
  final SpatialAudioSourceCategory category;

  /// Pozycja źródła w przestrzeni świata $(X, Y, Z)$ [m].
  final Vector3 position;

  /// Wektor prędkości źródła [m/s].
  final Vector3 velocity;

  /// Wzmocnienie bazowe źródła $[0.0, 2.0]$.
  final double baseGain;

  /// Dystans referencyjny pełnej głośności [m].
  final double referenceDistanceMeters;

  /// Maksymalny dystans słyszalności [m].
  final double maxDistanceMeters;

  /// Wykładnik tłumienia wraz z odległością (Rolloff Factor).
  final double rolloffFactor;

  /// Współczynnik efektu Dopplera ($0.0$ = brak, $1.0$ = fizyczny).
  final double dopplerFactor;

  /// Promień rozciągłości przestrzennej źródła [m] (łagodzi twarde panoramowanie wewnątrz grupy).
  final double spreadRadiusMeters;

  /// Czy źródło jest wyciszone.
  final bool isMuted;

  SpatialAudioSource3D({
    required this.id,
    required this.label,
    required this.category,
    required this.position,
    Vector3? velocity,
    this.baseGain = 1.0,
    double? referenceDistanceMeters,
    double? maxDistanceMeters,
    double? rolloffFactor,
    this.dopplerFactor = 1.0,
    double? spreadRadiusMeters,
    this.isMuted = false,
  })  : velocity = velocity ?? Vector3.zero(),
        referenceDistanceMeters = referenceDistanceMeters ??
            (category == SpatialAudioSourceCategory.peloton
                ? 6.0
                : category == SpatialAudioSourceCategory.teamCar
                    ? 5.0
                    : category == SpatialAudioSourceCategory.motoCamera
                        ? 4.5
                        : category == SpatialAudioSourceCategory.spectatorCrowd
                            ? 8.0
                            : 22.0),
        maxDistanceMeters = maxDistanceMeters ??
            (category == SpatialAudioSourceCategory.peloton
                ? 180.0
                : category == SpatialAudioSourceCategory.teamCar
                    ? 220.0
                    : category == SpatialAudioSourceCategory.motoCamera
                        ? 160.0
                        : category == SpatialAudioSourceCategory.spectatorCrowd
                            ? 260.0
                            : 420.0),
        rolloffFactor = rolloffFactor ??
            (category == SpatialAudioSourceCategory.peloton
                ? 1.15
                : category == SpatialAudioSourceCategory.teamCar
                    ? 1.10
                    : category == SpatialAudioSourceCategory.motoCamera
                        ? 1.25
                        : category == SpatialAudioSourceCategory.spectatorCrowd
                            ? 0.95
                            : 0.75),
        spreadRadiusMeters = spreadRadiusMeters ??
            (category == SpatialAudioSourceCategory.peloton
                ? 7.5
                : category == SpatialAudioSourceCategory.teamCar
                    ? 2.2
                    : category == SpatialAudioSourceCategory.motoCamera
                        ? 1.8
                        : category == SpatialAudioSourceCategory.spectatorCrowd
                            ? 12.0
                            : 18.0);

  SpatialAudioSource3D copyWith({
    String? id,
    String? label,
    SpatialAudioSourceCategory? category,
    Vector3? position,
    Vector3? velocity,
    double? baseGain,
    double? referenceDistanceMeters,
    double? maxDistanceMeters,
    double? rolloffFactor,
    double? dopplerFactor,
    double? spreadRadiusMeters,
    bool? isMuted,
  }) {
    return SpatialAudioSource3D(
      id: id ?? this.id,
      label: label ?? this.label,
      category: category ?? this.category,
      position: position ?? this.position.clone(),
      velocity: velocity ?? this.velocity.clone(),
      baseGain: baseGain ?? this.baseGain,
      referenceDistanceMeters:
          referenceDistanceMeters ?? this.referenceDistanceMeters,
      maxDistanceMeters: maxDistanceMeters ?? this.maxDistanceMeters,
      rolloffFactor: rolloffFactor ?? this.rolloffFactor,
      dopplerFactor: dopplerFactor ?? this.dopplerFactor,
      spreadRadiusMeters: spreadRadiusMeters ?? this.spreadRadiusMeters,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

/// Wynik obliczeń przestrzennego panoramowania stereo dla pojedynczego źródła 3D.
class SpatialSourcePanResult {
  final String sourceId;
  final SpatialAudioSourceCategory category;

  /// Odległość euklidesowa od kamery [m].
  final double distanceMeters;

  /// Kąt azymutu w płaszczyźnie poziomej kamery $[-\pi, \pi]$ (0 = przód, $+\pi/2$ = prawo).
  final double azimuthRadians;

  /// Kąt elewacji $[-\pi/2, \pi/2]$ (dodatni = źródło powyżej kamery).
  final double elevationRadians;

  /// Znormalizowana pozycja w panoramie stereo $[-1.0, +1.0]$ (-1 = lewy kanał, +1 = prawy).
  final double pan;

  /// Wypadkowe wzmocnienie lewego kanału $[0.0, 2.0]$.
  final double leftGain;

  /// Wypadkowe wzmocnienie prawego kanału $[0.0, 2.0]$.
  final double rightGain;

  /// Tłumienie wynikające z odległości $[0.0, 1.0]$.
  final double distanceAttenuation;

  /// Współczynnik absorpcji wysokich częstotliwości przez powietrze $[0.0, 1.0]$ (1.0 = brak strat).
  final double airAbsorptionFactor;

  /// Stosunek częstotliwości Dopplera $f'/f$ ($>1.0$ = zbliżanie, $<1.0$ = oddalanie).
  final double dopplerPitchRatio;

  /// Czy źródło znajduje się poza zasięgiem lub jest wyciszone (pominięte w miksie).
  final bool isCulled;

  const SpatialSourcePanResult({
    required this.sourceId,
    required this.category,
    required this.distanceMeters,
    required this.azimuthRadians,
    required this.elevationRadians,
    required this.pan,
    required this.leftGain,
    required this.rightGain,
    required this.distanceAttenuation,
    required this.airAbsorptionFactor,
    required this.dopplerPitchRatio,
    required this.isCulled,
  });

  /// Wypadkowa energia mono dla podglądu miernika poziomu.
  double get combinedGain =>
      math.sqrt(((leftGain * leftGain) + (rightGain * rightGain)) * 0.5);
}

/// Silnik przestrzennego panoramowania stereo dźwięku 3D dla peletonu, wozów technicznych i kibiców.
class Spatial3dPelotonAudioPanner {
  /// Prędkość dźwięku w powietrzu przy 20°C [m/s].
  static const double speedOfSoundMs = 343.0;

  final SpatialPanningLaw panningLaw;
  final double masterGain;
  final bool dopplerEnabled;
  final bool airAbsorptionEnabled;

  const Spatial3dPelotonAudioPanner({
    this.panningLaw = SpatialPanningLaw.equalPower,
    this.masterGain = 1.0,
    this.dopplerEnabled = true,
    this.airAbsorptionEnabled = true,
  });

  /// Oblicza parametry panoramowania stereo i tłumienia 3D dla zadanego źródła względem kamery.
  SpatialSourcePanResult computeSourcePan({
    required SpatialAudioSource3D source,
    required SpatialAudioListener3D listener,
  }) {
    final delta = source.position - listener.position;
    final distance = delta.length;

    final maxDist = math.max(1.0, source.maxDistanceMeters);
    if (source.isMuted || source.baseGain <= 0.0 || distance >= maxDist) {
      return SpatialSourcePanResult(
        sourceId: source.id,
        category: source.category,
        distanceMeters: distance,
        azimuthRadians: 0.0,
        elevationRadians: 0.0,
        pan: 0.0,
        leftGain: 0.0,
        rightGain: 0.0,
        distanceAttenuation: 0.0,
        airAbsorptionFactor: 0.0,
        dopplerPitchRatio: 1.0,
        isCulled: true,
      );
    }

    // Kierunek od słuchacza do źródła
    final Vector3 dir = distance > 1e-5 ? (delta / distance) : listener.forward;

    // Rzutowanie na bazę kamery (Right, Forward, Up)
    final double rightDot = dir.dot(listener.right).clamp(-1.0, 1.0);
    final double forwardDot = dir.dot(listener.forward).clamp(-1.0, 1.0);
    final double upDot = dir.dot(listener.up).clamp(-1.0, 1.0);

    final double azimuth = math.atan2(rightDot, forwardDot);
    final double elevation = math.asin(upDot);

    // Rozpiętość źródła: blisko lub wewnątrz peletonu/tłumu łagodzimy twarde panoramowanie
    final double spread = math.max(0.0, source.spreadRadiusMeters);
    final double spreadBlend =
        spread > 0.0 ? (distance / (distance + spread)).clamp(0.0, 1.0) : 1.0;

    // Delikatne przytłumienie tylnej półsfery (efekt małżowiny usznej / kamery kierunkowej)
    final double rearAttenuation =
        forwardDot < 0.0 ? (1.0 + (forwardDot * 0.16)).clamp(0.84, 1.0) : 1.0;

    final double rawPan = rightDot * spreadBlend;
    final double pan = rawPan.clamp(-1.0, 1.0);

    // Wyliczenie współczynników L/R według wybranego prawa panoramy
    final (double panL, double panR) = _computePanWeights(pan, panningLaw);

    // Tłumienie dystansowe (Inverse Distance Clamped + płynny rolloff przed maxDistance)
    final double refDist = math.max(0.5, source.referenceDistanceMeters);
    final double clampedDist = math.max(distance, refDist);
    final double inverseAtten = refDist /
        (refDist + source.rolloffFactor * (clampedDist - refDist));

    // Płynne wygaszenie na ostatnich 15% maksymalnego dystansu (brak nagłego ucięcia)
    final double fadeStart = maxDist * 0.85;
    final double edgeFade = distance > fadeStart
        ? (1.0 - ((distance - fadeStart) / (maxDist - fadeStart)))
            .clamp(0.0, 1.0)
        : 1.0;

    // Wzmocnienie zależne od trybu kamery 3D (np. w Helikopterze mocniejszy heli i szeroki tłum)
    final double modeGainMultiplier =
        _cameraModeCategoryWeight(listener.cameraMode, source.category);

    final double distanceAtten =
        (inverseAtten * edgeFade * rearAttenuation).clamp(0.0, 1.0);
    final double effectiveGain = (source.baseGain *
            distanceAtten *
            modeGainMultiplier *
            masterGain)
        .clamp(0.0, 2.0);

    final double leftGain = (panL * effectiveGain).clamp(0.0, 2.0);
    final double rightGain = (panR * effectiveGain).clamp(0.0, 2.0);

    // Absorpcja wysokich częstotliwości przez powietrze (~0.35 dB / 100m w uproszczeniu)
    final double airAbsorption = airAbsorptionEnabled
        ? math.exp(-0.0042 * distance).clamp(0.15, 1.0)
        : 1.0;

    // Efekt Dopplera wzdłuż osi łączącej słuchacza i źródło
    double dopplerRatio = 1.0;
    if (dopplerEnabled && source.dopplerFactor > 0.0 && distance > 0.25) {
      final double vListenerAlongDir = listener.velocity.dot(dir);
      final double vSourceAlongDir = source.velocity.dot(dir);
      // Gdy źródło zbliża się do kamery, vSourceAlongDir < 0 => mianownik maleje => pitch rośnie
      final double num =
          (speedOfSoundMs + (vListenerAlongDir * source.dopplerFactor))
              .clamp(220.0, 460.0);
      final double den =
          (speedOfSoundMs + (vSourceAlongDir * source.dopplerFactor))
              .clamp(220.0, 460.0);
      dopplerRatio = (num / den).clamp(0.75, 1.35);
    }

    return SpatialSourcePanResult(
      sourceId: source.id,
      category: source.category,
      distanceMeters: distance,
      azimuthRadians: azimuth,
      elevationRadians: elevation,
      pan: pan,
      leftGain: leftGain,
      rightGain: rightGain,
      distanceAttenuation: distanceAtten,
      airAbsorptionFactor: airAbsorption,
      dopplerPitchRatio: dopplerRatio,
      isCulled: effectiveGain <= 0.0005,
    );
  }

  /// Oblicza mapę wyników panoramowania dla wszystkich źródeł w scenie 3D.
  Map<String, SpatialSourcePanResult> computeAllSources({
    required List<SpatialAudioSource3D> sources,
    required SpatialAudioListener3D listener,
  }) {
    final Map<String, SpatialSourcePanResult> results =
        <String, SpatialSourcePanResult>{};
    for (final source in sources) {
      results[source.id] = computeSourcePan(source: source, listener: listener);
    }
    return results;
  }

  /// Panoramuje próbkę mono zgodnie z wynikiem [SpatialSourcePanResult].
  AudioStereoFrame panMonoSample(
    double monoSample,
    SpatialSourcePanResult panResult,
  ) {
    if (panResult.isCulled) return AudioStereoFrame.zero;
    return AudioStereoFrame(
      (monoSample * panResult.leftGain).clamp(-1.0, 1.0),
      (monoSample * panResult.rightGain).clamp(-1.0, 1.0),
    );
  }

  /// Panoramuje ramkę stereo (miksując kanały z zachowaniem balansu przestrzennego).
  AudioStereoFrame panStereoFrame(
    AudioStereoFrame input,
    SpatialSourcePanResult panResult,
  ) {
    if (panResult.isCulled) return AudioStereoFrame.zero;
    final double monoCenter = (input.left + input.right) * 0.5;
    // Zachowuje 25% oryginalnej szerokości stereo i 75% pozycji 3D
    final double blendedL = (input.left * 0.25) + (monoCenter * 0.75);
    final double blendedR = (input.right * 0.25) + (monoCenter * 0.75);
    return AudioStereoFrame(
      (blendedL * panResult.leftGain).clamp(-1.0, 1.0),
      (blendedR * panResult.rightGain).clamp(-1.0, 1.0),
    );
  }

  /// Miksuje listę źródeł 3D z ich ramkami audio w jedną ramkę stereo z miękkim limiterem.
  AudioStereoFrame mixSourcesToFrame({
    required List<({SpatialAudioSource3D source, AudioStereoFrame frame})>
        inputs,
    required SpatialAudioListener3D listener,
  }) {
    if (inputs.isEmpty || masterGain <= 0.0) return AudioStereoFrame.zero;

    double sumL = 0.0;
    double sumR = 0.0;

    for (final entry in inputs) {
      final panResult = computeSourcePan(
        source: entry.source,
        listener: listener,
      );
      if (panResult.isCulled) continue;
      final panned = panStereoFrame(entry.frame, panResult);
      sumL += panned.left;
      sumR += panned.right;
    }

    return AudioStereoFrame(_softClip(sumL), _softClip(sumR));
  }

  /// Generuje realistyczny zestaw źródeł 3D dla sceny wyścigowej (peleton, wozy, kibice, heli).
  static List<SpatialAudioSource3D> buildDefaultRaceSceneSources({
    double roadSpeedMs = 12.8,
  }) {
    return <SpatialAudioSource3D>[
      SpatialAudioSource3D(
        id: 'peloton_core',
        label: 'Główna grupa peletonu',
        category: SpatialAudioSourceCategory.peloton,
        position: Vector3(0.0, 0.9, 0.0),
        velocity: Vector3(0.0, 0.0, roadSpeedMs),
        baseGain: 1.05,
        spreadRadiusMeters: 8.5,
      ),
      SpatialAudioSource3D(
        id: 'team_car_1',
        label: 'Wóz techniczny #1 (DS)',
        category: SpatialAudioSourceCategory.teamCar,
        position: Vector3(-2.6, 1.1, -14.5),
        velocity: Vector3(0.0, 0.0, roadSpeedMs + 0.8),
        baseGain: 0.92,
      ),
      SpatialAudioSource3D(
        id: 'neutral_car',
        label: 'Wóz neutralny (Shimano)',
        category: SpatialAudioSourceCategory.teamCar,
        position: Vector3(2.8, 1.1, -24.0),
        velocity: Vector3(0.0, 0.0, roadSpeedMs + 0.3),
        baseGain: 0.80,
      ),
      SpatialAudioSource3D(
        id: 'moto_tv_front',
        label: 'Motocykl TV (przód)',
        category: SpatialAudioSourceCategory.motoCamera,
        position: Vector3(1.4, 1.2, 8.5),
        velocity: Vector3(0.0, 0.0, roadSpeedMs),
        baseGain: 0.82,
      ),
      SpatialAudioSource3D(
        id: 'crowd_left_barrier',
        label: 'Kibice — lewe pobocze',
        category: SpatialAudioSourceCategory.spectatorCrowd,
        position: Vector3(-7.5, 1.4, 12.0),
        velocity: Vector3.zero(),
        baseGain: 1.0,
        spreadRadiusMeters: 14.0,
      ),
      SpatialAudioSource3D(
        id: 'crowd_right_tunnel',
        label: 'Kibice — szpaler prawy',
        category: SpatialAudioSourceCategory.spectatorCrowd,
        position: Vector3(8.2, 1.5, 18.0),
        velocity: Vector3.zero(),
        baseGain: 1.05,
        spreadRadiusMeters: 14.0,
      ),
      SpatialAudioSource3D(
        id: 'tv_helicopter',
        label: 'Helikopter transmisji TV',
        category: SpatialAudioSourceCategory.helicopter,
        position: Vector3(-18.0, 58.0, 12.0),
        velocity: Vector3(3.2, 0.0, roadSpeedMs),
        baseGain: 0.78,
      ),
    ];
  }

  /// Tworzy słuchacza dla wybranego trybu kamery 3D w domyślnej scenie wyścigu.
  static SpatialAudioListener3D buildListenerForCameraMode(
    RaceCameraMode mode, {
    double roadSpeedMs = 12.8,
  }) {
    switch (mode) {
      case RaceCameraMode.chaseCam:
        return SpatialAudioListener3D.fromLookAt(
          position: Vector3(0.0, 1.85, -4.8),
          target: Vector3(0.0, 1.1, 4.0),
          velocity: Vector3(0.0, 0.0, roadSpeedMs),
          cameraMode: RaceCameraMode.chaseCam,
          fovDegrees: 58.0,
        );
      case RaceCameraMode.motoTvCam:
        return SpatialAudioListener3D.fromLookAt(
          position: Vector3(1.25, 1.65, 8.0),
          target: Vector3(0.0, 1.05, 0.0),
          velocity: Vector3(0.0, 0.0, roadSpeedMs),
          cameraMode: RaceCameraMode.motoTvCam,
          fovDegrees: 50.0,
        );
      case RaceCameraMode.heliCam:
        return SpatialAudioListener3D.fromLookAt(
          position: Vector3(-22.0, 62.0, -18.0),
          target: Vector3(0.0, 0.9, 0.0),
          velocity: Vector3(0.0, 0.0, roadSpeedMs),
          cameraMode: RaceCameraMode.heliCam,
          fovDegrees: 52.0,
        );
      case RaceCameraMode.finishLineCam:
        return SpatialAudioListener3D.fromLookAt(
          position: Vector3(0.8, 5.6, 42.0),
          target: Vector3(0.0, 1.0, 0.0),
          velocity: Vector3.zero(),
          cameraMode: RaceCameraMode.finishLineCam,
          fovDegrees: 24.0,
        );
    }
  }

  static (double, double) _computePanWeights(
    double pan,
    SpatialPanningLaw law,
  ) {
    final double clamped = pan.clamp(-1.0, 1.0);
    final double norm = (clamped + 1.0) * 0.5; // [0.0 = L, 1.0 = R]
    switch (law) {
      case SpatialPanningLaw.equalPower:
        final double angle = norm * (math.pi * 0.5);
        return (math.cos(angle), math.sin(angle));
      case SpatialPanningLaw.linear:
        return (1.0 - norm, norm);
      case SpatialPanningLaw.sqrtPower:
        return (math.sqrt(1.0 - norm), math.sqrt(norm));
    }
  }

  static double _cameraModeCategoryWeight(
    RaceCameraMode mode,
    SpatialAudioSourceCategory category,
  ) {
    switch (mode) {
      case RaceCameraMode.chaseCam:
        switch (category) {
          case SpatialAudioSourceCategory.peloton:
            return 1.08;
          case SpatialAudioSourceCategory.teamCar:
            return 1.0;
          case SpatialAudioSourceCategory.motoCamera:
            return 0.85;
          case SpatialAudioSourceCategory.spectatorCrowd:
            return 0.95;
          case SpatialAudioSourceCategory.helicopter:
            return 0.65;
        }
      case RaceCameraMode.motoTvCam:
        switch (category) {
          case SpatialAudioSourceCategory.peloton:
            return 1.05;
          case SpatialAudioSourceCategory.teamCar:
            return 0.78;
          case SpatialAudioSourceCategory.motoCamera:
            return 1.12;
          case SpatialAudioSourceCategory.spectatorCrowd:
            return 1.02;
          case SpatialAudioSourceCategory.helicopter:
            return 0.70;
        }
      case RaceCameraMode.heliCam:
        switch (category) {
          case SpatialAudioSourceCategory.peloton:
            return 0.72;
          case SpatialAudioSourceCategory.teamCar:
            return 0.65;
          case SpatialAudioSourceCategory.motoCamera:
            return 0.55;
          case SpatialAudioSourceCategory.spectatorCrowd:
            return 1.15;
          case SpatialAudioSourceCategory.helicopter:
            return 1.25;
        }
      case RaceCameraMode.finishLineCam:
        switch (category) {
          case SpatialAudioSourceCategory.peloton:
            return 1.10;
          case SpatialAudioSourceCategory.teamCar:
            return 0.75;
          case SpatialAudioSourceCategory.motoCamera:
            return 0.82;
          case SpatialAudioSourceCategory.spectatorCrowd:
            return 1.28;
          case SpatialAudioSourceCategory.helicopter:
            return 0.75;
        }
    }
  }

  static double _softClip(double x) {
    if (x < -1.5) return -1.0;
    if (x > 1.5) return 1.0;
    return x * (27.0 + (x * x)) / (27.0 + (9.0 * x * x));
  }
}

// ============================================================================
// STAN RIVERPOD & NOTIFIER
// ============================================================================

/// Niemutowalny stan kontrolera przestrzennego panoramowania 3D.
class SpatialAudioPannerState {
  final SpatialAudioListener3D listener;
  final List<SpatialAudioSource3D> sources;
  final Map<String, SpatialSourcePanResult> results;
  final SpatialPanningLaw panningLaw;
  final double masterGain;
  final bool dopplerEnabled;
  final bool airAbsorptionEnabled;
  final bool isBypassed;
  final String? selectedSourceId;

  const SpatialAudioPannerState({
    required this.listener,
    required this.sources,
    required this.results,
    this.panningLaw = SpatialPanningLaw.equalPower,
    this.masterGain = 1.0,
    this.dopplerEnabled = true,
    this.airAbsorptionEnabled = true,
    this.isBypassed = false,
    this.selectedSourceId,
  });

  SpatialAudioPannerState copyWith({
    SpatialAudioListener3D? listener,
    List<SpatialAudioSource3D>? sources,
    Map<String, SpatialSourcePanResult>? results,
    SpatialPanningLaw? panningLaw,
    double? masterGain,
    bool? dopplerEnabled,
    bool? airAbsorptionEnabled,
    bool? isBypassed,
    String? selectedSourceId,
    bool clearSelectedSource = false,
  }) {
    return SpatialAudioPannerState(
      listener: listener ?? this.listener,
      sources: sources ?? this.sources,
      results: results ?? this.results,
      panningLaw: panningLaw ?? this.panningLaw,
      masterGain: masterGain ?? this.masterGain,
      dopplerEnabled: dopplerEnabled ?? this.dopplerEnabled,
      airAbsorptionEnabled: airAbsorptionEnabled ?? this.airAbsorptionEnabled,
      isBypassed: isBypassed ?? this.isBypassed,
      selectedSourceId: clearSelectedSource
          ? null
          : (selectedSourceId ?? this.selectedSourceId),
    );
  }
}

/// Kontroler Riverpod zarządzający przestrzennym panoramowaniem 3D w czasie rzeczywistym.
class Spatial3dPelotonAudioPannerNotifier
    extends StateNotifier<SpatialAudioPannerState> {
  Spatial3dPelotonAudioPannerNotifier() : super(_buildInitialState());

  static SpatialAudioPannerState _buildInitialState() {
    final listener = Spatial3dPelotonAudioPanner.buildListenerForCameraMode(
      RaceCameraMode.chaseCam,
    );
    final sources = Spatial3dPelotonAudioPanner.buildDefaultRaceSceneSources();
    const panner = Spatial3dPelotonAudioPanner();
    final results = panner.computeAllSources(
      sources: sources,
      listener: listener,
    );
    return SpatialAudioPannerState(
      listener: listener,
      sources: sources,
      results: results,
      selectedSourceId: sources.first.id,
    );
  }

  Spatial3dPelotonAudioPanner get _activePanner => Spatial3dPelotonAudioPanner(
        panningLaw: state.panningLaw,
        masterGain: state.isBypassed ? 0.0 : state.masterGain,
        dopplerEnabled: state.dopplerEnabled,
        airAbsorptionEnabled: state.airAbsorptionEnabled,
      );

  void _recompute({
    SpatialAudioListener3D? listener,
    List<SpatialAudioSource3D>? sources,
    SpatialPanningLaw? panningLaw,
    double? masterGain,
    bool? dopplerEnabled,
    bool? airAbsorptionEnabled,
    bool? isBypassed,
    String? selectedSourceId,
    bool clearSelectedSource = false,
  }) {
    final nextListener = listener ?? state.listener;
    final nextSources = sources ?? state.sources;
    final nextLaw = panningLaw ?? state.panningLaw;
    final nextGain = (masterGain ?? state.masterGain).clamp(0.0, 1.5);
    final nextDoppler = dopplerEnabled ?? state.dopplerEnabled;
    final nextAir = airAbsorptionEnabled ?? state.airAbsorptionEnabled;
    final nextBypass = isBypassed ?? state.isBypassed;

    final panner = Spatial3dPelotonAudioPanner(
      panningLaw: nextLaw,
      masterGain: nextBypass ? 0.0 : nextGain,
      dopplerEnabled: nextDoppler,
      airAbsorptionEnabled: nextAir,
    );

    final nextResults = panner.computeAllSources(
      sources: nextSources,
      listener: nextListener,
    );

    state = state.copyWith(
      listener: nextListener,
      sources: nextSources,
      results: nextResults,
      panningLaw: nextLaw,
      masterGain: nextGain,
      dopplerEnabled: nextDoppler,
      airAbsorptionEnabled: nextAir,
      isBypassed: nextBypass,
      selectedSourceId: selectedSourceId,
      clearSelectedSource: clearSelectedSource,
    );
  }

  /// Synchronizuje pozycję i orientację słuchacza bezpośrednio z [CameraRigController].
  void updateFromCameraRig(CameraRigController rig, {Vector3? velocity}) {
    final listener = SpatialAudioListener3D.fromCameraRig(
      rig,
      velocity: velocity,
    );
    _recompute(listener: listener);
  }

  /// Aktualizuje słuchacza ręcznie (np. przy zmianie trybu kamery w podglądzie).
  void setCameraModePreset(RaceCameraMode mode) {
    final listener = Spatial3dPelotonAudioPanner.buildListenerForCameraMode(mode);
    _recompute(listener: listener);
  }

  void updateListener(SpatialAudioListener3D listener) {
    _recompute(listener: listener);
  }

  void upsertSource(SpatialAudioSource3D source) {
    final List<SpatialAudioSource3D> updated =
        List<SpatialAudioSource3D>.from(state.sources);
    final index = updated.indexWhere((s) => s.id == source.id);
    if (index >= 0) {
      updated[index] = source;
    } else {
      updated.add(source);
    }
    _recompute(sources: updated);
  }

  void removeSource(String sourceId) {
    final updated =
        state.sources.where((s) => s.id != sourceId).toList(growable: false);
    final clearSel = state.selectedSourceId == sourceId;
    _recompute(sources: updated, clearSelectedSource: clearSel);
  }

  void toggleSourceMute(String sourceId) {
    final updated = state.sources
        .map((s) => s.id == sourceId ? s.copyWith(isMuted: !s.isMuted) : s)
        .toList(growable: false);
    _recompute(sources: updated);
  }

  void selectSource(String? sourceId) {
    _recompute(
      selectedSourceId: sourceId,
      clearSelectedSource: sourceId == null,
    );
  }

  void setPanningLaw(SpatialPanningLaw law) {
    _recompute(panningLaw: law);
  }

  void setMasterGain(double gain) {
    _recompute(masterGain: gain);
  }

  void toggleDoppler() {
    _recompute(dopplerEnabled: !state.dopplerEnabled);
  }

  void toggleAirAbsorption() {
    _recompute(airAbsorptionEnabled: !state.airAbsorptionEnabled);
  }

  void toggleBypass() {
    _recompute(isBypassed: !state.isBypassed);
  }

  void resetDemoScene() {
    final initial = _buildInitialState();
    state = initial;
  }

  /// Miksuje bieżące źródła w jedną ramkę stereo na potrzeby potoku audio 3D.
  AudioStereoFrame mixCurrentFrame(
    Map<String, AudioStereoFrame> sourceFrames,
  ) {
    final inputs = <({SpatialAudioSource3D source, AudioStereoFrame frame})>[];
    for (final src in state.sources) {
      final frame = sourceFrames[src.id];
      if (frame != null) {
        inputs.add((source: src, frame: frame));
      }
    }
    return _activePanner.mixSourcesToFrame(
      inputs: inputs,
      listener: state.listener,
    );
  }
}

final spatial3dPelotonAudioPannerProvider = StateNotifierProvider<
    Spatial3dPelotonAudioPannerNotifier, SpatialAudioPannerState>(
  (ref) => Spatial3dPelotonAudioPannerNotifier(),
);

// ============================================================================
// PANEL UI: WIZUALIZATOR I KONTROLER PANORAMOWANIA 3D
// ============================================================================

/// Produkcyjny panel kontrolny i radar stereo panoramowania 3D dźwięku wyścigu.
class Spatial3dPelotonAudioPannerPanel extends ConsumerWidget {
  const Spatial3dPelotonAudioPannerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(spatial3dPelotonAudioPannerProvider);
    final notifier = ref.read(spatial3dPelotonAudioPannerProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;
          final isWide = constraints.maxWidth >= 1180;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _HeaderBar(
                  state: state,
                  onToggleBypass: notifier.toggleBypass,
                  onReset: notifier.resetDemoScene,
                  isCompact: isCompact,
                ),
                const SizedBox(height: 16),
                if (isCompact) ...<Widget>[
                  _RadarAndControlsCard(
                    state: state,
                    notifier: notifier,
                    radarHeight: 230,
                  ),
                  const SizedBox(height: 16),
                  _SourceMetersCard(
                    state: state,
                    notifier: notifier,
                  ),
                ] else ...<Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: isWide ? 5 : 6,
                        child: _RadarAndControlsCard(
                          state: state,
                          notifier: notifier,
                          radarHeight: isWide ? 310 : 260,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: isWide ? 7 : 6,
                        child: _SourceMetersCard(
                          state: state,
                          notifier: notifier,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final SpatialAudioPannerState state;
  final VoidCallback onToggleBypass;
  final VoidCallback onReset;
  final bool isCompact;

  const _HeaderBar({
    required this.state,
    required this.onToggleBypass,
    required this.onReset,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final titleRow = Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.45),
            ),
          ),
          child: const Icon(
            Icons.surround_sound_rounded,
            color: AppColors.goldAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Panoramowanie 3D Audio Wyścigu',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Kamera: ${state.listener.cameraMode.shortLabel} • ${state.sources.length} źródeł • ${state.panningLaw.label}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _InteractivePillButton(
          label: state.isBypassed ? 'Wyciszono (Bypass)' : 'Aktywny 3D',
          icon: state.isBypassed
              ? Icons.volume_off_rounded
              : Icons.graphic_eq_rounded,
          isActive: !state.isBypassed,
          activeColor: AppColors.statusSuccess,
          onPressed: onToggleBypass,
        ),
        _InteractivePillButton(
          label: isCompact ? 'Reset' : 'Resetuj scenę',
          icon: Icons.restart_alt_rounded,
          isActive: false,
          activeColor: AppColors.goldAccent,
          onPressed: onReset,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                titleRow,
                const SizedBox(height: 12),
                actions,
              ],
            )
          : Row(
              children: <Widget>[
                Expanded(child: titleRow),
                const SizedBox(width: 12),
                actions,
              ],
            ),
    );
  }
}

class _RadarAndControlsCard extends StatelessWidget {
  final SpatialAudioPannerState state;
  final Spatial3dPelotonAudioPannerNotifier notifier;
  final double radarHeight;

  const _RadarAndControlsCard({
    required this.state,
    required this.notifier,
    required this.radarHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'RADAR POLA STEREO 3D',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: radarHeight,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: SpatialAudioRadarPainter(
                  listener: state.listener,
                  sources: state.sources,
                  results: state.results,
                  selectedSourceId: state.selectedSourceId,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'TRYB KAMERY 3D',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RaceCameraMode.values.map((mode) {
              final selected = state.listener.cameraMode == mode;
              return _InteractivePillButton(
                label: mode.shortLabel,
                icon: _cameraIcon(mode),
                isActive: selected,
                activeColor: AppColors.goldAccent,
                onPressed: () => notifier.setCameraModePreset(mode),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'PRAWO PANORAMY & AKUSTYKA',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SpatialPanningLaw.values.map((law) {
              final selected = state.panningLaw == law;
              return _InteractivePillButton(
                label: law.label,
                icon: Icons.tune_rounded,
                isActive: selected,
                activeColor: AppColors.accentBlue,
                onPressed: () => notifier.setPanningLaw(law),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              const Text(
                'Master Gain',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.goldAccent,
                    inactiveTrackColor: AppColors.surfaceLight,
                    thumbColor: AppColors.goldAccent,
                    overlayColor: AppColors.goldAccent.withValues(alpha: 0.16),
                  ),
                  child: Slider(
                    value: state.masterGain.clamp(0.0, 1.5),
                    min: 0.0,
                    max: 1.5,
                    divisions: 30,
                    onChanged: state.isBypassed ? null : notifier.setMasterGain,
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '${(state.masterGain * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _InteractivePillButton(
                label: 'Efekt Dopplera',
                icon: Icons.speed_rounded,
                isActive: state.dopplerEnabled,
                activeColor: AppColors.cyanAccent,
                onPressed: notifier.toggleDoppler,
              ),
              _InteractivePillButton(
                label: 'Absorpcja powietrza',
                icon: Icons.air_rounded,
                isActive: state.airAbsorptionEnabled,
                activeColor: AppColors.statusSuccess,
                onPressed: notifier.toggleAirAbsorption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _cameraIcon(RaceCameraMode mode) {
    switch (mode) {
      case RaceCameraMode.chaseCam:
        return Icons.directions_bike_rounded;
      case RaceCameraMode.motoTvCam:
        return Icons.two_wheeler_rounded;
      case RaceCameraMode.heliCam:
        return Icons.flight_rounded;
      case RaceCameraMode.finishLineCam:
        return Icons.flag_rounded;
    }
  }
}

class _SourceMetersCard extends StatelessWidget {
  final SpatialAudioPannerState state;
  final Spatial3dPelotonAudioPannerNotifier notifier;

  const _SourceMetersCard({
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'ŹRÓDŁA PRZESTRZENNE & BALANS L/R',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${state.sources.where((s) => !s.isMuted).length}/${state.sources.length} aktywnych',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.sources.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Brak zarejestrowanych źródeł audio 3D.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...state.sources.map((source) {
              final result = state.results[source.id];
              final isSelected = state.selectedSourceId == source.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SourceMeterTile(
                  source: source,
                  result: result,
                  isSelected: isSelected,
                  onSelect: () => notifier.selectSource(source.id),
                  onToggleMute: () => notifier.toggleSourceMute(source.id),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SourceMeterTile extends StatefulWidget {
  final SpatialAudioSource3D source;
  final SpatialSourcePanResult? result;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onToggleMute;

  const _SourceMeterTile({
    required this.source,
    required this.result,
    required this.isSelected,
    required this.onSelect,
    required this.onToggleMute,
  });

  @override
  State<_SourceMeterTile> createState() => _SourceMeterTileState();
}

class _SourceMeterTileState extends State<_SourceMeterTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final res = widget.result;
    final catColor = widget.source.category.accentColor;
    final isMuted = widget.source.isMuted;
    final leftGain = res?.leftGain ?? 0.0;
    final rightGain = res?.rightGain ?? 0.0;
    final distM = res?.distanceMeters ?? 0.0;
    final pan = res?.pan ?? 0.0;
    final doppler = res?.dopplerPitchRatio ?? 1.0;

    final borderColor = widget.isSelected
        ? catColor
        : (_focused
            ? AppColors.goldAccent
            : (_hovered
                ? AppColors.textSecondary.withValues(alpha: 0.45)
                : AppTheme.borderColor));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: FocusableActionDetector(
        onShowFocusHighlight: (val) => setState(() => _focused = val),
        child: InkWell(
          onTap: widget.onSelect,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.surfaceLight
                  : (_hovered
                      ? AppColors.surfaceLight.withValues(alpha: 0.65)
                      : AppColors.background),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.source.category.shortLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isMuted ? AppColors.textSecondary : catColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.source.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isMuted
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${distM.toStringAsFixed(1)} m',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: widget.onToggleMute,
                      tooltip: isMuted ? 'Włącz źródło' : 'Wycisz źródło',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        size: 18,
                        color: isMuted
                            ? AppColors.crimsonAlert
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    const Text(
                      'L',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _StereoLevelBar(
                        level: (leftGain / 1.25).clamp(0.0, 1.0),
                        color: isMuted ? AppColors.textSecondary : catColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'R',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _StereoLevelBar(
                        level: (rightGain / 1.25).clamp(0.0, 1.0),
                        color: isMuted ? AppColors.textSecondary : catColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Pan ${pan >= 0 ? '+' : ''}${pan.toStringAsFixed(2)} • ${doppler.toStringAsFixed(2)}x',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StereoLevelBar extends StatelessWidget {
  final double level;
  final Color color;

  const _StereoLevelBar({
    required this.level,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          widthFactor: level.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractivePillButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onPressed;

  const _InteractivePillButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onPressed,
  });

  @override
  State<_InteractivePillButton> createState() => _InteractivePillButtonState();
}

class _InteractivePillButtonState extends State<_InteractivePillButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final bgColor = disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : (widget.isActive
            ? widget.activeColor.withValues(alpha: _hovered ? 0.28 : 0.18)
            : (_hovered ? AppColors.surfaceLight : AppColors.background));

    final borderColor = disabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : (_focused
            ? AppColors.goldAccent
            : (widget.isActive
                ? widget.activeColor.withValues(alpha: 0.7)
                : AppTheme.borderColor));

    final fgColor = disabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : (widget.isActive ? widget.activeColor : AppColors.textPrimary);

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: FocusableActionDetector(
        enabled: !disabled,
        onShowFocusHighlight: (val) => setState(() => _focused = val),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(widget.icon, size: 15, color: fgColor),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight:
                        widget.isActive ? FontWeight.w600 : FontWeight.w500,
                    color: fgColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rysuje radar pola stereo 3D w układzie współrzędnych kamery (przód w górę, prawo w prawo).
class SpatialAudioRadarPainter extends CustomPainter {
  final SpatialAudioListener3D listener;
  final List<SpatialAudioSource3D> sources;
  final Map<String, SpatialSourcePanResult> results;
  final String? selectedSourceId;

  const SpatialAudioRadarPainter({
    required this.listener,
    required this.sources,
    required this.results,
    this.selectedSourceId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.56);
    final maxRadius = math.min(size.width, size.height) * 0.42;

    // Siatka odległości (pierścienie)
    final gridPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final factor in const <double>[0.33, 0.66, 1.0]) {
      canvas.drawCircle(center, maxRadius * factor, gridPaint);
    }

    // Osie L/R i przód/tył
    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      gridPaint,
    );

    // Stożek pola widzenia kamery
    final halfFovRad =
        (listener.fovDegrees.clamp(15.0, 120.0) * math.pi / 180.0) * 0.5;
    final conePath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(
        center.dx - math.sin(halfFovRad) * maxRadius,
        center.dy - math.cos(halfFovRad) * maxRadius,
      )
      ..arcToPoint(
        Offset(
          center.dx + math.sin(halfFovRad) * maxRadius,
          center.dy - math.cos(halfFovRad) * maxRadius,
        ),
        radius: Radius.circular(maxRadius),
      )
      ..close();

    final conePaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawPath(conePath, conePaint);

    // Punkt kamery (słuchacza)
    canvas.drawCircle(
      center,
      5.5,
      Paint()..color = AppColors.goldAccent,
    );

    // Rysowanie źródeł w układzie lokalnym kamery
    const double radarRangeMeters = 80.0;
    for (final source in sources) {
      final delta = source.position - listener.position;
      final localX = delta.dot(listener.right);
      final localZ = delta.dot(listener.forward);

      final scaledDist =
          (math.sqrt((localX * localX) + (localZ * localZ)) / radarRangeMeters)
              .clamp(0.0, 1.0);
      final angle = math.atan2(localX, localZ);
      final px = center.dx + math.sin(angle) * scaledDist * maxRadius;
      final py = center.dy - math.cos(angle) * scaledDist * maxRadius;

      final res = results[source.id];
      final color = source.isMuted
          ? AppColors.textSecondary
          : source.category.accentColor;
      final isSelected = selectedSourceId == source.id;

      if (isSelected) {
        canvas.drawCircle(
          Offset(px, py),
          10.5,
          Paint()
            ..color = color.withValues(alpha: 0.25)
            ..style = PaintingStyle.fill,
        );
      }

      canvas.drawCircle(
        Offset(px, py),
        isSelected ? 6.0 : 4.5,
        Paint()..color = color,
      );

      if (res != null && !source.isMuted && res.combinedGain > 0.05) {
        canvas.drawCircle(
          Offset(px, py),
          6.0 + (res.combinedGain * 4.5),
          Paint()
            ..color = color.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant SpatialAudioRadarPainter oldDelegate) {
    return oldDelegate.listener != listener ||
        oldDelegate.sources != sources ||
        oldDelegate.results != results ||
        oldDelegate.selectedSourceId != selectedSourceId;
  }
}
