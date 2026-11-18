// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/race_simulation_notifier.dart';
import '../../ui/widgets/corner_g_force_and_lean_angle_telemetry_hud.dart';
import 'on_bike_computer_hud_widget.dart';
import 'peloton_3d_canvas_engine.dart';
import 'scene_3d_math_projection.dart';

/// Pozycja dłoni kolarza na kierownicy w widoku z pierwszej osoby (Cockpit View).
enum CockpitGripPosture {
  /// Standardowy chwyt na klamkomanetkach (najwyższa widoczność peletonu i licznika).
  hoods(
    label: 'Klamki (Hoods)',
    shortLabel: 'Hoods',
    eyeHeightMeters: 1.34,
    pitchOffsetRadians: -0.14,
    fovOffsetDegrees: 0.0,
    handSpreadFactor: 1.0,
    handVerticalOffset: 0.0,
  ),

  /// Dolny chwyt w baranku (sprint / szybki zjazd, niższa pozycja głowy).
  drops(
    label: 'Dolny chwyt (Drops)',
    shortLabel: 'Drops',
    eyeHeightMeters: 1.16,
    pitchOffsetRadians: -0.10,
    fovOffsetDegrees: 5.0,
    handSpreadFactor: 1.06,
    handVerticalOffset: 0.14,
  ),

  /// Górny chwyt na płaskiej części kierownicy (strome podjazdy).
  tops(
    label: 'Góra kierownicy (Tops)',
    shortLabel: 'Tops',
    eyeHeightMeters: 1.41,
    pitchOffsetRadians: -0.17,
    fovOffsetDegrees: -2.0,
    handSpreadFactor: 0.62,
    handVerticalOffset: -0.04,
  ),

  /// Agresywna pozycja aerodynamiczna z łokciami przy mostku.
  aeroTuck(
    label: 'Pozycja Aero (Tuck)',
    shortLabel: 'Aero',
    eyeHeightMeters: 1.06,
    pitchOffsetRadians: -0.08,
    fovOffsetDegrees: 7.5,
    handSpreadFactor: 0.78,
    handVerticalOffset: 0.04,
  );

  final String label;
  final String shortLabel;
  final double eyeHeightMeters;
  final double pitchOffsetRadians;
  final double fovOffsetDegrees;
  final double handSpreadFactor;
  final double handVerticalOffset;

  const CockpitGripPosture({
    required this.label,
    required this.shortLabel,
    required this.eyeHeightMeters,
    required this.pitchOffsetRadians,
    required this.fovOffsetDegrees,
    required this.handSpreadFactor,
    required this.handVerticalOffset,
  });
}

/// Kierunek kliknięcia zmiany przełożenia na klamkomanetkach.
enum CockpitShiftDirection {
  none,
  upshift,
  downshift,
}

/// Konfiguracja kamery pierwszoosobowej (First-Person Cockpit View).
class FirstPersonCockpitConfig {
  /// Bazowy pionowy kąt widzenia (Vertical FOV) [stopnie].
  final double baseFovYDegrees;

  /// Maksymalne poszerzenie FOV przy wysokich prędkościach (> 65 km/h) [stopnie].
  final double maxSpeedFovBoostDegrees;

  /// Szerokość kierownicy (od osi do osi klamek) [m].
  final double handlebarWidthMeters;

  /// Długość mostka [m].
  final double stemLengthMeters;

  /// Promień zewnętrzny przedniego koła z oponą [m].
  final double frontWheelRadiusMeters;

  /// Maksymalny zasięg renderowania rywali przed kamerą [m].
  final double maxRivalRenderDistanceMeters;

  /// Czy rysować proceduralną szosę i niebo w tle (false, gdy nakładka leży na silniku 3D).
  final bool renderBackgroundRoadAndSky;

  /// Czy włączyć mikrodrgania na bruku i kołysanie oddechu/kadencji.
  final bool enableDynamicHeadBob;

  /// Czy włączyć linie pędu powietrza przy dużych prędkościach.
  final bool enableSpeedLines;

  /// Model zamontowanego komputera rowerowego (Garmin / Wahoo).
  final BikeComputerModel computerModel;

  const FirstPersonCockpitConfig({
    this.baseFovYDegrees = 68.0,
    this.maxSpeedFovBoostDegrees = 8.0,
    this.handlebarWidthMeters = 0.40,
    this.stemLengthMeters = 0.12,
    this.frontWheelRadiusMeters = 0.34,
    this.maxRivalRenderDistanceMeters = 32.0,
    this.renderBackgroundRoadAndSky = true,
    this.enableDynamicHeadBob = true,
    this.enableSpeedLines = true,
    this.computerModel = BikeComputerModel.garminEdge,
  });

  FirstPersonCockpitConfig copyWith({
    double? baseFovYDegrees,
    double? maxSpeedFovBoostDegrees,
    double? handlebarWidthMeters,
    double? stemLengthMeters,
    double? frontWheelRadiusMeters,
    double? maxRivalRenderDistanceMeters,
    bool? renderBackgroundRoadAndSky,
    bool? enableDynamicHeadBob,
    bool? enableSpeedLines,
    BikeComputerModel? computerModel,
  }) {
    return FirstPersonCockpitConfig(
      baseFovYDegrees: baseFovYDegrees ?? this.baseFovYDegrees,
      maxSpeedFovBoostDegrees:
          maxSpeedFovBoostDegrees ?? this.maxSpeedFovBoostDegrees,
      handlebarWidthMeters: handlebarWidthMeters ?? this.handlebarWidthMeters,
      stemLengthMeters: stemLengthMeters ?? this.stemLengthMeters,
      frontWheelRadiusMeters:
          frontWheelRadiusMeters ?? this.frontWheelRadiusMeters,
      maxRivalRenderDistanceMeters:
          maxRivalRenderDistanceMeters ?? this.maxRivalRenderDistanceMeters,
      renderBackgroundRoadAndSky:
          renderBackgroundRoadAndSky ?? this.renderBackgroundRoadAndSky,
      enableDynamicHeadBob: enableDynamicHeadBob ?? this.enableDynamicHeadBob,
      enableSpeedLines: enableSpeedLines ?? this.enableSpeedLines,
      computerModel: computerModel ?? this.computerModel,
    );
  }
}

/// Dane pojedynczego rywala jadącego przed nami w gęstym peletonie (nawet 30 cm przed kołem!).
class CockpitRivalAheadSample {
  final String riderId;
  final String riderName;
  final int bibNumber;
  final Color jerseyColor;
  final LeaderJerseyType leaderJerseyType;

  /// Odległość od przedniego koła gracza do tylnego koła rywala [m] (np. 0.30 m).
  final double gapAheadMeters;

  /// Poprzeczne przesunięcie względem osi jazdy gracza [m] (- lewo, + prawo).
  final double lateralOffsetMeters;

  /// Prędkość rywala [m/s].
  final double speedMs;

  /// Kadencja rywala [RPM].
  final double cadenceRpm;

  /// Faza obrotu korby / koła [rad].
  final double wheelPhaseRadians;

  /// Czy rywal jedzie na stojąco ("en danseuse").
  final bool isStanding;

  /// Kąt pochylenia roweru w zakręcie lub przy kołysaniu [rad].
  final double leanAngleRadians;

  const CockpitRivalAheadSample({
    required this.riderId,
    required this.riderName,
    required this.bibNumber,
    required this.jerseyColor,
    this.leaderJerseyType = LeaderJerseyType.none,
    required this.gapAheadMeters,
    required this.lateralOffsetMeters,
    required this.speedMs,
    this.cadenceRpm = 90.0,
    this.wheelPhaseRadians = 0.0,
    this.isStanding = false,
    this.leanAngleRadians = 0.0,
  });
}

/// Rzutowany na ekran 2D rywal z wyliczoną perspektywą koła, nóg i pleców.
class ProjectedCockpitRival {
  final CockpitRivalAheadSample sample;
  final double depthMeters;
  final Offset rearWheelGroundScreen;
  final double wheelRadiusPx;
  final double torsoWidthPx;
  final double torsoHeightPx;
  final double perspectiveScale;
  final bool isTightDraftTarget;

  const ProjectedCockpitRival({
    required this.sample,
    required this.depthMeters,
    required this.rearWheelGroundScreen,
    required this.wheelRadiusPx,
    required this.torsoWidthPx,
    required this.torsoHeightPx,
    required this.perspectiveScale,
    required this.isTightDraftTarget,
  });
}

/// Stan wewnętrzny animacji kokpitu (fazy kół, kliknięcia palców, wygładzone pochylenie).
class FirstPersonCockpitCameraState {
  double frontWheelPhaseRadians;
  double crankPhaseRadians;
  double breathPhaseRadians;
  double cobbleVibrationPhaseRadians;
  double roadScrollMeters;
  double leftShiftAnimationProgress;
  double rightShiftAnimationProgress;
  CockpitShiftDirection activeShiftDirection;
  double smoothedLeanRadians;
  double smoothedSteerRadians;
  double smoothedPowerWatts;
  double smoothedCadenceRpm;
  int frontChainringTeeth;
  int rearCassetteTeeth;

  FirstPersonCockpitCameraState({
    this.frontWheelPhaseRadians = 0.0,
    this.crankPhaseRadians = 0.0,
    this.breathPhaseRadians = 0.0,
    this.cobbleVibrationPhaseRadians = 0.0,
    this.roadScrollMeters = 0.0,
    this.leftShiftAnimationProgress = 0.0,
    this.rightShiftAnimationProgress = 0.0,
    this.activeShiftDirection = CockpitShiftDirection.none,
    this.smoothedLeanRadians = 0.0,
    this.smoothedSteerRadians = 0.0,
    this.smoothedPowerWatts = 340.0,
    this.smoothedCadenceRpm = 92.0,
    this.frontChainringTeeth = 54,
    this.rearCassetteTeeth = 14,
  });

  String get gearLabel => '${frontChainringTeeth}x$rearCassetteTeeth';
}

/// Wejście pojedynczej klatki dla [FirstPersonCockpitCameraRenderer].
class FirstPersonCockpitFrameInput {
  final double dtSeconds;
  final Size viewportSize;
  final Vector3 riderWorldPosition;
  final Vector3 roadTangent;
  final Vector3 roadLateralRight;
  final Vector3 roadSurfaceNormal;
  final double speedMs;
  final double powerWatts;
  final double ftpWatts;
  final double cadenceRpm;
  final double gradientPercent;
  final int heartRateBpm;
  final double draftingSavingsPercent;
  final double leanAngleRadians;
  final double steerAngleRadians;
  final double surfaceRoughness;
  final bool isStanding;
  final CockpitGripPosture gripPosture;
  final Color glovePrimaryColor;
  final Color gloveAccentColor;
  final List<CockpitRivalAheadSample> rivalsAhead;

  const FirstPersonCockpitFrameInput({
    required this.dtSeconds,
    required this.viewportSize,
    required this.riderWorldPosition,
    required this.roadTangent,
    required this.roadLateralRight,
    required this.roadSurfaceNormal,
    required this.speedMs,
    required this.powerWatts,
    this.ftpWatts = 380.0,
    required this.cadenceRpm,
    required this.gradientPercent,
    this.heartRateBpm = 164,
    this.draftingSavingsPercent = 32.0,
    this.leanAngleRadians = 0.0,
    this.steerAngleRadians = 0.0,
    this.surfaceRoughness = 0.12,
    this.isStanding = false,
    this.gripPosture = CockpitGripPosture.hoods,
    this.glovePrimaryColor = AppColors.surfaceLight,
    this.gloveAccentColor = AppColors.primaryAccent,
    this.rivalsAhead = const <CockpitRivalAheadSample>[],
  });
}

/// Wyjściowy stan wyliczony przez [FirstPersonCockpitCameraRenderer] dla jednej klatki.
class FirstPersonCockpitFrameResult {
  final Camera3DConfig cameraConfig;
  final double fovYDegrees;
  final double horizonYFraction;
  final double horizonTiltRadians;
  final double headBobVerticalOffsetPx;
  final double headBobHorizontalOffsetPx;
  final double cobbleShakeOffsetPx;
  final double frontWheelPhaseRadians;
  final double crankPhaseRadians;
  final double roadScrollMeters;
  final double steerAngleRadians;
  final double leftFingerShiftProgress;
  final double rightFingerShiftProgress;
  final int liveWatts;
  final int liveCadenceRpm;
  final double liveGradientPercent;
  final double liveSpeedKmh;
  final int liveHeartRateBpm;
  final int powerZone;
  final Color powerZoneColor;
  final String gearLabel;
  final double closestRivalGapMeters;
  final double draftingSavingsPercent;
  final double speedLinesIntensity;
  final CockpitGripPosture gripPosture;
  final Color glovePrimaryColor;
  final Color gloveAccentColor;
  final List<ProjectedCockpitRival> projectedRivals;

  const FirstPersonCockpitFrameResult({
    required this.cameraConfig,
    required this.fovYDegrees,
    required this.horizonYFraction,
    required this.horizonTiltRadians,
    required this.headBobVerticalOffsetPx,
    required this.headBobHorizontalOffsetPx,
    required this.cobbleShakeOffsetPx,
    required this.frontWheelPhaseRadians,
    required this.crankPhaseRadians,
    required this.roadScrollMeters,
    required this.steerAngleRadians,
    required this.leftFingerShiftProgress,
    required this.rightFingerShiftProgress,
    required this.liveWatts,
    required this.liveCadenceRpm,
    required this.liveGradientPercent,
    required this.liveSpeedKmh,
    required this.liveHeartRateBpm,
    required this.powerZone,
    required this.powerZoneColor,
    required this.gearLabel,
    required this.closestRivalGapMeters,
    required this.draftingSavingsPercent,
    required this.speedLinesIntensity,
    required this.gripPosture,
    required this.glovePrimaryColor,
    required this.gloveAccentColor,
    required this.projectedRivals,
  });
}

/// Silnik kamery pierwszoosobowej 3D (**First-Person Cockpit View / Pro Cyclist Camera**).
///
/// Umieszcza kamerę na wysokości oczu kolarza (`1.06 m - 1.41 m` zależnie od chwytu),
/// oblicza macierz projekcji perspektywicznej `Scene3DMathProjection`, animuje
/// kliknięcia palców przy zmianie przełożeń na klamkomanetkach, obrót przedniego
/// koła pod mostkiem oraz rzutuje rywali jadących nawet `30 cm` przed nami w peletonie.
class FirstPersonCockpitCameraRenderer {
  FirstPersonCockpitConfig config;
  final FirstPersonCockpitCameraState state;
  final Scene3DMathProjection projection;

  static const List<int> _cassette12Teeth = <int>[
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    19,
    21,
    24,
    28,
    34,
  ];

  FirstPersonCockpitCameraRenderer({
    this.config = const FirstPersonCockpitConfig(),
    FirstPersonCockpitCameraState? state,
    Scene3DMathProjection? projection,
  })  : state = state ?? FirstPersonCockpitCameraState(),
        projection = projection ?? Scene3DMathProjection();

  /// Wyzwala animację kliknięcia palców na lewej lub prawej klamkomanetce
  /// i aktualizuje aktualne przełożenie napędu (np. `54x14` -> `54x13`).
  void triggerGearShift(CockpitShiftDirection direction) {
    if (direction == CockpitShiftDirection.none) return;
    state.activeShiftDirection = direction;
    final int currentIdx = _cassette12Teeth.indexOf(state.rearCassetteTeeth);
    final int safeIdx = currentIdx < 0 ? 3 : currentIdx;

    if (direction == CockpitShiftDirection.upshift) {
      state.rightShiftAnimationProgress = 1.0;
      if (safeIdx > 0) {
        state.rearCassetteTeeth = _cassette12Teeth[safeIdx - 1];
      } else if (state.frontChainringTeeth < 54) {
        state.frontChainringTeeth = 54;
      }
    } else if (direction == CockpitShiftDirection.downshift) {
      state.leftShiftAnimationProgress = 1.0;
      if (safeIdx < _cassette12Teeth.length - 1) {
        state.rearCassetteTeeth = _cassette12Teeth[safeIdx + 1];
      } else if (state.frontChainringTeeth > 40) {
        state.frontChainringTeeth = 40;
      }
    }
  }

  /// Wyznacza optymalne przełożenie na podstawie prędkości, kadencji i nachylenia.
  void autoSyncGearToTelemetry({
    required double speedMs,
    required double cadenceRpm,
    required double gradientPercent,
  }) {
    final int targetFront = gradientPercent >= 5.5 ? 40 : 54;
    if (targetFront != state.frontChainringTeeth) {
      state.frontChainringTeeth = targetFront;
    }

    final double safeCadence = cadenceRpm.clamp(45.0, 130.0);
    final double wheelCircumference =
        2.0 * math.pi * config.frontWheelRadiusMeters;
    final double targetRatio =
        (speedMs * 60.0) / (safeCadence * wheelCircumference);

    int bestRear = state.rearCassetteTeeth;
    double bestError = double.infinity;
    for (final int teeth in _cassette12Teeth) {
      final double ratio = targetFront / teeth;
      final double err = (ratio - targetRatio).abs();
      if (err < bestError) {
        bestError = err;
        bestRear = teeth;
      }
    }

    if (bestRear != state.rearCassetteTeeth) {
      final bool isUpshift = bestRear < state.rearCassetteTeeth;
      state.rearCassetteTeeth = bestRear;
      if (isUpshift) {
        state.rightShiftAnimationProgress =
            math.max(state.rightShiftAnimationProgress, 0.72);
      } else {
        state.leftShiftAnimationProgress =
            math.max(state.leftShiftAnimationProgress, 0.72);
      }
    }
  }

  /// Buduje listę rywali przed graczem na podstawie migawki symulacji [RiderPositionSnapshot].
  List<CockpitRivalAheadSample> buildRivalSamplesFromSnapshots({
    required List<RiderPositionSnapshot> snapshots,
    required String playerRiderId,
  }) {
    if (snapshots.isEmpty) return const <CockpitRivalAheadSample>[];

    RiderPositionSnapshot? player;
    for (final RiderPositionSnapshot s in snapshots) {
      if (s.riderId == playerRiderId || s.isPlayerRider) {
        player = s;
        break;
      }
    }
    player ??= snapshots.first;

    final List<CockpitRivalAheadSample> result = <CockpitRivalAheadSample>[];
    for (final RiderPositionSnapshot r in snapshots) {
      if (r.riderId == player.riderId || r.isDnf) continue;
      final double rawGap = r.distanceCoveredMeters - player.distanceCoveredMeters;
      // Uwzględniamy długość roweru (~1.72 m), by dystans koło-do-koła zaczynał się od ~0.30 m.
      final double wheelToWheelGap = rawGap - 1.72;
      if (wheelToWheelGap < 0.25 ||
          wheelToWheelGap > config.maxRivalRenderDistanceMeters) {
        continue;
      }
      final double lateralDelta =
          r.lateralOffsetRoadMeters - player.lateralOffsetRoadMeters;
      final int hash = r.riderId.hashCode;
      result.add(
        CockpitRivalAheadSample(
          riderId: r.riderId,
          riderName: r.riderName,
          bibNumber: r.bibNumber,
          jerseyColor: _parseHexColor(r.teamJerseyHexColor),
          gapAheadMeters: wheelToWheelGap,
          lateralOffsetMeters: lateralDelta,
          speedMs: r.speedMs,
          cadenceRpm: r.cadenceRpm.toDouble(),
          wheelPhaseRadians: (hash % 628) / 100.0 + state.frontWheelPhaseRadians,
          isStanding: r.powerWatts > 520,
          leanAngleRadians: (lateralDelta * 0.03).clamp(-0.18, 0.18),
        ),
      );
    }

    result.sort((a, b) => b.gapAheadMeters.compareTo(a.gapAheadMeters));
    return result;
  }

  /// Przelicza jedną klatkę kamery First-Person Cockpit i rzutuje rywali w 3D.
  FirstPersonCockpitFrameResult stepFrame(FirstPersonCockpitFrameInput input) {
    final double dt = input.dtSeconds.clamp(0.0, 0.1);
    final double safeSpeedMs = input.speedMs.clamp(0.0, 35.0);
    final double safeCadence = input.cadenceRpm.clamp(0.0, 145.0);

    // 1. Aktualizacja faz obrotu przedniego koła, korby, oddechu i drgań bruku.
    final double angularWheelVel = safeSpeedMs / config.frontWheelRadiusMeters;
    state.frontWheelPhaseRadians =
        (state.frontWheelPhaseRadians + angularWheelVel * dt) % (2.0 * math.pi);

    final double crankAngularVel = (safeCadence / 60.0) * 2.0 * math.pi;
    state.crankPhaseRadians =
        (state.crankPhaseRadians + crankAngularVel * dt) % (2.0 * math.pi);

    final double effortRatio =
        (input.powerWatts / math.max(120.0, input.ftpWatts)).clamp(0.2, 2.2);
    state.breathPhaseRadians =
        (state.breathPhaseRadians + (1.6 + effortRatio * 1.4) * dt) %
            (2.0 * math.pi);

    state.cobbleVibrationPhaseRadians =
        (state.cobbleVibrationPhaseRadians + 38.0 * dt) % (2.0 * math.pi);

    state.roadScrollMeters += safeSpeedMs * dt;

    // 2. Wygładzenie animacji kliknięcia palców na klamkomanetkach (ok. 260 ms).
    if (state.leftShiftAnimationProgress > 0.0) {
      state.leftShiftAnimationProgress =
          math.max(0.0, state.leftShiftAnimationProgress - dt * 3.8);
    }
    if (state.rightShiftAnimationProgress > 0.0) {
      state.rightShiftAnimationProgress =
          math.max(0.0, state.rightShiftAnimationProgress - dt * 3.8);
    }
    if (state.leftShiftAnimationProgress == 0.0 &&
        state.rightShiftAnimationProgress == 0.0) {
      state.activeShiftDirection = CockpitShiftDirection.none;
    }

    // 3. Wygładzenie przechyłu w zakręcie, skrętu kierownicy i danych licznika.
    final double lerpAlpha = (dt * 10.0).clamp(0.0, 1.0);
    state.smoothedLeanRadians +=
        (input.leanAngleRadians - state.smoothedLeanRadians) * lerpAlpha;
    state.smoothedSteerRadians +=
        (input.steerAngleRadians - state.smoothedSteerRadians) * lerpAlpha;
    state.smoothedPowerWatts +=
        (input.powerWatts - state.smoothedPowerWatts) * (dt * 6.0).clamp(0.0, 1.0);
    state.smoothedCadenceRpm +=
        (safeCadence - state.smoothedCadenceRpm) * (dt * 6.0).clamp(0.0, 1.0);

    // 4. Obliczenie pozycji kamery 3D na wysokości oczu kolarza.
    final double postureEyeHeight = input.isStanding
        ? math.max(input.gripPosture.eyeHeightMeters, 1.42)
        : input.gripPosture.eyeHeightMeters;

    final double bobAmplitudeMeters = config.enableDynamicHeadBob
        ? (input.isStanding ? 0.026 : 0.008)
        : 0.0;
    final double bobVerticalMeters =
        math.sin(state.crankPhaseRadians * 2.0) * bobAmplitudeMeters +
            math.sin(state.breathPhaseRadians) * 0.004;
    final double bobLateralMeters =
        math.cos(state.crankPhaseRadians) *
            (input.isStanding ? 0.032 : 0.006);

    final double cobbleJitterMeters = config.enableDynamicHeadBob
        ? math.sin(state.cobbleVibrationPhaseRadians) *
            input.surfaceRoughness *
            0.012
        : 0.0;

    final Vector3 safeTangent = input.roadTangent.length2 > 1e-6
        ? input.roadTangent.normalized()
        : Vector3(0.0, 0.0, 1.0);
    final Vector3 safeRight = input.roadLateralRight.length2 > 1e-6
        ? input.roadLateralRight.normalized()
        : Vector3(1.0, 0.0, 0.0);
    final Vector3 safeUp = input.roadSurfaceNormal.length2 > 1e-6
        ? input.roadSurfaceNormal.normalized()
        : Vector3(0.0, 1.0, 0.0);

    final Vector3 eyePosition = input.riderWorldPosition +
        safeUp * (postureEyeHeight + bobVerticalMeters + cobbleJitterMeters) +
        safeRight * bobLateralMeters +
        safeTangent * 0.16;

    // Patrzymy w przód wzdłuż drogi z lekkim pochyleniem w dół (widoczna kierownica i koło rywala).
    final double slopePitch =
        math.atan(input.gradientPercent / 100.0) * 0.25;
    final Vector3 lookTarget = eyePosition +
        safeTangent * 12.0 +
        safeUp *
            (12.0 *
                math.tan(input.gripPosture.pitchOffsetRadians + slopePitch)) +
        safeRight * (state.smoothedSteerRadians * 3.5);

    // Przechył wektora "góry" kamery w zakręcie.
    final Vector3 tiltedUp = (safeUp * math.cos(state.smoothedLeanRadians) +
            safeRight * math.sin(state.smoothedLeanRadians))
        .normalized();

    final double speedKmh = safeSpeedMs * 3.6;
    final double speedBoostFraction =
        ((speedKmh - 36.0) / 42.0).clamp(0.0, 1.0);
    final double fovYDegrees = config.baseFovYDegrees +
        input.gripPosture.fovOffsetDegrees +
        speedBoostFraction * config.maxSpeedFovBoostDegrees;

    final Camera3DConfig cameraConfig = Camera3DConfig(
      position: eyePosition,
      target: lookTarget,
      up: tiltedUp,
      fovYDegrees: fovYDegrees,
      nearPlane: 0.12,
      farPlane: 1200.0,
    );

    final double safeWidth = math.max(1.0, input.viewportSize.width);
    final double safeHeight = math.max(1.0, input.viewportSize.height);
    projection.updateCamera(
      cameraConfig,
      viewportWidth: safeWidth,
      viewportHeight: safeHeight,
    );

    // 5. Rzutowanie rywali jadących przed nami (od 30 cm w górę) do przestrzeni ekranu.
    final List<ProjectedCockpitRival> projectedRivals = <ProjectedCockpitRival>[];
    double closestGap = double.infinity;

    for (final CockpitRivalAheadSample rival in input.rivalsAhead) {
      if (rival.gapAheadMeters < 0.20 ||
          rival.gapAheadMeters > config.maxRivalRenderDistanceMeters) {
        continue;
      }
      if (rival.gapAheadMeters < closestGap) {
        closestGap = rival.gapAheadMeters;
      }

      // Odległość od oka kamery do tylnego koła rywala:
      // koło gracza jest ~0.85 m przed okiem, więc środek tylnego koła rywala to 0.85 + gap + 0.34 m.
      final double distanceFromEye = 0.85 + rival.gapAheadMeters + 0.34;
      final Vector3 rivalWheelGround = input.riderWorldPosition +
          safeTangent * (distanceFromEye + 0.16) +
          safeRight * rival.lateralOffsetMeters;

      final ProjectedPoint3D projectedGround =
          projection.worldToScreen(rivalWheelGround);
      if (!projectedGround.isInFrontOfCamera) continue;

      final Vector3 rivalWheelTop =
          rivalWheelGround + safeUp * (config.frontWheelRadiusMeters * 2.0);
      final ProjectedPoint3D projectedWheelTop =
          projection.worldToScreen(rivalWheelTop);

      final double rawWheelHeightPx =
          (projectedGround.screenY - projectedWheelTop.screenY).abs();
      final double wheelRadiusPx = (rawWheelHeightPx * 0.5).clamp(4.0, safeHeight * 0.65);

      final Vector3 rivalTorsoTop = rivalWheelGround + safeUp * 1.48;
      final ProjectedPoint3D projectedTorsoTop =
          projection.worldToScreen(rivalTorsoTop);
      final double riderTotalHeightPx =
          (projectedGround.screenY - projectedTorsoTop.screenY)
              .abs()
              .clamp(12.0, safeHeight * 1.4);

      final double torsoWidthPx = riderTotalHeightPx * 0.34;
      final double torsoHeightPx = riderTotalHeightPx * 0.44;

      final bool isTightDraftTarget =
          rival.gapAheadMeters <= 1.25 && rival.lateralOffsetMeters.abs() <= 0.55;

      projectedRivals.add(
        ProjectedCockpitRival(
          sample: rival,
          depthMeters: projectedGround.depthEye,
          rearWheelGroundScreen:
              Offset(projectedGround.screenX, projectedGround.screenY),
          wheelRadiusPx: wheelRadiusPx,
          torsoWidthPx: torsoWidthPx,
          torsoHeightPx: torsoHeightPx,
          perspectiveScale: projectedGround.perspectiveScale,
          isTightDraftTarget: isTightDraftTarget,
        ),
      );
    }

    // Painter's algorithm: najdalsi rywale najpierw, najbliżsi (30 cm) na końcu.
    projectedRivals.sort((a, b) => b.depthMeters.compareTo(a.depthMeters));

    // 6. Wyznaczenie strefy mocy Coggana (Z1-Z7) i linii horyzontu.
    final int liveWatts = state.smoothedPowerWatts.round().clamp(0, 2200);
    final int powerZone = _computePowerZone(
      watts: liveWatts.toDouble(),
      ftp: math.max(120.0, input.ftpWatts),
    );
    final Color powerZoneColor = AppColors.getPowerZoneColor(powerZone);

    final double horizonYFraction =
        (0.36 - slopePitch * 0.55 + (input.gripPosture.pitchOffsetRadians + 0.14) * 0.6)
            .clamp(0.20, 0.52);

    return FirstPersonCockpitFrameResult(
      cameraConfig: cameraConfig,
      fovYDegrees: fovYDegrees,
      horizonYFraction: horizonYFraction,
      horizonTiltRadians: -state.smoothedLeanRadians * 0.85,
      headBobVerticalOffsetPx: bobVerticalMeters * 220.0,
      headBobHorizontalOffsetPx: bobLateralMeters * 220.0,
      cobbleShakeOffsetPx: cobbleJitterMeters * 260.0,
      frontWheelPhaseRadians: state.frontWheelPhaseRadians,
      crankPhaseRadians: state.crankPhaseRadians,
      roadScrollMeters: state.roadScrollMeters,
      steerAngleRadians: state.smoothedSteerRadians,
      leftFingerShiftProgress: state.leftShiftAnimationProgress,
      rightFingerShiftProgress: state.rightShiftAnimationProgress,
      liveWatts: liveWatts,
      liveCadenceRpm: state.smoothedCadenceRpm.round().clamp(0, 160),
      liveGradientPercent: input.gradientPercent,
      liveSpeedKmh: speedKmh,
      liveHeartRateBpm: input.heartRateBpm,
      powerZone: powerZone,
      powerZoneColor: powerZoneColor,
      gearLabel: state.gearLabel,
      closestRivalGapMeters: closestGap.isFinite ? closestGap : -1.0,
      draftingSavingsPercent: input.draftingSavingsPercent,
      speedLinesIntensity:
          config.enableSpeedLines ? speedBoostFraction : 0.0,
      gripPosture: input.gripPosture,
      glovePrimaryColor: input.glovePrimaryColor,
      gloveAccentColor: input.gloveAccentColor,
      projectedRivals: projectedRivals,
    );
  }

  static int _computePowerZone({required double watts, required double ftp}) {
    final double ratio = watts / ftp;
    if (ratio < 0.55) return 1;
    if (ratio < 0.75) return 2;
    if (ratio < 0.90) return 3;
    if (ratio < 1.05) return 4;
    if (ratio < 1.20) return 5;
    if (ratio < 1.50) return 6;
    return 7;
  }

  static Color _parseHexColor(String hex) {
    final String clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final int? value = int.tryParse('FF$clean', radix: 16);
      if (value != null) return Color(value);
    } else if (clean.length == 8) {
      final int? value = int.tryParse(clean, radix: 16);
      if (value != null) return Color(value);
    }
    return AppColors.primaryAccent;
  }
}

/// Główny `CustomPainter` renderujący pełny widok 3D z pierwszej osoby (Cockpit View):
/// - Szosa i rywale jadący 30 cm przed kołem w gęstym peletonie
/// - Obracająca się opona przedniego koła pod mostkiem
/// - Trójwymiarowa karbonowa kierownica z mostkiem i owijką
/// - Zamontowany komputer Garmin / Wahoo wyświetlający na żywo waty, kadencję i nachylenie
/// - Dłonie w rękawiczkach na klamkomanetkach z animacją palców klikających zmianę biegów
class FirstPersonCockpitPainter extends CustomPainter {
  final FirstPersonCockpitFrameResult frame;
  final FirstPersonCockpitConfig config;

  const FirstPersonCockpitPainter({
    required this.frame,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // 1. Opcjonalne tło nieba, gór i perspektywicznej szosy.
    if (config.renderBackgroundRoadAndSky) {
      _paintSkyAndRoadBackground(canvas, size);
    }

    // 2. Rywale w peletonie przed nami (posortowani od najdalszych do 30 cm przed kołem).
    for (final ProjectedCockpitRival rival in frame.projectedRivals) {
      _paintRivalCyclist(canvas, size, rival);
    }

    // 3. Linie pędu powietrza przy wysokich prędkościach (> 36 km/h).
    if (frame.speedLinesIntensity > 0.02) {
      _paintSpeedTunnelLines(canvas, size, frame.speedLinesIntensity);
    }

    // 4. Przesunięcie kokpitu wynikające z pracy ciała, kadencji i drgań nawierzchni.
    final double cockpitScale = _computeCockpitScale(size);
    final double bobX = frame.headBobHorizontalOffsetPx;
    final double bobY =
        frame.headBobVerticalOffsetPx + frame.cobbleShakeOffsetPx;

    canvas.save();
    canvas.translate(bobX, bobY);
    canvas.translate(size.width * 0.5, size.height * 0.92);
    canvas.rotate(frame.steerAngleRadians * 0.45 - frame.horizonTiltRadians * 0.25);
    canvas.translate(-size.width * 0.5, -size.height * 0.92);

    // 5. Obracająca się opona przedniego koła i widelec pod mostkiem.
    _paintFrontWheelUnderStem(canvas, size, cockpitScale);

    // 6. Trójwymiarowa karbonowa kierownica, mostek i owijka.
    _paintCarbonHandlebarAndStem(canvas, size, cockpitScale);

    // 7. Zamontowany komputer rowerowy Garmin / Wahoo z telemetrią na żywo.
    _paintMountedBikeComputer(canvas, size, cockpitScale);

    // 8. Klamkomanetki i dłonie w rękawiczkach z animacją klikania zmiany biegów.
    _paintShiftersAndGlovedHands(canvas, size, cockpitScale);

    canvas.restore();
    canvas.restore();
  }

  double _computeCockpitScale(Size size) {
    final double minDim = math.min(size.width, size.height);
    return (minDim / 780.0).clamp(0.55, 1.45);
  }

  void _paintSkyAndRoadBackground(Canvas canvas, Size size) {
    final double horizonY = size.height * frame.horizonYFraction;

    // Niebo z subtelnym gradientem alpejskim
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF0B1320),
          Color(0xFF17273E),
          Color(0xFF284263),
          Color(0xFF456684),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, horizonY + 40));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizonY + 40), skyPaint);

    canvas.save();
    canvas.translate(size.width * 0.5, horizonY);
    canvas.rotate(frame.horizonTiltRadians);
    canvas.translate(-size.width * 0.5, -horizonY);

    // Zarys dalekich gór na horyzoncie
    final Path mountainPath = Path()
      ..moveTo(-80, horizonY + 12)
      ..lineTo(size.width * 0.14, horizonY - 58)
      ..lineTo(size.width * 0.30, horizonY - 18)
      ..lineTo(size.width * 0.48, horizonY - 76)
      ..lineTo(size.width * 0.68, horizonY - 24)
      ..lineTo(size.width * 0.86, horizonY - 64)
      ..lineTo(size.width + 80, horizonY + 12)
      ..close();
    canvas.drawPath(
      mountainPath,
      Paint()..color = const Color(0xFF1A2838),
    );

    // Pobocze / trawa
    final Paint vergePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF1B2B22),
          Color(0xFF121C16),
        ],
      ).createShader(
        Rect.fromLTWH(-120, horizonY, size.width + 240, size.height - horizonY + 120),
      );
    canvas.drawRect(
      Rect.fromLTWH(
        -120,
        horizonY,
        size.width + 240,
        size.height - horizonY + 120,
      ),
      vergePaint,
    );

    // Perspektywiczna wstęga asfaltu
    final double vanishX = size.width * 0.5 + frame.steerAngleRadians * 120.0;
    final double roadBottomHalfW = size.width * 0.92;
    final Path roadPath = Path()
      ..moveTo(vanishX - 18, horizonY)
      ..lineTo(vanishX + 18, horizonY)
      ..lineTo(size.width * 0.5 + roadBottomHalfW, size.height + 80)
      ..lineTo(size.width * 0.5 - roadBottomHalfW, size.height + 80)
      ..close();

    final Paint asphaltPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF282D36),
          Color(0xFF1D2129),
          Color(0xFF14171D),
        ],
      ).createShader(
        Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY + 80),
      );
    canvas.drawPath(roadPath, asphaltPaint);

    // Białe linie krawędziowe i przerywana linia środkowa z animowanym przewijaniem
    final Paint edgeLinePaint = Paint()
      ..color = const Color(0x66E5E7EB)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(vanishX - 16, horizonY),
      Offset(size.width * 0.5 - roadBottomHalfW * 0.92, size.height + 80),
      edgeLinePaint,
    );
    canvas.drawLine(
      Offset(vanishX + 16, horizonY),
      Offset(size.width * 0.5 + roadBottomHalfW * 0.92, size.height + 80),
      edgeLinePaint,
    );

    final double scrollPhase = (frame.roadScrollMeters % 8.0) / 8.0;
    final Paint dashPaint = Paint()..color = const Color(0x88F3F4F6);
    for (int i = 0; i < 12; i++) {
      final double t0 = ((i + scrollPhase) / 12.0).clamp(0.0, 1.0);
      final double t1 = ((i + scrollPhase + 0.42) / 12.0).clamp(0.0, 1.0);
      // Krzywa perspektywiczna t^2.4 daje realistyczne przyspieszanie pasów przy kole
      final double p0 = math.pow(t0, 2.4).toDouble();
      final double p1 = math.pow(t1, 2.4).toDouble();
      final double y0 = ui.lerpDouble(horizonY + 2, size.height + 40, p0)!;
      final double y1 = ui.lerpDouble(horizonY + 2, size.height + 40, p1)!;
      final double x0 = ui.lerpDouble(vanishX, size.width * 0.5, p0)!;
      final double x1 = ui.lerpDouble(vanishX, size.width * 0.5, p1)!;
      final double w0 = ui.lerpDouble(1.0, 8.0, p0)!;
      final double w1 = ui.lerpDouble(1.0, 11.0, p1)!;

      final Path dash = Path()
        ..moveTo(x0 - w0 * 0.5, y0)
        ..lineTo(x0 + w0 * 0.5, y0)
        ..lineTo(x1 + w1 * 0.5, y1)
        ..lineTo(x1 - w1 * 0.5, y1)
        ..close();
      canvas.drawPath(dash, dashPaint);
    }

    canvas.restore();
  }

  void _paintRivalCyclist(
    Canvas canvas,
    Size size,
    ProjectedCockpitRival rival,
  ) {
    final Offset ground = rival.rearWheelGroundScreen;
    final double wheelR = rival.wheelRadiusPx;
    final double torsoW = rival.torsoWidthPx;
    final double torsoH = rival.torsoHeightPx;
    final double gap = rival.sample.gapAheadMeters;

    // Przyciemnienie oddalonych kolarzy dla wrażenia głębi (Atmospheric Perspective)
    final double fogFactor = ((gap - 4.0) / 28.0).clamp(0.0, 0.48);

    canvas.save();
    canvas.translate(ground.dx, ground.dy);
    canvas.rotate(rival.sample.leanAngleRadians);

    // 1. Cień kontaktowy na asfalcie pod tylnym kołem i korbą
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, wheelR * 0.04),
        width: wheelR * 1.15,
        height: wheelR * 0.24,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.52)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );

    // 2. Obracające się tylne koło rywala (z perspektywą opony, stożka karbonowego i szprych!)
    final Offset wheelCenter = Offset(0, -wheelR);
    final double tireThickness = math.max(2.0, wheelR * 0.115);
    final double rimThickness = math.max(1.8, wheelR * 0.14);

    // Opona zewnętrzna
    canvas.drawOval(
      Rect.fromCenter(
        center: wheelCenter,
        width: tireThickness * 1.85,
        height: wheelR * 2.0,
      ),
      Paint()..color = const Color(0xFF14161A),
    );

    // Boczny pasek Tan-Wall / karbonowy stożek 50 mm
    canvas.drawOval(
      Rect.fromCenter(
        center: wheelCenter,
        width: rimThickness * 1.25,
        height: (wheelR - tireThickness) * 2.0,
      ),
      Paint()
        ..color = const Color(0xFF232832)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, tireThickness * 0.55),
    );

    // Animowane błyski obracających się szprych i kasety
    final double wheelPhase = rival.sample.wheelPhaseRadians;
    final Paint spokePaint = Paint()
      ..color = const Color(0x88CBD5E1)
      ..strokeWidth = math.max(0.8, wheelR * 0.025);
    for (int s = 0; s < 6; s++) {
      final double a = wheelPhase + (s * math.pi / 3.0);
      final double sy = math.sin(a) * (wheelR - tireThickness - 1.0);
      final double sx = math.cos(a) * (tireThickness * 0.35);
      canvas.drawLine(
        wheelCenter,
        wheelCenter + Offset(sx, sy),
        spokePaint,
      );
    }

    // Kaseta i tylna piasta
    canvas.drawCircle(
      wheelCenter + Offset(tireThickness * 0.32, 0),
      math.max(1.5, wheelR * 0.09),
      Paint()..color = const Color(0xFF94A3B8),
    );

    // 3. Rama (tylne widełki) i siodło
    final Offset saddlePos = Offset(0, -wheelR * 2.08);
    final Paint framePaint = Paint()
      ..color = const Color(0xFF2D3340)
      ..strokeWidth = math.max(1.6, wheelR * 0.075)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      wheelCenter + Offset(-tireThickness * 0.35, 0),
      saddlePos,
      framePaint,
    );
    canvas.drawLine(
      wheelCenter + Offset(tireThickness * 0.35, 0),
      saddlePos,
      framePaint,
    );

    // Siodło
    canvas.drawOval(
      Rect.fromCenter(
        center: saddlePos,
        width: math.max(6.0, torsoW * 0.34),
        height: math.max(3.0, wheelR * 0.16),
      ),
      Paint()..color = const Color(0xFF111318),
    );

    // 4. Animowane nogi kolarza pedałujące w rytmie kadencji
    final double legPhase = wheelPhase * 0.38;
    final double leftPedalY = math.sin(legPhase) * wheelR * 0.34;
    final double rightPedalY = math.sin(legPhase + math.pi) * wheelR * 0.34;
    final double hipY = saddlePos.dy - wheelR * 0.05;
    final double hipSpan = torsoW * 0.24;

    final Paint bibShortsPaint = Paint()
      ..color = const Color(0xFF151820)
      ..strokeWidth = math.max(3.0, torsoW * 0.22)
      ..strokeCap = StrokeCap.round;
    final Paint skinLegPaint = Paint()
      ..color = const Color(0xFFD6A27E)
      ..strokeWidth = math.max(2.2, torsoW * 0.16)
      ..strokeCap = StrokeCap.round;

    // Lewa noga
    final Offset leftHip = Offset(-hipSpan, hipY);
    final Offset leftKnee = Offset(-hipSpan * 1.15, hipY + wheelR * 0.48 + leftPedalY * 0.45);
    final Offset leftFoot = Offset(-hipSpan * 1.05, hipY + wheelR * 1.02 + leftPedalY);
    canvas.drawLine(leftHip, leftKnee, bibShortsPaint);
    canvas.drawLine(leftKnee, leftFoot, skinLegPaint);

    // Prawa noga
    final Offset rightHip = Offset(hipSpan, hipY);
    final Offset rightKnee = Offset(hipSpan * 1.15, hipY + wheelR * 0.48 + rightPedalY * 0.45);
    final Offset rightFoot = Offset(hipSpan * 1.05, hipY + wheelR * 1.02 + rightPedalY);
    canvas.drawLine(rightHip, rightKnee, bibShortsPaint);
    canvas.drawLine(rightKnee, rightFoot, skinLegPaint);

    // 5. Plecy i koszulka rywala (z numerem startowym i kaskiem aero)
    final double standingBob = rival.sample.isStanding
        ? math.sin(legPhase) * wheelR * 0.12
        : 0.0;
    final Offset lowerBack = Offset(0, hipY - standingBob);
    final Offset shouldersCenter = Offset(0, lowerBack.dy - torsoH);

    final Color baseJersey = Color.lerp(
      _jerseyColorFor(rival.sample),
      const Color(0xFF283344),
      fogFactor,
    )!;

    final Path torsoPath = Path()
      ..moveTo(-torsoW * 0.34, lowerBack.dy)
      ..quadraticBezierTo(
        -torsoW * 0.56,
        (lowerBack.dy + shouldersCenter.dy) * 0.5,
        -torsoW * 0.52,
        shouldersCenter.dy + torsoH * 0.12,
      )
      ..quadraticBezierTo(
        0,
        shouldersCenter.dy - torsoH * 0.08,
        torsoW * 0.52,
        shouldersCenter.dy + torsoH * 0.12,
      )
      ..quadraticBezierTo(
        torsoW * 0.56,
        (lowerBack.dy + shouldersCenter.dy) * 0.5,
        torsoW * 0.34,
        lowerBack.dy,
      )
      ..close();

    final Paint jerseyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          baseJersey,
          Color.lerp(baseJersey, Colors.black, 0.28)!,
        ],
      ).createShader(torsoPath.getBounds());
    canvas.drawPath(torsoPath, jerseyPaint);

    // Pasek drużynowy na plecach
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(0, (lowerBack.dy + shouldersCenter.dy) * 0.5),
        width: torsoW * 0.88,
        height: math.max(2.0, torsoH * 0.14),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );

    // Numer startowy na dolnej części pleców (widoczny przy bliskiej jeździe w peletonie!)
    if (torsoW > 26.0) {
      final Rect bibRect = Rect.fromCenter(
        center: Offset(0, lowerBack.dy - torsoH * 0.24),
        width: torsoW * 0.36,
        height: torsoH * 0.22,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bibRect, const Radius.circular(2.0)),
        Paint()..color = const Color(0xFFF3F4F6),
      );
      final TextPainter bibPainter = TextPainter(
        text: TextSpan(
          text: '${rival.sample.bibNumber}',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: (bibRect.height * 0.72).clamp(7.0, 18.0),
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F1115),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      bibPainter.paint(
        canvas,
        bibRect.center - Offset(bibPainter.width * 0.5, bibPainter.height * 0.5),
      );
    }

    // Kask aero na górze sylwetki
    final double helmetR = math.max(4.0, torsoW * 0.24);
    final Offset helmetCenter = Offset(0, shouldersCenter.dy - helmetR * 0.55);
    canvas.drawOval(
      Rect.fromCenter(
        center: helmetCenter,
        width: helmetR * 1.9,
        height: helmetR * 1.65,
      ),
      Paint()..color = const Color(0xFFE5E7EB),
    );
    // Otwory wentylacyjne kasku
    canvas.drawOval(
      Rect.fromCenter(
        center: helmetCenter + Offset(0, helmetR * 0.15),
        width: helmetR * 0.9,
        height: helmetR * 0.45,
      ),
      Paint()..color = const Color(0xFF1F2937),
    );

    // Subtelny znacznik tunelu aerodynamicznego (30 cm draft!)
    if (rival.isTightDraftTarget) {
      final Paint draftRingPaint = Paint()
        ..color = AppColors.cyanAccent.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, wheelR * 0.04),
          width: wheelR * 1.55,
          height: wheelR * 0.36,
        ),
        draftRingPaint,
      );
    }

    canvas.restore();
  }

  Color _jerseyColorFor(CockpitRivalAheadSample sample) {
    switch (sample.leaderJerseyType) {
      case LeaderJerseyType.yellow:
        return const Color(0xFFFACC15);
      case LeaderJerseyType.green:
        return const Color(0xFF10B981);
      case LeaderJerseyType.polkaDot:
        return const Color(0xFFF3F4F6);
      case LeaderJerseyType.rainbow:
        return const Color(0xFF38BDF8);
      case LeaderJerseyType.white:
        return const Color(0xFFE5E7EB);
      case LeaderJerseyType.none:
        return sample.jerseyColor;
    }
  }

  void _paintSpeedTunnelLines(Canvas canvas, Size size, double intensity) {
    final Offset center = Offset(size.width * 0.5, size.height * 0.42);
    final Paint linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16 * intensity)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final double phase = frame.roadScrollMeters * 0.45;
    for (int i = 0; i < 18; i++) {
      final double angle = (i / 18.0) * 2.0 * math.pi;
      // Pomijamy dolny środek zasłonięty przez kokpit
      if (angle > math.pi * 0.30 && angle < math.pi * 0.70) continue;
      final double rStart =
          size.width * (0.28 + ((i * 0.17 + phase) % 0.18));
      final double rEnd = rStart + size.width * (0.12 + intensity * 0.14);
      canvas.drawLine(
        center + Offset(math.cos(angle) * rStart, math.sin(angle) * rStart),
        center + Offset(math.cos(angle) * rEnd, math.sin(angle) * rEnd),
        linePaint,
      );
    }
  }

  void _paintFrontWheelUnderStem(
    Canvas canvas,
    Size size,
    double scale,
  ) {
    final double centerX = size.width * 0.5;
    final double wheelTopY = size.height * 0.77;
    final double wheelBottomY = size.height + 24.0;
    final double tireW = 28.0 * scale;

    // 1. Pasek obracającej się opony przedniego koła pod mostkiem
    final Rect tireRect = Rect.fromLTRB(
      centerX - tireW * 0.5,
      wheelTopY,
      centerX + tireW * 0.5,
      wheelBottomY,
    );
    final Paint tirePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0xFF0E1014),
          Color(0xFF272B33),
          Color(0xFF0E1014),
        ],
      ).createShader(tireRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(tireRect, Radius.circular(tireW * 0.45)),
      tirePaint,
    );

    // Boczne ścianki Tan-Wall opony szosowej
    final Paint tanWallPaint = Paint()
      ..color = const Color(0xFF9C7A4C)
      ..strokeWidth = 2.4 * scale;
    canvas.drawLine(
      Offset(tireRect.left + 2.5 * scale, wheelTopY + 12 * scale),
      Offset(tireRect.left + 2.5 * scale, wheelBottomY),
      tanWallPaint,
    );
    canvas.drawLine(
      Offset(tireRect.right - 2.5 * scale, wheelTopY + 12 * scale),
      Offset(tireRect.right - 2.5 * scale, wheelBottomY),
      tanWallPaint,
    );

    // Animowane paski bieżnika / ślad obrotu opony zależne od frontWheelPhaseRadians
    final double treadSpacing = 18.0 * scale;
    final double phaseOffset =
        (frame.frontWheelPhaseRadians / (2.0 * math.pi)) * treadSpacing * 3.0;
    final Paint treadPaint = Paint()
      ..color = const Color(0x554B5563)
      ..strokeWidth = 2.2 * scale;
    for (double y = wheelTopY + (phaseOffset % treadSpacing);
        y < wheelBottomY;
        y += treadSpacing) {
      canvas.drawLine(
        Offset(centerX - tireW * 0.28, y),
        Offset(centerX + tireW * 0.28, y + 3.0 * scale),
        treadPaint,
      );
    }

    // 2. Karbonowe golenie przedniego widelca obejmujące oponę
    final Paint forkPaint = Paint()
      ..color = const Color(0xFF151820)
      ..strokeWidth = 13.0 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX - 18.0 * scale, size.height * 0.80),
      Offset(centerX - 28.0 * scale, wheelBottomY),
      forkPaint,
    );
    canvas.drawLine(
      Offset(centerX + 18.0 * scale, size.height * 0.80),
      Offset(centerX + 28.0 * scale, wheelBottomY),
      forkPaint,
    );
  }

  void _paintCarbonHandlebarAndStem(
    Canvas canvas,
    Size size,
    double scale,
  ) {
    final double cx = size.width * 0.5;
    final double barY = size.height * 0.845;
    final double halfSpan =
        math.min(size.width * 0.42, 235.0 * scale);

    // 1. Mostek kierownicy (3D Carbon Stem) łączący rurę sterową z kierownicą
    final Path stemPath = Path()
      ..moveTo(cx - 19.0 * scale, size.height + 10)
      ..lineTo(cx - 17.0 * scale, barY - 12.0 * scale)
      ..lineTo(cx + 17.0 * scale, barY - 12.0 * scale)
      ..lineTo(cx + 19.0 * scale, size.height + 10)
      ..close();
    canvas.drawPath(
      stemPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            Color(0xFF0E1015),
            Color(0xFF282D38),
            Color(0xFF12151C),
          ],
        ).createShader(stemPath.getBounds()),
    );

    // Kapselek sterów (Top Cap) z akcentem złota
    canvas.drawCircle(
      Offset(cx, size.height * 0.935),
      12.5 * scale,
      Paint()..color = const Color(0xFF1A1E27),
    );
    canvas.drawCircle(
      Offset(cx, size.height * 0.935),
      12.5 * scale,
      Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * scale,
    );

    // 2. Zintegrowana płaska kierownica karbonowa (Aero Carbon Handlebar)
    final double barThickness = 26.0 * scale;
    final Path barPath = Path()
      ..moveTo(cx - halfSpan, barY + 26.0 * scale)
      ..quadraticBezierTo(
        cx - halfSpan * 0.65,
        barY - barThickness * 0.55,
        cx,
        barY - barThickness * 0.50,
      )
      ..quadraticBezierTo(
        cx + halfSpan * 0.65,
        barY - barThickness * 0.55,
        cx + halfSpan,
        barY + 26.0 * scale,
      )
      ..lineTo(cx + halfSpan - 12.0 * scale, barY + 46.0 * scale)
      ..quadraticBezierTo(
        cx + halfSpan * 0.62,
        barY + barThickness * 0.58,
        cx,
        barY + barThickness * 0.54,
      )
      ..quadraticBezierTo(
        cx - halfSpan * 0.62,
        barY + barThickness * 0.58,
        cx - halfSpan + 12.0 * scale,
        barY + 46.0 * scale,
      )
      ..close();

    canvas.drawPath(
      barPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF323846),
            Color(0xFF181B22),
            Color(0xFF0C0E13),
          ],
        ).createShader(barPath.getBounds()),
    );

    // Subtelny połysk splotu karbonowego 3K na górnej płaszczyźnie kierownicy
    canvas.drawLine(
      Offset(cx - halfSpan * 0.72, barY - 4.0 * scale),
      Offset(cx + halfSpan * 0.72, barY - 4.0 * scale),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..strokeWidth = 2.0 * scale
        ..strokeCap = StrokeCap.round,
    );

    // Owijka na zewnętrznych łukach kierownicy (perforowana czerń + burgund)
    final Paint tapePaint = Paint()
      ..color = const Color(0xFF14161B)
      ..strokeWidth = 24.0 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - halfSpan * 0.62, barY + 6.0 * scale),
      Offset(cx - halfSpan * 0.98, barY + 40.0 * scale),
      tapePaint,
    );
    canvas.drawLine(
      Offset(cx + halfSpan * 0.62, barY + 6.0 * scale),
      Offset(cx + halfSpan * 0.98, barY + 40.0 * scale),
      tapePaint,
    );

    // Śruby płyty czołowej mostka (4 tytanowe śruby)
    final Paint boltPaint = Paint()..color = const Color(0xFF94A3B8);
    for (final double dx in <double>[-11.0, 11.0]) {
      for (final double dy in <double>[-7.0, 8.0]) {
        canvas.drawCircle(
          Offset(cx + dx * scale, barY + dy * scale),
          2.0 * scale,
          boltPaint,
        );
      }
    }
  }

  void _paintMountedBikeComputer(
    Canvas canvas,
    Size size,
    double scale,
  ) {
    final double cx = size.width * 0.5;
    final double mountY = size.height * 0.775;
    final bool isWahoo = config.computerModel == BikeComputerModel.wahooElemnt;

    // Uchwyt wysunięty przed mostek (Out-Front Mount)
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, mountY + 34.0 * scale),
        width: 16.0 * scale,
        height: 28.0 * scale,
      ),
      Paint()..color = const Color(0xFF151820),
    );

    final double bodyW = (isWahoo ? 124.0 : 128.0) * scale;
    final double bodyH = (isWahoo ? 90.0 : 96.0) * scale;
    final Rect bodyRect = Rect.fromCenter(
      center: Offset(cx, mountY),
      width: bodyW,
      height: bodyH,
    );

    // Cień pod obudową komputera
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bodyRect.shift(Offset(0, 5.0 * scale)),
        Radius.circular(14.0 * scale),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
    );

    // Obudowa Garmin / Wahoo
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(14.0 * scale)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF282D38),
            Color(0xFF12151B),
          ],
        ).createShader(bodyRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(14.0 * scale)),
      Paint()
        ..color = AppTheme.borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * scale,
    );

    // Ekran LCD komputera rowerowego
    final Rect screenRect = bodyRect.deflate(6.5 * scale);
    canvas.drawRRect(
      RRect.fromRectAndRadius(screenRect, Radius.circular(9.0 * scale)),
      Paint()..color = const Color(0xFF0A0D12),
    );

    // Wahoo QuickLook LEDs na górze ekranu lub pasek Garmin Solar
    if (isWahoo) {
      const int ledCount = 7;
      final double ledW = (screenRect.width - 16.0 * scale) / ledCount;
      for (int i = 0; i < ledCount; i++) {
        final bool lit = (i + 1) <= frame.powerZone;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              screenRect.left + 8.0 * scale + i * ledW,
              screenRect.top + 3.5 * scale,
              ledW - 2.5 * scale,
              4.0 * scale,
            ),
            Radius.circular(2.0 * scale),
          ),
          Paint()
            ..color = lit
                ? AppColors.getPowerZoneColor(i + 1)
                : const Color(0xFF1F242E),
        );
      }
    } else {
      // Garmin branding strip + status
      final TextPainter brandPainter = TextPainter(
        text: TextSpan(
          text: 'GARMIN • ${frame.gearLabel}',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: (7.5 * scale).clamp(6.0, 11.0),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      brandPainter.paint(
        canvas,
        Offset(
          screenRect.center.dx - brandPainter.width * 0.5,
          screenRect.top + 3.0 * scale,
        ),
      );
    }

    // Główna wartość: WATY NA ŻYWO (kolorowane wg strefy Coggana)
    final TextPainter wattsPainter = TextPainter(
      text: TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '${frame.liveWatts}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: (24.0 * scale).clamp(16.0, 34.0),
              fontWeight: FontWeight.w800,
              color: frame.powerZoneColor,
              fontFeatures: const <ui.FontFeature>[
                ui.FontFeature.tabularFigures(),
              ],
            ),
          ),
          TextSpan(
            text: 'W',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: (11.0 * scale).clamp(8.0, 15.0),
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    wattsPainter.paint(
      canvas,
      Offset(
        screenRect.center.dx - wattsPainter.width * 0.5,
        screenRect.top + 14.0 * scale,
      ),
    );

    // Linia podziału danych na ekranie
    final double splitY = screenRect.top + screenRect.height * 0.57;
    canvas.drawLine(
      Offset(screenRect.left + 6.0 * scale, splitY),
      Offset(screenRect.right - 6.0 * scale, splitY),
      Paint()
        ..color = AppTheme.borderColor
        ..strokeWidth = 1.0,
    );
    canvas.drawLine(
      Offset(screenRect.center.dx, splitY),
      Offset(screenRect.center.dx, screenRect.bottom - 4.0 * scale),
      Paint()
        ..color = AppTheme.borderColor
        ..strokeWidth = 1.0,
    );

    // Lewa dolna komórka: KADENCJA (RPM)
    _paintComputerCell(
      canvas: canvas,
      rect: Rect.fromLTRB(
        screenRect.left + 4.0 * scale,
        splitY + 2.0 * scale,
        screenRect.center.dx - 2.0 * scale,
        screenRect.bottom - 3.0 * scale,
      ),
      label: 'CAD',
      value: '${frame.liveCadenceRpm}',
      valueColor: AppColors.textPrimary,
      scale: scale,
    );

    // Prawa dolna komórka: NACHYLENIE (%)
    final String gradPrefix = frame.liveGradientPercent >= 0 ? '+' : '';
    final Color gradColor = frame.liveGradientPercent >= 6.0
        ? AppColors.crimsonAlert
        : frame.liveGradientPercent >= 2.5
            ? AppColors.amberWarning
            : frame.liveGradientPercent <= -2.0
                ? AppColors.accentBlue
                : AppColors.statusSuccess;

    _paintComputerCell(
      canvas: canvas,
      rect: Rect.fromLTRB(
        screenRect.center.dx + 2.0 * scale,
        splitY + 2.0 * scale,
        screenRect.right - 4.0 * scale,
        screenRect.bottom - 3.0 * scale,
      ),
      label: 'GRAD',
      value: '$gradPrefix${frame.liveGradientPercent.toStringAsFixed(1)}%',
      valueColor: gradColor,
      scale: scale,
    );
  }

  void _paintComputerCell({
    required Canvas canvas,
    required Rect rect,
    required String label,
    required String value,
    required Color valueColor,
    required double scale,
  }) {
    final TextPainter labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: (6.8 * scale).clamp(5.5, 10.0),
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(
      canvas,
      Offset(rect.center.dx - labelPainter.width * 0.5, rect.top + 1.0),
    );

    final TextPainter valPainter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: (12.0 * scale).clamp(9.0, 17.0),
          fontWeight: FontWeight.w800,
          color: valueColor,
          fontFeatures: const <ui.FontFeature>[ui.FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    valPainter.paint(
      canvas,
      Offset(
        rect.center.dx - valPainter.width * 0.5,
        rect.bottom - valPainter.height - 1.0,
      ),
    );
  }

  void _paintShiftersAndGlovedHands(
    Canvas canvas,
    Size size,
    double scale,
  ) {
    final double cx = size.width * 0.5;
    final double barY = size.height * 0.845;
    final double halfSpan = math.min(size.width * 0.42, 235.0 * scale);

    final double spread = frame.gripPosture.handSpreadFactor;
    final double vShift = frame.gripPosture.handVerticalOffset * 120.0 * scale;

    final Offset leftHoodPos = Offset(
      cx - halfSpan * 0.84 * spread,
      barY - 12.0 * scale + vShift,
    );
    final Offset rightHoodPos = Offset(
      cx + halfSpan * 0.84 * spread,
      barY - 12.0 * scale + vShift,
    );

    _paintSingleShifterAndHand(
      canvas: canvas,
      hoodPos: leftHoodPos,
      isLeft: true,
      shiftClickProgress: frame.leftFingerShiftProgress,
      scale: scale,
    );
    _paintSingleShifterAndHand(
      canvas: canvas,
      hoodPos: rightHoodPos,
      isLeft: false,
      shiftClickProgress: frame.rightFingerShiftProgress,
      scale: scale,
    );
  }

  void _paintSingleShifterAndHand({
    required Canvas canvas,
    required Offset hoodPos,
    required bool isLeft,
    required double shiftClickProgress,
    required double scale,
  }) {
    final double dir = isLeft ? 1.0 : -1.0;

    canvas.save();
    canvas.translate(hoodPos.dx, hoodPos.dy);
    // Pro-style lekko pochylone do wewnątrz klamkomanetki (inward flare)
    canvas.rotate(dir * 0.14);

    // 1. Gumowy korpus klamkomanetki (STI Hood)
    final Rect hoodRect = Rect.fromCenter(
      center: Offset(0, -10.0 * scale),
      width: 30.0 * scale,
      height: 56.0 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(hoodRect, Radius.circular(11.0 * scale)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF2B303A),
            Color(0xFF14171D),
          ],
        ).createShader(hoodRect),
    );

    // 2. Karbonowa łopatka dźwigni hamulca / zmiany biegów (wychyla się przy kliknięciu)
    final double leverSweep = shiftClickProgress * 9.0 * scale;
    final Path leverPath = Path()
      ..moveTo(-4.0 * scale, 12.0 * scale)
      ..lineTo(dir * (5.0 * scale + leverSweep), 52.0 * scale)
      ..lineTo(dir * (11.0 * scale + leverSweep), 50.0 * scale)
      ..lineTo(5.0 * scale, 12.0 * scale)
      ..close();
    canvas.drawPath(
      leverPath,
      Paint()..color = const Color(0xFF0C0E12),
    );

    // 3. Rękawiczka kolarska obejmująca klamkomanetkę
    final Rect glovePalmRect = Rect.fromCenter(
      center: Offset(-dir * 10.0 * scale, 16.0 * scale),
      width: 44.0 * scale,
      height: 54.0 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(glovePalmRect, Radius.circular(14.0 * scale)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            frame.glovePrimaryColor,
            Color.lerp(frame.glovePrimaryColor, Colors.black, 0.35)!,
          ],
        ).createShader(glovePalmRect),
    );

    // Pasek drużynowy na mankiecie rękawiczki
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-dir * 12.0 * scale, 38.0 * scale),
          width: 40.0 * scale,
          height: 8.5 * scale,
        ),
        Radius.circular(4.0 * scale),
      ),
      Paint()..color = frame.gloveAccentColor,
    );

    // 4. Palce w rękawiczce z animacją kliknięcia zmiany biegu!
    // Palec wskazujący i środkowy zginają się ku łopatce Di2 przy zmianie przełożenia
    final double fingerPressOffset = shiftClickProgress * 8.5 * scale;
    final Paint fingerPaint = Paint()
      ..color = const Color(0xFFC99573)
      ..strokeWidth = 9.5 * scale
      ..strokeCap = StrokeCap.round;
    final Paint gloveFingerCapPaint = Paint()
      ..color = frame.glovePrimaryColor
      ..strokeWidth = 10.5 * scale
      ..strokeCap = StrokeCap.round;

    for (int f = 0; f < 2; f++) {
      final double fy = (-2.0 + f * 12.0) * scale;
      final Offset knuckle = Offset(dir * 6.0 * scale, fy);
      final Offset fingerTip = Offset(
        dir * (18.0 * scale - fingerPressOffset),
        fy + 3.0 * scale + fingerPressOffset * 0.4,
      );
      canvas.drawLine(knuckle, fingerTip, fingerPaint);
      // Krótki mankiet palca rękawiczki
      canvas.drawLine(
        knuckle,
        Offset.lerp(knuckle, fingerTip, 0.45)!,
        gloveFingerCapPaint,
      );
    }

    // Kciuk oparty na wewnętrznej stronie klamki
    canvas.drawLine(
      Offset(dir * 2.0 * scale, -14.0 * scale),
      Offset(dir * 10.0 * scale, -26.0 * scale),
      fingerPaint,
    );

    // Błysk potwierdzenia elektronicznej zmiany biegu (Di2/eTap)
    if (shiftClickProgress > 0.15) {
      canvas.drawCircle(
        Offset(dir * 12.0 * scale, 4.0 * scale),
        (5.5 + shiftClickProgress * 4.0) * scale,
        Paint()
          ..color = (isLeft ? AppColors.amberWarning : AppColors.cyanAccent)
              .withValues(alpha: shiftClickProgress * 0.75)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FirstPersonCockpitPainter oldDelegate) {
    return oldDelegate.frame != frame || oldDelegate.config != config;
  }
}

/// Responsywny widget produkcyjny prezentujący widok **First-Person Cockpit View (Pro Cyclist Camera)**
/// z pełnymi stanami `hover` / `active` / `disabled` / `focus`, obsługą `LayoutBuilder`
/// dla `390x844`, `1024x768` i `1600x900` oraz interaktywną zmianą biegów i licznika.
class FirstPersonCockpitViewportWidget extends StatefulWidget {
  final List<RiderPositionSnapshot> snapshots;
  final String playerRiderId;
  final BikeComputerModel initialComputerModel;
  final CockpitGripPosture initialGripPosture;
  final double initialPowerWatts;
  final double initialCadenceRpm;
  final double initialGradientPercent;
  final double initialSpeedKmh;
  final bool showInteractiveControls;
  final bool initialShowCornerGForceHud;

  const FirstPersonCockpitViewportWidget({
    super.key,
    this.snapshots = const <RiderPositionSnapshot>[],
    this.playerRiderId = 'rider_0',
    this.initialComputerModel = BikeComputerModel.garminEdge,
    this.initialGripPosture = CockpitGripPosture.hoods,
    this.initialPowerWatts = 385.0,
    this.initialCadenceRpm = 94.0,
    this.initialGradientPercent = 6.2,
    this.initialSpeedKmh = 38.4,
    this.showInteractiveControls = true,
    this.initialShowCornerGForceHud = false,
  });

  @override
  State<FirstPersonCockpitViewportWidget> createState() =>
      _FirstPersonCockpitViewportWidgetState();
}

class _FirstPersonCockpitViewportWidgetState
    extends State<FirstPersonCockpitViewportWidget>
    with SingleTickerProviderStateMixin {
  late final FirstPersonCockpitCameraRenderer _renderer;
  late Ticker _ticker;
  Duration _lastTick = Duration.zero;
  late BikeComputerModel _computerModel;
  late CockpitGripPosture _gripPosture;
  FirstPersonCockpitFrameResult? _currentFrame;
  double _pelotonPackDensityMeters = 0.30; // Domyślnie gęsty peleton: 30 cm!
  late bool _showCornerGForceHud;
  double _peakCornerLateralG = 0.0;
  double _peakCornerLeanDegrees = 0.0;
  CornerSurfaceGripCondition _cornerSurfaceGrip =
      CornerSurfaceGripCondition.dryTarmac;

  @override
  void initState() {
    super.initState();
    _computerModel = widget.initialComputerModel;
    _gripPosture = widget.initialGripPosture;
    _showCornerGForceHud = widget.initialShowCornerGForceHud;
    _renderer = FirstPersonCockpitCameraRenderer(
      config: FirstPersonCockpitConfig(
        computerModel: _computerModel,
      ),
    );
    _stepSimulation(1.0 / 60.0, const Size(1024, 600));
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final double dt = _lastTick == Duration.zero
        ? (1.0 / 60.0)
        : ((elapsed - _lastTick).inMicroseconds / 1000000.0).clamp(0.001, 0.05);
    _lastTick = elapsed;
    if (!mounted) return;
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final Size viewportSize = box != null && box.hasSize
        ? box.size
        : const Size(1024, 600);
    setState(() {
      _stepSimulation(dt, viewportSize);
    });
  }

  void _stepSimulation(double dt, Size viewportSize) {
    RiderPositionSnapshot? player;
    if (widget.snapshots.isNotEmpty) {
      for (final RiderPositionSnapshot s in widget.snapshots) {
        if (s.riderId == widget.playerRiderId || s.isPlayerRider) {
          player = s;
          break;
        }
      }
      player ??= widget.snapshots.first;
    }

    final List<CockpitRivalAheadSample> rivals = widget.snapshots.isNotEmpty
        ? _renderer.buildRivalSamplesFromSnapshots(
            snapshots: widget.snapshots,
            playerRiderId: widget.playerRiderId,
          )
        : _buildDensePelotonDemoRivals(
            closestGapMeters: _pelotonPackDensityMeters,
            wheelPhase: _renderer.state.frontWheelPhaseRadians,
          );

    final double speedMs =
        player != null ? player.speedMs : (widget.initialSpeedKmh / 3.6);
    final double powerWatts =
        player != null ? player.powerWatts.toDouble() : widget.initialPowerWatts;
    final double cadenceRpm =
        player != null ? player.cadenceRpm.toDouble() : widget.initialCadenceRpm;
    final double gradient =
        player != null ? player.currentGradientPercent : widget.initialGradientPercent;

    _currentFrame = _renderer.stepFrame(
      FirstPersonCockpitFrameInput(
        dtSeconds: dt,
        viewportSize: viewportSize,
        riderWorldPosition: Vector3.zero(),
        roadTangent: Vector3(0.0, 0.0, 1.0),
        roadLateralRight: Vector3(1.0, 0.0, 0.0),
        roadSurfaceNormal: Vector3(0.0, 1.0, 0.0),
        speedMs: speedMs,
        powerWatts: powerWatts,
        cadenceRpm: cadenceRpm,
        gradientPercent: gradient,
        heartRateBpm: player?.heartRateBpm ?? 166,
        draftingSavingsPercent: player?.draftingSavingsPercent ?? 34.0,
        gripPosture: _gripPosture,
        rivalsAhead: rivals,
      ),
    );
  }

  List<CockpitRivalAheadSample> _buildDensePelotonDemoRivals({
    required double closestGapMeters,
    required double wheelPhase,
  }) {
    return <CockpitRivalAheadSample>[
      CockpitRivalAheadSample(
        riderId: 'rival_1',
        riderName: 'T. Pogacar',
        bibNumber: 1,
        jerseyColor: const Color(0xFF1F2937),
        leaderJerseyType: LeaderJerseyType.yellow,
        gapAheadMeters: closestGapMeters,
        lateralOffsetMeters: 0.04,
        speedMs: widget.initialSpeedKmh / 3.6,
        cadenceRpm: 96.0,
        wheelPhaseRadians: wheelPhase + 0.4,
      ),
      CockpitRivalAheadSample(
        riderId: 'rival_2',
        riderName: 'J. Vingegaard',
        bibNumber: 11,
        jerseyColor: const Color(0xFFEAB308),
        gapAheadMeters: closestGapMeters + 1.35,
        lateralOffsetMeters: -0.62,
        speedMs: widget.initialSpeedKmh / 3.6,
        cadenceRpm: 94.0,
        wheelPhaseRadians: wheelPhase + 1.8,
      ),
      CockpitRivalAheadSample(
        riderId: 'rival_3',
        riderName: 'R. Evenepoel',
        bibNumber: 21,
        jerseyColor: const Color(0xFF2563EB),
        leaderJerseyType: LeaderJerseyType.white,
        gapAheadMeters: closestGapMeters + 1.90,
        lateralOffsetMeters: 0.68,
        speedMs: widget.initialSpeedKmh / 3.6,
        cadenceRpm: 92.0,
        wheelPhaseRadians: wheelPhase + 3.1,
      ),
      CockpitRivalAheadSample(
        riderId: 'rival_4',
        riderName: 'M. van der Poel',
        bibNumber: 31,
        jerseyColor: AppColors.primaryAccent,
        leaderJerseyType: LeaderJerseyType.rainbow,
        gapAheadMeters: closestGapMeters + 4.20,
        lateralOffsetMeters: -0.22,
        speedMs: widget.initialSpeedKmh / 3.6,
        cadenceRpm: 98.0,
        wheelPhaseRadians: wheelPhase + 4.4,
        isStanding: true,
      ),
    ];
  }

  void _switchComputerModel(BikeComputerModel model) {
    setState(() {
      _computerModel = model;
      _renderer.config = _renderer.config.copyWith(computerModel: model);
    });
  }

  void _switchPosture(CockpitGripPosture posture) {
    setState(() {
      _gripPosture = posture;
    });
  }

  @override
  Widget build(BuildContext context) {
    final FirstPersonCockpitFrameResult? frame = _currentFrame;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 540;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: <Widget>[
              if (frame != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: FirstPersonCockpitPainter(
                      frame: frame,
                      config: _renderer.config,
                    ),
                  ),
                ),
              if (frame != null)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: _buildTopTelemetryBanner(frame, isCompact),
                ),
              if (frame != null && _showCornerGForceHud)
                Positioned(
                  top: isCompact ? 96 : 62,
                  right: 12,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isCompact ? 248 : 300,
                    ),
                    child: CornerGForceAndLeanAngleTelemetryHud(
                      data: _buildCornerTelemetryData(frame),
                      isVisible: _showCornerGForceHud,
                      compactOverlay: true,
                      isExpanded: !isCompact,
                      onResetPeaks: () {
                        setState(() {
                          _peakCornerLateralG = 0.0;
                          _peakCornerLeanDegrees = 0.0;
                        });
                      },
                      onSurfaceChanged: (CornerSurfaceGripCondition next) {
                        setState(() {
                          _cornerSurfaceGrip = next;
                        });
                      },
                      onToggleVisibility: () {
                        setState(() {
                          _showCornerGForceHud = false;
                        });
                      },
                    ),
                  ),
                ),
              if (widget.showInteractiveControls)
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: _buildBottomControlsBar(isCompact),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopTelemetryBanner(
    FirstPersonCockpitFrameResult frame,
    bool isCompact,
  ) {
    final bool hasWheelAhead = frame.closestRivalGapMeters > 0;
    final String gapText = hasWheelAhead
        ? '${(frame.closestRivalGapMeters * 100).round()} cm'
        : 'BRAK';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.visibility_rounded,
                size: 16,
                color: AppColors.goldAccent,
              ),
              const SizedBox(width: 8),
              Text(
                isCompact ? 'COCKPIT 3D' : 'PRO CYCLIST COCKPIT 3D',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasWheelAhead && frame.closestRivalGapMeters <= 0.6
                  ? AppColors.cyanAccent
                  : AppTheme.borderColor,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.air_rounded,
                size: 16,
                color: hasWheelAhead
                    ? AppColors.cyanAccent
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'KOŁO PRZED TOBĄ: $gapText',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFeatures: <ui.FontFeature>[ui.FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControlsBar(bool isCompact) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _CockpitActionChip(
            label: 'Bieg - (L)',
            icon: Icons.arrow_downward_rounded,
            isActive: false,
            onTap: () {
              setState(() {
                _renderer.triggerGearShift(CockpitShiftDirection.downshift);
              });
            },
          ),
          const SizedBox(width: 6),
          _CockpitActionChip(
            label: 'Bieg + (R)',
            icon: Icons.arrow_upward_rounded,
            isActive: false,
            onTap: () {
              setState(() {
                _renderer.triggerGearShift(CockpitShiftDirection.upshift);
              });
            },
          ),
          const SizedBox(width: 10),
          for (final CockpitGripPosture posture in CockpitGripPosture.values) ...[
            _CockpitActionChip(
              label: isCompact ? posture.shortLabel : posture.label,
              isActive: _gripPosture == posture,
              onTap: () => _switchPosture(posture),
            ),
            const SizedBox(width: 6),
          ],
          const SizedBox(width: 4),
          _CockpitActionChip(
            label: _computerModel == BikeComputerModel.garminEdge
                ? 'Garmin'
                : 'Wahoo',
            icon: Icons.speed_rounded,
            isActive: true,
            onTap: () => _switchComputerModel(
              _computerModel == BikeComputerModel.garminEdge
                  ? BikeComputerModel.wahooElemnt
                  : BikeComputerModel.garminEdge,
            ),
          ),
          if (widget.snapshots.isEmpty) ...<Widget>[
            const SizedBox(width: 6),
            _CockpitActionChip(
              label: _pelotonPackDensityMeters <= 0.4
                  ? '30 cm Peleton'
                  : '1.8 m Odstęp',
              icon: Icons.groups_rounded,
              isActive: _pelotonPackDensityMeters <= 0.4,
              onTap: () {
                setState(() {
                  _pelotonPackDensityMeters =
                      _pelotonPackDensityMeters <= 0.4 ? 1.80 : 0.30;
                });
              },
            ),
          ],
          const SizedBox(width: 6),
          _CockpitActionChip(
            label: _showCornerGForceHud ? 'G-Force: ON' : 'G-Force: OFF',
            icon: Icons.tire_repair_rounded,
            isActive: _showCornerGForceHud,
            onTap: () {
              setState(() {
                _showCornerGForceHud = !_showCornerGForceHud;
              });
            },
          ),
        ],
      ),
    );
  }

  CornerGForceAndLeanTelemetryData _buildCornerTelemetryData(
    FirstPersonCockpitFrameResult frame,
  ) {
    final double leanRad = _renderer.state.smoothedLeanRadians != 0.0
        ? _renderer.state.smoothedLeanRadians
        : -frame.horizonTiltRadians;
    final CornerGForceAndLeanTelemetryData telemetry =
        CornerGForcePhysicsCalculator.fromCameraMotion(
      speedKmh: frame.liveSpeedKmh,
      leanAngleRadians: leanRad,
      source: CornerTelemetryCameraSource.firstPersonCockpit,
      surface: _cornerSurfaceGrip,
      previousPeakG: _peakCornerLateralG,
      previousPeakLeanDeg: _peakCornerLeanDegrees,
    );
    _peakCornerLateralG = telemetry.peakLateralG;
    _peakCornerLeanDegrees = telemetry.peakLeanDegrees;
    return telemetry;
  }
}

class _CockpitActionChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback? onTap;

  const _CockpitActionChip({
    required this.label,
    this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_CockpitActionChip> createState() => _CockpitActionChipState();
}

class _CockpitActionChipState extends State<_CockpitActionChip> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onTap == null;
    final Color bgColor = isDisabled
        ? AppColors.surface.withValues(alpha: 0.45)
        : widget.isActive
            ? AppColors.primaryAccent
            : _isHovered
                ? AppColors.surfaceLight
                : AppColors.surface.withValues(alpha: 0.90);

    final Color borderColor = isDisabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _isFocused
            ? AppColors.goldAccent
            : widget.isActive
                ? AppColors.goldAccent.withValues(alpha: 0.75)
                : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: !isDisabled,
      onShowHoverHighlight: (bool hover) => setState(() => _isHovered = hover),
      onShowFocusHighlight: (bool focus) => setState(() => _isFocused = focus),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.icon != null) ...<Widget>[
                Icon(
                  widget.icon,
                  size: 14,
                  color: isDisabled
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: isDisabled
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
