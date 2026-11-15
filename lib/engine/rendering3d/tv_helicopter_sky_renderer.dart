// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import 'scene_3d_math_projection.dart';

// =============================================================================
// 1. TRYBY LOTU I KONFIGURACJA HELIKOPTERA TELEWIZYJNEGO
// =============================================================================

/// Tryb lotu helikoptera telewizyjnego krążącego nad czołem wyścigu.
enum TvHelicopterFlightMode {
  /// Klasyczne krążenie po orbicie nad czołową grupą lub ucieczką.
  orbitingLeadGroup('Orbita nad czołem'),

  /// Lot ósemkowy wzdłuż ucieczki zapewniający ciągłe ujęcia z boku.
  trackingBreakaway('Śledzenie ucieczki'),

  /// Niski przelot na finiszu lub podczas ataku na premii górskiej.
  lowFlybySprint('Niski przelot TV'),

  /// Zawis nad szczytem podjazdu Hors Catégorie.
  hoveringClimbSummit('Zawis nad szczytem');

  final String labelPl;

  const TvHelicopterFlightMode(this.labelPl);
}

/// Konfiguracja parametrów lotu, wirników, cienia oraz podmuchu wiatru.
class TvHelicopterConfig {
  final bool enabled;
  final double orbitRadiusMeters;
  final double cruiseAltitudeMeters;
  final double orbitAngularSpeedRadPerSec;
  final double mainRotorRpm;
  final double tailRotorRpm;
  final double mainRotorRadiusMeters;
  final double tailRotorRadiusMeters;
  final double fuselageLengthMeters;
  final double fuselageWidthMeters;
  final bool enableRoadShadow;
  final bool enableRotorDownwashWind;
  final double downwashInfluenceRadiusMeters;
  final double maxDownwashSwayMeters;
  final bool showBroadcastCallSign;
  final String callSign;
  final Color fuselagePrimaryColor;
  final Color fuselageAccentColor;
  final Color broadcastStripeColor;

  const TvHelicopterConfig({
    this.enabled = true,
    this.orbitRadiusMeters = 36.0,
    this.cruiseAltitudeMeters = 22.0,
    this.orbitAngularSpeedRadPerSec = 0.44,
    this.mainRotorRpm = 390.0,
    this.tailRotorRpm = 1860.0,
    this.mainRotorRadiusMeters = 5.35,
    this.tailRotorRadiusMeters = 1.05,
    this.fuselageLengthMeters = 9.4,
    this.fuselageWidthMeters = 1.95,
    this.enableRoadShadow = true,
    this.enableRotorDownwashWind = true,
    this.downwashInfluenceRadiusMeters = 46.0,
    this.maxDownwashSwayMeters = 1.35,
    this.showBroadcastCallSign = true,
    this.callSign = 'TV HELI 1',
    this.fuselagePrimaryColor = AppColors.surface,
    this.fuselageAccentColor = AppColors.crimsonAlert,
    this.broadcastStripeColor = AppColors.goldAccent,
  });

  TvHelicopterConfig copyWith({
    bool? enabled,
    double? orbitRadiusMeters,
    double? cruiseAltitudeMeters,
    double? orbitAngularSpeedRadPerSec,
    double? mainRotorRpm,
    double? tailRotorRpm,
    bool? enableRoadShadow,
    bool? enableRotorDownwashWind,
    double? downwashInfluenceRadiusMeters,
    double? maxDownwashSwayMeters,
    bool? showBroadcastCallSign,
    String? callSign,
  }) {
    return TvHelicopterConfig(
      enabled: enabled ?? this.enabled,
      orbitRadiusMeters: orbitRadiusMeters ?? this.orbitRadiusMeters,
      cruiseAltitudeMeters: cruiseAltitudeMeters ?? this.cruiseAltitudeMeters,
      orbitAngularSpeedRadPerSec:
          orbitAngularSpeedRadPerSec ?? this.orbitAngularSpeedRadPerSec,
      mainRotorRpm: mainRotorRpm ?? this.mainRotorRpm,
      tailRotorRpm: tailRotorRpm ?? this.tailRotorRpm,
      mainRotorRadiusMeters: mainRotorRadiusMeters,
      tailRotorRadiusMeters: tailRotorRadiusMeters,
      fuselageLengthMeters: fuselageLengthMeters,
      fuselageWidthMeters: fuselageWidthMeters,
      enableRoadShadow: enableRoadShadow ?? this.enableRoadShadow,
      enableRotorDownwashWind:
          enableRotorDownwashWind ?? this.enableRotorDownwashWind,
      downwashInfluenceRadiusMeters:
          downwashInfluenceRadiusMeters ?? this.downwashInfluenceRadiusMeters,
      maxDownwashSwayMeters:
          maxDownwashSwayMeters ?? this.maxDownwashSwayMeters,
      showBroadcastCallSign:
          showBroadcastCallSign ?? this.showBroadcastCallSign,
      callSign: callSign ?? this.callSign,
      fuselagePrimaryColor: fuselagePrimaryColor,
      fuselageAccentColor: fuselageAccentColor,
      broadcastStripeColor: broadcastStripeColor,
    );
  }
}

// =============================================================================
// 2. MODELE STANU 3D, CIENIA NA SZOSIE ORAZ PODMUCHU NA KORONY DRZEW
// =============================================================================

/// Pełny stan kinematyczny helikoptera telewizyjnego w przestrzeni 3D.
class TvHelicopterState {
  final Vector3 worldPosition;
  final Vector3 velocityWorld;
  final Vector3 forward;
  final Vector3 right;
  final Vector3 up;
  final double yawRadians;
  final double pitchRadians;
  final double bankRollRadians;
  final double mainRotorAngleRadians;
  final double tailRotorAngleRadians;
  final double gimbalYawRadians;
  final double gimbalPitchRadians;
  final Vector3 gimbalTargetWorld;
  final double orbitPhaseRadians;
  final double altitudeAboveRoadMeters;
  final double beaconIntensity;
  final TvHelicopterFlightMode flightMode;

  const TvHelicopterState({
    required this.worldPosition,
    required this.velocityWorld,
    required this.forward,
    required this.right,
    required this.up,
    required this.yawRadians,
    required this.pitchRadians,
    required this.bankRollRadians,
    required this.mainRotorAngleRadians,
    required this.tailRotorAngleRadians,
    required this.gimbalYawRadians,
    required this.gimbalPitchRadians,
    required this.gimbalTargetWorld,
    required this.orbitPhaseRadians,
    required this.altitudeAboveRoadMeters,
    required this.beaconIntensity,
    required this.flightMode,
  });

  /// Pozycja głowicy kamery żyroskopowej na dziobie w przestrzeni świata.
  Vector3 get noseGimbalWorldPosition =>
      worldPosition + forward * 3.85 - up * 0.52;

  /// Pozycja piasty głównego wirnika nad kadłubem w przestrzeni świata.
  Vector3 get mainRotorHubWorldPosition => worldPosition + up * 1.48;

  /// Pozycja wirnika ogonowego na końcu belki ogonowej.
  Vector3 get tailRotorHubWorldPosition =>
      worldPosition - forward * 5.25 + up * 0.42 + right * 0.18;
}

/// Rzutowany cień helikoptera i wirnika na płaszczyznę szosy.
class HelicopterRoadShadowGeometry {
  final Vector3 shadowCenterWorld;
  final Vector3 shadowForward;
  final Vector3 shadowRight;
  final double fuselageLengthMeters;
  final double fuselageWidthMeters;
  final double rotorRadiusMeters;
  final double mainRotorAngleRadians;
  final double penumbraScale;
  final double opacity;

  const HelicopterRoadShadowGeometry({
    required this.shadowCenterWorld,
    required this.shadowForward,
    required this.shadowRight,
    required this.fuselageLengthMeters,
    required this.fuselageWidthMeters,
    required this.rotorRadiusMeters,
    required this.mainRotorAngleRadians,
    required this.penumbraScale,
    required this.opacity,
  });
}

/// Dane pojedynczego drzewa przydrożnego poddanego podmuchowi wirnika.
class HelicopterDownwashTreeInput {
  final String treeId;
  final Vector3 baseWorldPosition;
  final double heightMeters;
  final double canopyRadiusMeters;
  final double flexibility;

  const HelicopterDownwashTreeInput({
    required this.treeId,
    required this.baseWorldPosition,
    this.heightMeters = 9.0,
    this.canopyRadiusMeters = 2.8,
    this.flexibility = 1.0,
  });
}

/// Wyliczone wychylenie korony drzewa od podmuchu wiatru wirnika (Rotor Downwash).
class HelicopterTreeSwayDisplacement {
  final String treeId;
  final Vector3 canopyCenterWorld;
  final Vector3 swayOffsetWorld;
  final double bendAngleRadians;
  final double gustIntensity;
  final double leafFlutterPhase;

  const HelicopterTreeSwayDisplacement({
    required this.treeId,
    required this.canopyCenterWorld,
    required this.swayOffsetWorld,
    required this.bendAngleRadians,
    required this.gustIntensity,
    required this.leafFlutterPhase,
  });
}

// =============================================================================
// 3. GŁÓWNY RENDERER HELIKOPTERA TELEWIZYJNEGO 3D
// =============================================================================

/// Renderer helikoptera telewizyjnego krążącego nad czołem wyścigu:
/// - kinematyka lotu po orbicie z przechyłem w zakręcie i pochyleniem dziobu,
/// - obracający się 4-łopatowy wirnik główny z dyskiem motion-blur oraz wirnik ogonowy,
/// - stabilizowana żyroskopowo kamera Cineflex na dziobie śledząca czoło wyścigu,
/// - miękki cień rzucany na szosę (kadłub + płozy + obracający się wirnik),
/// - podmuch wiatru (rotor downwash) poruszający korony przydrożnych drzew.
class TvHelicopterSkyRenderer {
  final TvHelicopterConfig config;

  // Prealokowane obiekty Paint (Zero-GC przy renderowaniu 60/120 FPS)
  late final Paint _fuselagePaint;
  late final Paint _fuselageShadePaint;
  late final Paint _cockpitGlassPaint;
  late final Paint _cockpitHighlightPaint;
  late final Paint _stripePaint;
  late final Paint _accentPaint;
  late final Paint _skidPaint;
  late final Paint _rotorBladePaint;
  late final Paint _rotorDiscPaint;
  late final Paint _rotorDiscRingPaint;
  late final Paint _gimbalHousingPaint;
  late final Paint _gimbalLensPaint;
  late final Paint _gimbalGlintPaint;
  late final Paint _beaconPaint;
  late final Paint _shadowPenumbraPaint;
  late final Paint _shadowUmbraPaint;
  late final Paint _shadowRotorPaint;
  late final Paint _downwashRingPaint;
  late final Paint _canopyGustPaint;
  late final Paint _canopyShadowPaint;
  late final Paint _badgeBgPaint;
  late final Paint _badgeBorderPaint;

  final Map<String, TextPainter> _callSignPainterCache = {};

  TvHelicopterSkyRenderer({
    this.config = const TvHelicopterConfig(),
  }) {
    _fuselagePaint = Paint()
      ..color = config.fuselagePrimaryColor
      ..style = PaintingStyle.fill;
    _fuselageShadePaint = Paint()
      ..color = const Color(0xFF0B0D11)
      ..style = PaintingStyle.fill;
    _cockpitGlassPaint = Paint()
      ..color = const Color(0xFF0E293D)
      ..style = PaintingStyle.fill;
    _cockpitHighlightPaint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    _stripePaint = Paint()
      ..color = config.broadcastStripeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    _accentPaint = Paint()
      ..color = config.fuselageAccentColor
      ..style = PaintingStyle.fill;
    _skidPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _rotorBladePaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    _rotorDiscPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    _rotorDiscRingPaint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke;
    _gimbalHousingPaint = Paint()
      ..color = const Color(0xFF222630)
      ..style = PaintingStyle.fill;
    _gimbalLensPaint = Paint()
      ..color = const Color(0xFF090D16)
      ..style = PaintingStyle.fill;
    _gimbalGlintPaint = Paint()
      ..color = AppColors.cyanAccent.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    _beaconPaint = Paint()..style = PaintingStyle.fill;
    _shadowPenumbraPaint = Paint()..style = PaintingStyle.fill;
    _shadowUmbraPaint = Paint()..style = PaintingStyle.fill;
    _shadowRotorPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    _downwashRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    _canopyGustPaint = Paint()..style = PaintingStyle.fill;
    _canopyShadowPaint = Paint()..style = PaintingStyle.fill;
    _badgeBgPaint = Paint()
      ..color = AppColors.surface.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;
    _badgeBorderPaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
  }

  /// Wylicza kompletny stan 3D helikoptera dla zadanej pozycji czoła wyścigu i czasu [elapsedSeconds].
  TvHelicopterState computeState({
    required Vector3 leadRiderWorldPos,
    required Vector3 roadTangent,
    Vector3? roadNormal,
    required double elapsedSeconds,
    TvHelicopterFlightMode flightMode = TvHelicopterFlightMode.orbitingLeadGroup,
    double leadSpeedMs = 12.5,
  }) {
    final Vector3 upWorld = (roadNormal != null && roadNormal.length2 > 1e-6)
        ? roadNormal.normalized()
        : Vector3(0.0, 1.0, 0.0);

    final Vector3 tangentNorm = roadTangent.length2 > 1e-6
        ? roadTangent.normalized()
        : Vector3(0.0, 0.0, 1.0);
    final Vector3 lateralRight =
        tangentNorm.cross(upWorld).normalized();

    final double phase = elapsedSeconds * config.orbitAngularSpeedRadPerSec;

    // Kształt trajektorii zależny od wybranego trybu lotu TV
    final double radius = switch (flightMode) {
      TvHelicopterFlightMode.orbitingLeadGroup => config.orbitRadiusMeters,
      TvHelicopterFlightMode.trackingBreakaway =>
        config.orbitRadiusMeters * 0.85,
      TvHelicopterFlightMode.lowFlybySprint => config.orbitRadiusMeters * 0.55,
      TvHelicopterFlightMode.hoveringClimbSummit =>
        config.orbitRadiusMeters * 0.38,
    };

    final double baseAltitude = switch (flightMode) {
      TvHelicopterFlightMode.orbitingLeadGroup => config.cruiseAltitudeMeters,
      TvHelicopterFlightMode.trackingBreakaway =>
        config.cruiseAltitudeMeters * 0.92,
      TvHelicopterFlightMode.lowFlybySprint =>
        config.cruiseAltitudeMeters * 0.62,
      TvHelicopterFlightMode.hoveringClimbSummit =>
        config.cruiseAltitudeMeters * 1.08,
    };

    final double bobbing = math.sin(elapsedSeconds * 1.45) * 0.65 +
        math.cos(elapsedSeconds * 0.72) * 0.35;
    final double altitude = (baseAltitude + bobbing).clamp(8.0, 95.0);

    // Pozycja na orbicie wokół czoła wyścigu
    final double localForwardOffset;
    final double localRightOffset;
    final double tangentSpeedForward;
    final double tangentSpeedRight;

    if (flightMode == TvHelicopterFlightMode.trackingBreakaway) {
      // Ósemka nad czołem wyścigu
      localForwardOffset = math.sin(phase) * radius * 0.72 + 8.0;
      localRightOffset = math.sin(phase * 2.0) * radius * 0.58;
      tangentSpeedForward =
          math.cos(phase) * radius * 0.72 * config.orbitAngularSpeedRadPerSec;
      tangentSpeedRight = math.cos(phase * 2.0) *
          radius *
          0.58 *
          (config.orbitAngularSpeedRadPerSec * 2.0);
    } else if (flightMode == TvHelicopterFlightMode.lowFlybySprint) {
      // Szybki niski przelot lekko z przodu po prawej
      localForwardOffset = math.cos(phase * 1.35) * radius + 12.0;
      localRightOffset = math.sin(phase * 1.35) * radius * 0.55 + 6.0;
      tangentSpeedForward = -math.sin(phase * 1.35) *
          radius *
          config.orbitAngularSpeedRadPerSec *
          1.35;
      tangentSpeedRight = math.cos(phase * 1.35) *
          radius *
          0.55 *
          config.orbitAngularSpeedRadPerSec *
          1.35;
    } else {
      // Klasyczna orbita lub ciasny zawis nad szczytem
      localForwardOffset = math.cos(phase) * radius + 6.0;
      localRightOffset = math.sin(phase) * radius;
      tangentSpeedForward =
          -math.sin(phase) * radius * config.orbitAngularSpeedRadPerSec;
      tangentSpeedRight =
          math.cos(phase) * radius * config.orbitAngularSpeedRadPerSec;
    }

    final Vector3 worldPos = leadRiderWorldPos +
        tangentNorm * localForwardOffset +
        lateralRight * localRightOffset +
        upWorld * altitude;

    final Vector3 velocity = tangentNorm * (leadSpeedMs + tangentSpeedForward) +
        lateralRight * tangentSpeedRight;

    // Kierunek lotu (dziób lekko zwrócony w stronę ruchu z lekkim znoszeniem na cel)
    final Vector3 toTarget = (leadRiderWorldPos - worldPos);
    final Vector3 toTargetFlat = Vector3(toTarget.x, 0.0, toTarget.z);
    final Vector3 velFlat = Vector3(velocity.x, 0.0, velocity.z);

    final Vector3 headingDir = velFlat.length2 > 0.25
        ? (velFlat.normalized() * 0.78 +
                (toTargetFlat.length2 > 1e-4
                    ? toTargetFlat.normalized() * 0.22
                    : Vector3.zero()))
            .normalized()
        : (toTargetFlat.length2 > 1e-4
            ? toTargetFlat.normalized()
            : tangentNorm);

    final double yawRad = math.atan2(headingDir.x, headingDir.z);
    final double speedNorm = (velocity.length / 28.0).clamp(0.0, 1.0);
    final double pitchRad = 0.06 + speedNorm * 0.14; // Dziób lekko w dół

    // Przechył w zakręcie proporcjonalny do prędkości kątowej orbity
    final double bankRollRad = switch (flightMode) {
      TvHelicopterFlightMode.hoveringClimbSummit =>
        0.05 * math.sin(phase * 0.8),
      TvHelicopterFlightMode.trackingBreakaway => 0.24 * math.cos(phase * 2.0),
      _ => 0.22,
    };

    // Lokalna baza 3D śmigłowca po zastosowaniu yaw, pitch i roll
    final Vector3 baseRight =
        Vector3(0.0, 1.0, 0.0).cross(headingDir).normalized();
    final Vector3 pitchedForward = (headingDir * math.cos(pitchRad) -
            Vector3(0.0, 1.0, 0.0) * math.sin(pitchRad))
        .normalized();
    final Vector3 pitchedUp = pitchedForward.cross(baseRight).normalized();

    final Vector3 heliRight = (baseRight * math.cos(bankRollRad) +
            pitchedUp * math.sin(bankRollRad))
        .normalized();
    final Vector3 heliUp = heliRight.cross(pitchedForward).normalized();
    final Vector3 heliForward = pitchedForward;

    // Obroty wirnika głównego i ogonowego
    final double mainRotorRadPerSec =
        (config.mainRotorRpm / 60.0) * 2.0 * math.pi;
    final double tailRotorRadPerSec =
        (config.tailRotorRpm / 60.0) * 2.0 * math.pi;
    final double mainRotorAngle =
        (elapsedSeconds * mainRotorRadPerSec) % (2.0 * math.pi);
    final double tailRotorAngle =
        (elapsedSeconds * tailRotorRadPerSec) % (2.0 * math.pi);

    // Kamera żyroskopowa Cineflex na dziobie zawsze stabilizowana na czoło wyścigu
    final Vector3 gimbalPos = worldPos + heliForward * 3.85 - heliUp * 0.52;
    final Vector3 aimVec = leadRiderWorldPos - gimbalPos;
    final double horizDist =
        math.sqrt(aimVec.x * aimVec.x + aimVec.z * aimVec.z).clamp(0.1, 9999.0);
    final double gimbalWorldYaw = math.atan2(aimVec.x, aimVec.z);
    final double gimbalYawRel = _wrapAngleRadians(gimbalWorldYaw - yawRad);
    final double gimbalPitch = -math.atan2(aimVec.y, horizDist);

    // Pulsowanie stroboskopu antykolizyjnego
    final double strobeWave = math.sin(elapsedSeconds * 7.2);
    final double beaconIntensity = strobeWave > 0.65 ? 1.0 : 0.22;

    return TvHelicopterState(
      worldPosition: worldPos,
      velocityWorld: velocity,
      forward: heliForward,
      right: heliRight,
      up: heliUp,
      yawRadians: yawRad,
      pitchRadians: pitchRad,
      bankRollRadians: bankRollRad,
      mainRotorAngleRadians: mainRotorAngle,
      tailRotorAngleRadians: tailRotorAngle,
      gimbalYawRadians: gimbalYawRel,
      gimbalPitchRadians: gimbalPitch,
      gimbalTargetWorld: leadRiderWorldPos,
      orbitPhaseRadians: phase,
      altitudeAboveRoadMeters: altitude,
      beaconIntensity: beaconIntensity,
      flightMode: flightMode,
    );
  }

  /// Wylicza rzutowany cień helikoptera i wirnika na powierzchnię szosy.
  HelicopterRoadShadowGeometry? computeRoadShadow({
    required TvHelicopterState state,
    required double roadSurfaceY,
    Vector3? sunDirectionToLight,
    double weatherOpacityFactor = 1.0,
  }) {
    if (!config.enabled || !config.enableRoadShadow) return null;

    final Vector3 sunDir = (sunDirectionToLight != null &&
            sunDirectionToLight.length2 > 1e-6)
        ? sunDirectionToLight.normalized()
        : Vector3(0.42, 0.78, -0.46).normalized();

    // Zabezpieczenie przed bardzo niskim kątem słońca
    final double sunY = sunDir.y.clamp(0.18, 1.0);
    final double heightAboveRoad =
        (state.worldPosition.y - roadSurfaceY).clamp(1.0, 120.0);

    final double t = heightAboveRoad / sunY;
    final Vector3 shadowCenter = Vector3(
      state.worldPosition.x - sunDir.x * t,
      roadSurfaceY + 0.02,
      state.worldPosition.z - sunDir.z * t,
    );

    final Vector3 flatForward = Vector3(state.forward.x, 0.0, state.forward.z);
    final Vector3 shadowFwd = flatForward.length2 > 1e-6
        ? flatForward.normalized()
        : Vector3(0.0, 0.0, 1.0);
    final Vector3 shadowRight =
        shadowFwd.cross(Vector3(0.0, 1.0, 0.0)).normalized();

    final double penumbraScale = 1.0 + (heightAboveRoad / 45.0) * 0.48;
    final double baseOpacity =
        (0.46 - (heightAboveRoad / 140.0) * 0.22).clamp(0.14, 0.48);

    return HelicopterRoadShadowGeometry(
      shadowCenterWorld: shadowCenter,
      shadowForward: shadowFwd,
      shadowRight: shadowRight,
      fuselageLengthMeters: config.fuselageLengthMeters,
      fuselageWidthMeters: config.fuselageWidthMeters,
      rotorRadiusMeters: config.mainRotorRadiusMeters,
      mainRotorAngleRadians: state.mainRotorAngleRadians,
      penumbraScale: penumbraScale,
      opacity: (baseOpacity * weatherOpacityFactor).clamp(0.0, 0.55),
    );
  }

  /// Wylicza wychylenia koron drzew pod wpływem podmuchu wirnika (Rotor Downwash).
  List<HelicopterTreeSwayDisplacement> computeTreeDownwashSways({
    required TvHelicopterState state,
    required List<HelicopterDownwashTreeInput> trees,
    required double elapsedSeconds,
  }) {
    if (!config.enabled || !config.enableRotorDownwashWind || trees.isEmpty) {
      return const [];
    }

    final double influenceRadius = config.downwashInfluenceRadiusMeters;
    if (influenceRadius <= 0.0) return const [];

    final double altAttenuation =
        (1.0 - (state.altitudeAboveRoadMeters - 10.0) / 55.0).clamp(0.25, 1.0);

    final List<HelicopterTreeSwayDisplacement> results = [];

    for (final tree in trees) {
      final double dx = tree.baseWorldPosition.x - state.worldPosition.x;
      final double dz = tree.baseWorldPosition.z - state.worldPosition.z;
      final double horizDist = math.sqrt(dx * dx + dz * dz);

      final Vector3 canopyCenter = tree.baseWorldPosition +
          Vector3(0.0, tree.heightMeters * 0.72, 0.0);

      if (horizDist > influenceRadius) {
        // Delikatny ambientowy ruch wiatru poza strefą głównego podmuchu
        final double ambientWave =
            math.sin(elapsedSeconds * 1.8 + tree.baseWorldPosition.z * 0.15) *
                0.08 *
                tree.flexibility;
        results.add(
          HelicopterTreeSwayDisplacement(
            treeId: tree.treeId,
            canopyCenterWorld: canopyCenter,
            swayOffsetWorld: Vector3(ambientWave, 0.0, ambientWave * 0.4),
            bendAngleRadians: ambientWave * 0.03,
            gustIntensity: 0.0,
            leafFlutterPhase: elapsedSeconds * 2.4,
          ),
        );
        continue;
      }

      // Profil Gaussa siły podmuchu pod śmigłowcem + zawirowanie styczne
      final double normalizedDist = horizDist / influenceRadius;
      final double radialFalloff =
          math.exp(-normalizedDist * normalizedDist * 3.1);
      final double gustIntensity =
          (radialFalloff * altAttenuation * tree.flexibility).clamp(0.0, 1.0);

      final double invDist = horizDist > 0.25 ? 1.0 / horizDist : 0.0;
      final double radX = horizDist > 0.25 ? dx * invDist : 1.0;
      final double radZ = horizDist > 0.25 ? dz * invDist : 0.0;

      // Składowa styczna (wirowa) od obrotu głównego wirnika
      final double swirlX = -radZ;
      final double swirlZ = radX;

      final double flutter = math.sin(elapsedSeconds * 9.5 + horizDist * 0.6) *
              0.32 +
          math.cos(elapsedSeconds * 14.2 + tree.baseWorldPosition.x * 0.4) *
              0.18;

      final double swayMagnitude =
          config.maxDownwashSwayMeters * gustIntensity * (0.78 + flutter * 0.35);

      final Vector3 swayOffset = Vector3(
        (radX * 0.82 + swirlX * 0.42) * swayMagnitude,
        -gustIntensity * 0.22 * tree.flexibility,
        (radZ * 0.82 + swirlZ * 0.42) * swayMagnitude,
      );

      results.add(
        HelicopterTreeSwayDisplacement(
          treeId: tree.treeId,
          canopyCenterWorld: canopyCenter,
          swayOffsetWorld: swayOffset,
          bendAngleRadians: (swayMagnitude / tree.heightMeters).clamp(0.0, 0.35),
          gustIntensity: gustIntensity,
          leafFlutterPhase:
              (elapsedSeconds * 11.0 + horizDist * 0.5) % (2.0 * math.pi),
        ),
      );
    }

    return results;
  }

  /// Renderuje cień helikoptera na szosie, falujące korony drzew oraz model 3D helikoptera.
  void paint({
    required Canvas canvas,
    required Size size,
    required Scene3DMathProjection projection,
    required TvHelicopterState state,
    HelicopterRoadShadowGeometry? roadShadow,
    List<HelicopterDownwashTreeInput> nearbyTrees = const [],
    List<HelicopterTreeSwayDisplacement>? precomputedTreeSways,
    double elapsedSeconds = 0.0,
  }) {
    if (!config.enabled || size.width <= 0 || size.height <= 0) return;

    // 1. Cień na szosie i podmuch wiatru pod wirnikiem
    if (roadShadow != null && config.enableRoadShadow) {
      _paintRoadShadow(canvas, projection, roadShadow);
    }

    if (config.enableRotorDownwashWind && nearbyTrees.isNotEmpty) {
      final sways = precomputedTreeSways ??
          computeTreeDownwashSways(
            state: state,
            trees: nearbyTrees,
            elapsedSeconds: elapsedSeconds,
          );
      _paintTreeDownwashEffects(canvas, projection, nearbyTrees, sways);
    }

    if (config.enableRotorDownwashWind) {
      _paintDownwashAirRings(canvas, projection, state, elapsedSeconds);
    }

    // 2. Model 3D helikoptera w przestrzeni kamery
    final ProjectedPoint3D centerProj =
        projection.worldToScreen(state.worldPosition);
    if (!centerProj.isInFrontOfCamera) return;

    // Rzutowanie kluczowych punktów szkieletu 3D
    final Vector3 noseTip = state.worldPosition + state.forward * 4.15;
    final Vector3 tailTip = state.worldPosition - state.forward * 5.35 + state.up * 0.38;
    final Vector3 cockpitTop = state.worldPosition + state.forward * 1.45 + state.up * 0.95;
    final Vector3 bellyBottom = state.worldPosition + state.forward * 0.35 - state.up * 0.72;
    final Vector3 cabinLeft = state.worldPosition - state.right * (config.fuselageWidthMeters * 0.5);
    final Vector3 cabinRight = state.worldPosition + state.right * (config.fuselageWidthMeters * 0.5);

    final ProjectedPoint3D pNose = projection.worldToScreen(noseTip);
    final ProjectedPoint3D pTail = projection.worldToScreen(tailTip);
    final ProjectedPoint3D pTop = projection.worldToScreen(cockpitTop);
    final ProjectedPoint3D pBelly = projection.worldToScreen(bellyBottom);
    final ProjectedPoint3D pLeft = projection.worldToScreen(cabinLeft);
    final ProjectedPoint3D pRight = projection.worldToScreen(cabinRight);

    if (!pNose.isInFrontOfCamera || !pTail.isInFrontOfCamera) return;

    final double scale = centerProj.perspectiveScale.clamp(0.18, 4.5);

    // Płozy do lądowania (TV_Heli_Skids)
    _paintLandingSkids(canvas, projection, state, scale);

    // Belka ogonowa i statecznik pionowy + wirnik ogonowy
    _paintTailAssembly(canvas, projection, state, centerProj, pTail, scale);

    // Kadłub główny (TV_Heli_Fuselage)
    _paintFuselage(
      canvas,
      pNose,
      pTail,
      pTop,
      pBelly,
      pLeft,
      pRight,
      centerProj,
      scale,
    );

    // Kamera żyroskopowa na dziobie (TV_Heli_Cineflex_Gimbal)
    _paintNoseGyroCamera(canvas, projection, state, scale);

    // Stroboskop antykolizyjny
    _paintBeaconLight(canvas, projection, state, scale);

    // Główny wirnik 4-łopatowy + dysk motion-blur (TV_Heli_Main_Rotor)
    _paintMainRotor(canvas, projection, state, scale);

    // Etykieta wywoławcza transmisji TV
    if (config.showBroadcastCallSign && centerProj.isInViewport) {
      _paintCallSignBadge(canvas, centerProj, scale);
    }
  }

  void _paintRoadShadow(
    Canvas canvas,
    Scene3DMathProjection projection,
    HelicopterRoadShadowGeometry shadow,
  ) {
    final ProjectedPoint3D center =
        projection.worldToScreen(shadow.shadowCenterWorld);
    if (!center.isInFrontOfCamera) return;

    final Vector3 fwdTip = shadow.shadowCenterWorld +
        shadow.shadowForward * (shadow.fuselageLengthMeters * 0.52 * shadow.penumbraScale);
    final Vector3 aftTip = shadow.shadowCenterWorld -
        shadow.shadowForward * (shadow.fuselageLengthMeters * 0.56 * shadow.penumbraScale);
    final Vector3 sideR = shadow.shadowCenterWorld +
        shadow.shadowRight * (shadow.fuselageWidthMeters * 0.65 * shadow.penumbraScale);
    final Vector3 sideL = shadow.shadowCenterWorld -
        shadow.shadowRight * (shadow.fuselageWidthMeters * 0.65 * shadow.penumbraScale);

    final ProjectedPoint3D pFwd = projection.worldToScreen(fwdTip);
    final ProjectedPoint3D pAft = projection.worldToScreen(aftTip);
    final ProjectedPoint3D pR = projection.worldToScreen(sideR);
    final ProjectedPoint3D pL = projection.worldToScreen(sideL);

    if (!pFwd.isInFrontOfCamera || !pAft.isInFrontOfCamera) return;

    // Miękki półcień kadłuba na asfalcie
    final Path penumbraPath = Path()
      ..moveTo(pFwd.screenX, pFwd.screenY)
      ..quadraticBezierTo(
        pR.screenX,
        pR.screenY,
        pAft.screenX,
        pAft.screenY,
      )
      ..quadraticBezierTo(
        pL.screenX,
        pL.screenY,
        pFwd.screenX,
        pFwd.screenY,
      )
      ..close();

    _shadowPenumbraPaint.color =
        Colors.black.withValues(alpha: shadow.opacity * 0.45);
    canvas.drawPath(penumbraPath, _shadowPenumbraPaint);

    // Rdzeń cienia (umbra)
    const double coreShrink = 0.66;
    final Path umbraPath = Path()
      ..moveTo(
        _lerp(center.screenX, pFwd.screenX, coreShrink),
        _lerp(center.screenY, pFwd.screenY, coreShrink),
      )
      ..quadraticBezierTo(
        _lerp(center.screenX, pR.screenX, coreShrink),
        _lerp(center.screenY, pR.screenY, coreShrink),
        _lerp(center.screenX, pAft.screenX, coreShrink),
        _lerp(center.screenY, pAft.screenY, coreShrink),
      )
      ..quadraticBezierTo(
        _lerp(center.screenX, pL.screenX, coreShrink),
        _lerp(center.screenY, pL.screenY, coreShrink),
        _lerp(center.screenX, pFwd.screenX, coreShrink),
        _lerp(center.screenY, pFwd.screenY, coreShrink),
      )
      ..close();

    _shadowUmbraPaint.color = Colors.black.withValues(alpha: shadow.opacity);
    canvas.drawPath(umbraPath, _shadowUmbraPaint);

    // Cień obracających się łopat wirnika głównego na szosie
    _shadowRotorPaint
      ..color = Colors.black.withValues(alpha: shadow.opacity * 0.42)
      ..strokeWidth = (3.2 * center.perspectiveScale).clamp(1.2, 7.5);

    for (int i = 0; i < 4; i++) {
      final double angle = shadow.mainRotorAngleRadians + i * (math.pi * 0.5);
      final Vector3 bladeDir = shadow.shadowForward * math.cos(angle) +
          shadow.shadowRight * math.sin(angle);
      final ProjectedPoint3D bladeEnd = projection.worldToScreen(
        shadow.shadowCenterWorld +
            bladeDir * (shadow.rotorRadiusMeters * shadow.penumbraScale),
      );
      if (bladeEnd.isInFrontOfCamera) {
        canvas.drawLine(
          Offset(center.screenX, center.screenY),
          Offset(bladeEnd.screenX, bladeEnd.screenY),
          _shadowRotorPaint,
        );
      }
    }
  }

  void _paintTreeDownwashEffects(
    Canvas canvas,
    Scene3DMathProjection projection,
    List<HelicopterDownwashTreeInput> trees,
    List<HelicopterTreeSwayDisplacement> sways,
  ) {
    final int count = math.min(trees.length, sways.length);
    for (int i = 0; i < count; i++) {
      final tree = trees[i];
      final sway = sways[i];
      if (sway.gustIntensity <= 0.02) continue;

      final Vector3 displacedCenter =
          sway.canopyCenterWorld + sway.swayOffsetWorld;
      final ProjectedPoint3D pBase =
          projection.worldToScreen(tree.baseWorldPosition);
      final ProjectedPoint3D pCanopy = projection.worldToScreen(displacedCenter);

      if (!pCanopy.isInFrontOfCamera) continue;

      final double radiusPx =
          (tree.canopyRadiusMeters * 18.0 * pCanopy.perspectiveScale)
              .clamp(4.0, 68.0);

      // Cień i wychylona korona drzewa poruszana podmuchem
      if (pBase.isInFrontOfCamera) {
        _canopyShadowPaint.color = const Color(0xFF14532D)
            .withValues(alpha: 0.25 * sway.gustIntensity);
        canvas.drawLine(
          Offset(pBase.screenX, pBase.screenY),
          Offset(pCanopy.screenX, pCanopy.screenY),
          _canopyShadowPaint..strokeWidth = (radiusPx * 0.16).clamp(1.5, 5.0),
        );
      }

      _canopyGustPaint.color = const Color(0xFF22C55E)
          .withValues(alpha: 0.22 * sway.gustIntensity);
      canvas.drawCircle(
        Offset(pCanopy.screenX, pCanopy.screenY),
        radiusPx,
        _canopyGustPaint,
      );

      // Drobne smugi wiatru wokół wychylonej korony
      final double streakDx =
          math.cos(sway.leafFlutterPhase) * radiusPx * 0.72;
      final double streakDy =
          math.sin(sway.leafFlutterPhase) * radiusPx * 0.35;
      _downwashRingPaint
        ..color = Colors.white.withValues(alpha: 0.24 * sway.gustIntensity)
        ..strokeWidth = 1.2;
      canvas.drawLine(
        Offset(pCanopy.screenX - streakDx * 0.3, pCanopy.screenY - streakDy * 0.3),
        Offset(pCanopy.screenX + streakDx, pCanopy.screenY + streakDy),
        _downwashRingPaint,
      );
    }
  }

  void _paintDownwashAirRings(
    Canvas canvas,
    Scene3DMathProjection projection,
    TvHelicopterState state,
    double elapsedSeconds,
  ) {
    final Vector3 groundCenter = Vector3(
      state.worldPosition.x,
      state.worldPosition.y - state.altitudeAboveRoadMeters,
      state.worldPosition.z,
    );
    final ProjectedPoint3D pGround = projection.worldToScreen(groundCenter);
    if (!pGround.isInFrontOfCamera) return;

    final double pulse = (elapsedSeconds * 1.6) % 1.0;
    final double ringRadiusMeters = 4.0 + pulse * 13.0;
    final ProjectedPoint3D pEdge = projection.worldToScreen(
      groundCenter + state.right * ringRadiusMeters,
    );
    if (!pEdge.isInFrontOfCamera) return;

    final double radiusPx = (pEdge.screenX - pGround.screenX).abs().clamp(4.0, 90.0);
    _downwashRingPaint
      ..color = Colors.white.withValues(alpha: (1.0 - pulse) * 0.14)
      ..strokeWidth = 1.3;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pGround.screenX, pGround.screenY),
        width: radiusPx * 2.0,
        height: radiusPx * 0.72,
      ),
      _downwashRingPaint,
    );
  }

  void _paintLandingSkids(
    Canvas canvas,
    Scene3DMathProjection projection,
    TvHelicopterState state,
    double scale,
  ) {
    _skidPaint.strokeWidth = (2.1 * scale).clamp(1.0, 4.5);

    for (final double side in const [-1.0, 1.0]) {
      final Vector3 skidBase =
          state.worldPosition + state.right * (side * 1.02) - state.up * 1.15;
      final ProjectedPoint3D pSkidFwd = projection.worldToScreen(
        skidBase + state.forward * 2.35 + state.up * 0.14,
      );
      final ProjectedPoint3D pSkidAft = projection.worldToScreen(
        skidBase - state.forward * 1.85,
      );
      final ProjectedPoint3D pStrutFwd = projection.worldToScreen(
        state.worldPosition + state.right * (side * 0.65) + state.forward * 1.15 - state.up * 0.55,
      );
      final ProjectedPoint3D pStrutAft = projection.worldToScreen(
        state.worldPosition + state.right * (side * 0.65) - state.forward * 0.95 - state.up * 0.55,
      );

      if (pSkidFwd.isInFrontOfCamera && pSkidAft.isInFrontOfCamera) {
        canvas.drawLine(
          Offset(pSkidFwd.screenX, pSkidFwd.screenY),
          Offset(pSkidAft.screenX, pSkidAft.screenY),
          _skidPaint,
        );
      }
      if (pStrutFwd.isInFrontOfCamera && pSkidFwd.isInFrontOfCamera) {
        canvas.drawLine(
          Offset(pStrutFwd.screenX, pStrutFwd.screenY),
          Offset(_lerp(pSkidAft.screenX, pSkidFwd.screenX, 0.72),
              _lerp(pSkidAft.screenY, pSkidFwd.screenY, 0.72)),
          _skidPaint,
        );
      }
      if (pStrutAft.isInFrontOfCamera && pSkidAft.isInFrontOfCamera) {
        canvas.drawLine(
          Offset(pStrutAft.screenX, pStrutAft.screenY),
          Offset(_lerp(pSkidAft.screenX, pSkidFwd.screenX, 0.25),
              _lerp(pSkidAft.screenY, pSkidFwd.screenY, 0.25)),
          _skidPaint,
        );
      }
    }
  }

  void _paintTailAssembly(
    Canvas canvas,
    Scene3DMathProjection projection,
    TvHelicopterState state,
    ProjectedPoint3D centerProj,
    ProjectedPoint3D pTail,
    double scale,
  ) {
    final ProjectedPoint3D pBoomStart = projection.worldToScreen(
      state.worldPosition - state.forward * 1.35 + state.up * 0.15,
    );
    final ProjectedPoint3D pFinTop = projection.worldToScreen(
      state.worldPosition - state.forward * 5.15 + state.up * 1.48,
    );

    if (pBoomStart.isInFrontOfCamera) {
      final Paint boomPaint = Paint()
        ..color = config.fuselagePrimaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = (5.2 * scale).clamp(2.0, 14.0)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(pBoomStart.screenX, pBoomStart.screenY),
        Offset(pTail.screenX, pTail.screenY),
        boomPaint,
      );

      // Złoty pasek na belce ogonowej
      _stripePaint.strokeWidth = (1.6 * scale).clamp(0.8, 3.8);
      canvas.drawLine(
        Offset(pBoomStart.screenX, pBoomStart.screenY),
        Offset(pTail.screenX, pTail.screenY),
        _stripePaint,
      );
    }

    // Statecznik pionowy
    if (pFinTop.isInFrontOfCamera) {
      final Path finPath = Path()
        ..moveTo(pTail.screenX, pTail.screenY)
        ..lineTo(pFinTop.screenX, pFinTop.screenY)
        ..lineTo(
          _lerp(pTail.screenX, centerProj.screenX, 0.14),
          _lerp(pTail.screenY, centerProj.screenY, 0.14),
        )
        ..close();
      canvas.drawPath(finPath, _accentPaint);
    }

    // Wirnik ogonowy (TV_Heli_Tail_Rotor)
    final ProjectedPoint3D pTailHub =
        projection.worldToScreen(state.tailRotorHubWorldPosition);
    if (pTailHub.isInFrontOfCamera) {
      _rotorBladePaint.strokeWidth = (2.0 * scale).clamp(1.0, 4.2);
      for (int i = 0; i < 2; i++) {
        final double angle = state.tailRotorAngleRadians + i * math.pi;
        final Vector3 tipWorld = state.tailRotorHubWorldPosition +
            state.forward * (math.cos(angle) * config.tailRotorRadiusMeters) +
            state.up * (math.sin(angle) * config.tailRotorRadiusMeters);
        final ProjectedPoint3D pBlade = projection.worldToScreen(tipWorld);
        if (pBlade.isInFrontOfCamera) {
          canvas.drawLine(
            Offset(pTailHub.screenX, pTailHub.screenY),
            Offset(pBlade.screenX, pBlade.screenY),
            _rotorBladePaint,
          );
        }
      }
    }
  }

  void _paintFuselage(
    Canvas canvas,
    ProjectedPoint3D pNose,
    ProjectedPoint3D pTail,
    ProjectedPoint3D pTop,
    ProjectedPoint3D pBelly,
    ProjectedPoint3D pLeft,
    ProjectedPoint3D pRight,
    ProjectedPoint3D centerProj,
    double scale,
  ) {
    final Offset nose = Offset(pNose.screenX, pNose.screenY);
    final Offset top = Offset(pTop.screenX, pTop.screenY);
    final Offset belly = Offset(pBelly.screenX, pBelly.screenY);
    final Offset aft = Offset(
      _lerp(centerProj.screenX, pTail.screenX, 0.34),
      _lerp(centerProj.screenY, pTail.screenY, 0.34),
    );

    // Główny obrys kabiny
    final Path cabinPath = Path()
      ..moveTo(nose.dx, nose.dy)
      ..quadraticBezierTo(
        _lerp(nose.dx, top.dx, 0.65),
        _lerp(nose.dy, top.dy, 0.85),
        top.dx,
        top.dy,
      )
      ..quadraticBezierTo(
        _lerp(top.dx, aft.dx, 0.72),
        _lerp(top.dy, aft.dy, 0.45),
        aft.dx,
        aft.dy,
      )
      ..quadraticBezierTo(
        _lerp(aft.dx, belly.dx, 0.55),
        _lerp(aft.dy, belly.dy, 0.75),
        belly.dx,
        belly.dy,
      )
      ..quadraticBezierTo(
        _lerp(belly.dx, nose.dx, 0.65),
        _lerp(belly.dy, nose.dy, 0.65),
        nose.dx,
        nose.dy,
      )
      ..close();

    canvas.drawPath(cabinPath, _fuselagePaint);

    // Cieniowanie dolnej części kadłuba
    final Path bellyShadePath = Path()
      ..moveTo(nose.dx, nose.dy)
      ..lineTo(
        _lerp(pLeft.screenX, pRight.screenX, 0.5),
        _lerp(pLeft.screenY, pRight.screenY, 0.5),
      )
      ..lineTo(aft.dx, aft.dy)
      ..lineTo(belly.dx, belly.dy)
      ..close();
    canvas.drawPath(bellyShadePath, _fuselageShadePaint);

    // Przeszklony kokpit na dziobie
    final Path glassPath = Path()
      ..moveTo(
        _lerp(nose.dx, top.dx, 0.14),
        _lerp(nose.dy, top.dy, 0.14),
      )
      ..quadraticBezierTo(
        _lerp(nose.dx, top.dx, 0.65),
        _lerp(nose.dy, top.dy, 0.80),
        _lerp(top.dx, centerProj.screenX, 0.28),
        _lerp(top.dy, centerProj.screenY, 0.28),
      )
      ..lineTo(
        _lerp(nose.dx, centerProj.screenX, 0.44),
        _lerp(nose.dy, centerProj.screenY, 0.44),
      )
      ..close();
    canvas.drawPath(glassPath, _cockpitGlassPaint);
    canvas.drawPath(glassPath, _cockpitHighlightPaint);

    // Złoty pas transmisji TV na boku kadłuba
    _stripePaint.strokeWidth = (2.1 * scale).clamp(1.0, 5.2);
    canvas.drawLine(
      Offset(
        _lerp(nose.dx, centerProj.screenX, 0.32),
        _lerp(nose.dy, centerProj.screenY, 0.32),
      ),
      aft,
      _stripePaint,
    );
  }

  void _paintNoseGyroCamera(
    Canvas canvas,
    Scene3DMathProjection projection,
    TvHelicopterState state,
    double scale,
  ) {
    final Vector3 gimbalPos = state.noseGimbalWorldPosition;
    final ProjectedPoint3D pGimbal = projection.worldToScreen(gimbalPos);
    if (!pGimbal.isInFrontOfCamera) return;

    // Wysięgnik łączący dziób z kulą żyroskopową
    final ProjectedPoint3D pMount = projection.worldToScreen(
      state.worldPosition + state.forward * 3.55 - state.up * 0.22,
    );
    if (pMount.isInFrontOfCamera) {
      _skidPaint.strokeWidth = (2.0 * scale).clamp(1.0, 4.0);
      canvas.drawLine(
        Offset(pMount.screenX, pMount.screenY),
        Offset(pGimbal.screenX, pGimbal.screenY),
        _skidPaint,
      );
    }

    final double sphereRadius = (4.8 * scale).clamp(2.2, 13.0);
    final Offset gCenter = Offset(pGimbal.screenX, pGimbal.screenY);

    // Obudowa kamery Cineflex
    canvas.drawCircle(gCenter, sphereRadius, _gimbalHousingPaint);

    // Wektor celowania obiektywu w stronę czoła wyścigu
    final Vector3 aimDir = (state.gimbalTargetWorld - gimbalPos).normalized();
    final ProjectedPoint3D pAim =
        projection.worldToScreen(gimbalPos + aimDir * 0.42);
    final Offset lensOffset = pAim.isInFrontOfCamera
        ? Offset(
            (pAim.screenX - gCenter.dx).clamp(-sphereRadius * 0.45, sphereRadius * 0.45),
            (pAim.screenY - gCenter.dy).clamp(-sphereRadius * 0.45, sphereRadius * 0.45),
          )
        : Offset(0.0, sphereRadius * 0.25);

    final Offset lensCenter = gCenter + lensOffset;
    canvas.drawCircle(lensCenter, sphereRadius * 0.48, _gimbalLensPaint);
    canvas.drawCircle(
      lensCenter + Offset(-sphereRadius * 0.12, -sphereRadius * 0.12),
      sphereRadius * 0.16,
      _gimbalGlintPaint,
    );

    // Dioda REC na kamerze
    _beaconPaint.color = AppColors.crimsonAlert;
    canvas.drawCircle(
      gCenter + Offset(sphereRadius * 0.55, -sphereRadius * 0.48),
      (1.5 * scale).clamp(0.9, 3.0),
      _beaconPaint,
    );
  }

  void _paintBeaconLight(
    Canvas canvas,
    Scene3DMathProjection projection,
    TvHelicopterState state,
    double scale,
  ) {
    final Vector3 beaconWorld =
        state.worldPosition - state.forward * 5.05 + state.up * 1.48;
    final ProjectedPoint3D pBeacon = projection.worldToScreen(beaconWorld);
    if (!pBeacon.isInFrontOfCamera) return;

    _beaconPaint.color =
        AppColors.crimsonAlert.withValues(alpha: state.beaconIntensity);
    canvas.drawCircle(
      Offset(pBeacon.screenX, pBeacon.screenY),
      (3.4 * scale * (0.7 + state.beaconIntensity * 0.6)).clamp(1.5, 8.0),
      _beaconPaint,
    );
  }

  void _paintMainRotor(
    Canvas canvas,
    Scene3DMathProjection projection,
    TvHelicopterState state,
    double scale,
  ) {
    final Vector3 hubWorld = state.mainRotorHubWorldPosition;
    final ProjectedPoint3D pHub = projection.worldToScreen(hubWorld);
    if (!pHub.isInFrontOfCamera) return;

    // Dysk rozmycia ruchu wirnika (Motion-Blur Rotor Disc)
    final List<Offset> discPoints = [];
    const int discSegments = 20;
    for (int i = 0; i < discSegments; i++) {
      final double a = (i / discSegments) * 2.0 * math.pi;
      final Vector3 rimWorld = hubWorld +
          state.forward * (math.cos(a) * config.mainRotorRadiusMeters) +
          state.right * (math.sin(a) * config.mainRotorRadiusMeters);
      final ProjectedPoint3D pRim = projection.worldToScreen(rimWorld);
      if (pRim.isInFrontOfCamera) {
        discPoints.add(Offset(pRim.screenX, pRim.screenY));
      }
    }

    if (discPoints.length >= 6) {
      final Path discPath = Path()..addPolygon(discPoints, true);
      canvas.drawPath(discPath, _rotorDiscPaint);
      _rotorDiscRingPaint.strokeWidth = (1.1 * scale).clamp(0.6, 2.2);
      canvas.drawPath(discPath, _rotorDiscRingPaint);
    }

    // 4 łopaty głównego wirnika (TV_Heli_Main_Rotor)
    _rotorBladePaint.strokeWidth = (2.4 * scale).clamp(1.1, 5.2);
    for (int i = 0; i < 4; i++) {
      final double bladeAngle =
          state.mainRotorAngleRadians + i * (math.pi * 0.5);
      final Vector3 tipWorld = hubWorld +
          state.forward * (math.cos(bladeAngle) * config.mainRotorRadiusMeters) +
          state.right * (math.sin(bladeAngle) * config.mainRotorRadiusMeters);
      final ProjectedPoint3D pTip = projection.worldToScreen(tipWorld);
      if (pTip.isInFrontOfCamera) {
        canvas.drawLine(
          Offset(pHub.screenX, pHub.screenY),
          Offset(pTip.screenX, pTip.screenY),
          _rotorBladePaint,
        );
      }
    }

    // Piasta wirnika
    _gimbalHousingPaint.style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(pHub.screenX, pHub.screenY),
      (2.8 * scale).clamp(1.4, 6.5),
      _gimbalHousingPaint,
    );
  }

  void _paintCallSignBadge(
    Canvas canvas,
    ProjectedPoint3D centerProj,
    double scale,
  ) {
    final String label = config.callSign;
    final TextPainter tp = _callSignPainterCache.putIfAbsent(label, () {
      return TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: AppColors.textPrimary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });

    const double padX = 7.0;
    const double padY = 3.0;
    final double w = tp.width + padX * 2.0;
    final double h = tp.height + padY * 2.0;
    final double yOffset = (26.0 * scale).clamp(16.0, 46.0);

    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerProj.screenX, centerProj.screenY - yOffset),
        width: w,
        height: h,
      ),
      const Radius.circular(6.0),
    );

    canvas.drawRRect(rect, _badgeBgPaint);
    canvas.drawRRect(rect, _badgeBorderPaint);
    tp.paint(
      canvas,
      Offset(rect.left + padX, rect.top + padY),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static double _wrapAngleRadians(double angle) {
    double a = angle;
    while (a > math.pi) {
      a -= 2.0 * math.pi;
    }
    while (a < -math.pi) {
      a += 2.0 * math.pi;
    }
    return a;
  }
}

// =============================================================================
// 4. CUSTOM PAINTER & RESPONSIVE KONTROLER PODGLĄDU HELIKOPTERA TV
// =============================================================================

/// [CustomPainter] rysujący helikopter telewizyjny, cień na szosie oraz podmuch na korony drzew.
class TvHelicopterSkyPainter extends CustomPainter {
  final TvHelicopterSkyRenderer renderer;
  final Scene3DMathProjection projection;
  final TvHelicopterState state;
  final HelicopterRoadShadowGeometry? roadShadow;
  final List<HelicopterDownwashTreeInput> nearbyTrees;
  final List<HelicopterTreeSwayDisplacement>? precomputedTreeSways;
  final double elapsedSeconds;

  const TvHelicopterSkyPainter({
    required this.renderer,
    required this.projection,
    required this.state,
    this.roadShadow,
    this.nearbyTrees = const [],
    this.precomputedTreeSways,
    this.elapsedSeconds = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    renderer.paint(
      canvas: canvas,
      size: size,
      projection: projection,
      state: state,
      roadShadow: roadShadow,
      nearbyTrees: nearbyTrees,
      precomputedTreeSways: precomputedTreeSways,
      elapsedSeconds: elapsedSeconds,
    );
  }

  @override
  bool shouldRepaint(covariant TvHelicopterSkyPainter oldDelegate) {
    return oldDelegate.elapsedSeconds != elapsedSeconds ||
        oldDelegate.state != state ||
        oldDelegate.roadShadow != roadShadow;
  }
}

/// Responsywny panel sterowania i telemetrii helikoptera telewizyjnego
/// zgodny z paletą [AppColors], czcionką `Inter` oraz pełnymi stanami interakcji.
class TvHelicopterTelemetryControlPanel extends StatefulWidget {
  final TvHelicopterFlightMode currentMode;
  final bool enabled;
  final bool showRoadShadow;
  final bool enableDownwashWind;
  final double altitudeMeters;
  final ValueChanged<TvHelicopterFlightMode>? onModeChanged;
  final ValueChanged<bool>? onToggleEnabled;
  final ValueChanged<bool>? onToggleRoadShadow;
  final ValueChanged<bool>? onToggleDownwashWind;

  const TvHelicopterTelemetryControlPanel({
    super.key,
    required this.currentMode,
    this.enabled = true,
    this.showRoadShadow = true,
    this.enableDownwashWind = true,
    this.altitudeMeters = 22.0,
    this.onModeChanged,
    this.onToggleEnabled,
    this.onToggleRoadShadow,
    this.onToggleDownwashWind,
  });

  @override
  State<TvHelicopterTelemetryControlPanel> createState() =>
      _TvHelicopterTelemetryControlPanelState();
}

class _TvHelicopterTelemetryControlPanelState
    extends State<TvHelicopterTelemetryControlPanel> {
  TvHelicopterFlightMode? _hoveredMode;
  TvHelicopterFlightMode? _focusedMode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 520.0;
        final double horizontalPad = isCompact ? 12.0 : 16.0;

        return Container(
          padding: EdgeInsets.all(horizontalPad),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      color: widget.enabled
                          ? AppColors.statusSuccess
                          : AppColors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'HELIKOPTER TV • ${widget.altitudeMeters.toStringAsFixed(0)} m AGL',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _InteractiveToggleChip(
                    label: widget.enabled ? 'AKTYWNY' : 'WYŁ.',
                    isActive: widget.enabled,
                    isDisabled: widget.onToggleEnabled == null,
                    onTap: widget.onToggleEnabled != null
                        ? () => widget.onToggleEnabled!(!widget.enabled)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: TvHelicopterFlightMode.values.map((mode) {
                  final bool isSelected = widget.currentMode == mode;
                  final bool isDisabled = !widget.enabled || widget.onModeChanged == null;
                  final bool isHovered = _hoveredMode == mode;
                  final bool isFocused = _focusedMode == mode;

                  final Color bgColor = isDisabled
                      ? AppColors.background.withValues(alpha: 0.5)
                      : isSelected
                          ? AppColors.primaryAccent
                          : isHovered
                              ? AppColors.surfaceLight
                              : AppColors.background;

                  final Color borderColor = isFocused
                      ? AppColors.goldAccent
                      : isSelected
                          ? AppColors.goldAccent
                          : AppColors.cardBorder;

                  return FocusableActionDetector(
                    enabled: !isDisabled,
                    onShowHoverHighlight: (hovered) {
                      setState(() => _hoveredMode = hovered ? mode : null);
                    },
                    onShowFocusHighlight: (focused) {
                      setState(() => _focusedMode = focused ? mode : null);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: borderColor, width: 1.0),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isDisabled ? null : () => widget.onModeChanged!(mode),
                          borderRadius: BorderRadius.circular(10.0),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 7.0,
                            ),
                            child: Text(
                              mode.labelPl,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: isCompact ? 11.0 : 12.0,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isDisabled
                                    ? AppColors.textSecondary.withValues(alpha: 0.45)
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(growable: false),
              ),
              const SizedBox(height: 10.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  _InteractiveToggleChip(
                    label: 'Cień na szosie',
                    isActive: widget.showRoadShadow,
                    isDisabled: !widget.enabled || widget.onToggleRoadShadow == null,
                    onTap: widget.onToggleRoadShadow != null
                        ? () =>
                            widget.onToggleRoadShadow!(!widget.showRoadShadow)
                        : null,
                  ),
                  _InteractiveToggleChip(
                    label: 'Podmuch na drzewa',
                    isActive: widget.enableDownwashWind,
                    isDisabled:
                        !widget.enabled || widget.onToggleDownwashWind == null,
                    onTap: widget.onToggleDownwashWind != null
                        ? () => widget.onToggleDownwashWind!(
                            !widget.enableDownwashWind)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InteractiveToggleChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _InteractiveToggleChip({
    required this.label,
    required this.isActive,
    required this.isDisabled,
    this.onTap,
  });

  @override
  State<_InteractiveToggleChip> createState() => _InteractiveToggleChipState();
}

class _InteractiveToggleChipState extends State<_InteractiveToggleChip> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.isDisabled
        ? AppColors.background.withValues(alpha: 0.45)
        : widget.isActive
            ? AppColors.surfaceLight
            : _isHovered
                ? AppColors.surfaceLight.withValues(alpha: 0.65)
                : AppColors.background;

    final Color border = _isFocused
        ? AppColors.goldAccent
        : widget.isActive
            ? AppColors.accentBlue
            : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (h) => setState(() => _isHovered = h),
      onShowFocusHighlight: (f) => setState(() => _isFocused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: border, width: 1.0),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isDisabled ? null : widget.onTap,
            borderRadius: BorderRadius.circular(10.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                  color: widget.isDisabled
                      ? AppColors.textSecondary.withValues(alpha: 0.45)
                      : widget.isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
