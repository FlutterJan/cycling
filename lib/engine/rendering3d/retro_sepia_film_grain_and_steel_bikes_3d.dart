// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/retro/golden_era_retro_season_model.dart';

/// Tryb filtra telewizyjnego / taśmy filmowej dla widoku 3D ery historycznej.
enum RetroBroadcastFilterMode {
  /// Taśma celuloidowa 16mm z ciepłą sepią, ziarnem i rysami pionowymi (lata 70.).
  film16mmSepia1970s(
    label: '16mm Sepia (1970s)',
    badgeText: '16MM FILM · 24 FPS',
    defaultGrain: 0.68,
    defaultSepia: 0.72,
    defaultVignette: 0.58,
    defaultTrackingJitter: 0.08,
    defaultScanlineOpacity: 0.06,
  ),

  /// Analogowa kaseta VHS z liniami skanowania, aberracją RGB i pasem tracking (lata 80.).
  vhsAnalog1980s(
    label: 'VHS Analog (1980s)',
    badgeText: 'VHS SP · HI-FI',
    defaultGrain: 0.42,
    defaultSepia: 0.24,
    defaultVignette: 0.44,
    defaultTrackingJitter: 0.62,
    defaultScanlineOpacity: 0.34,
  ),

  /// Wczesna telewizja Betacam SP z subtelnym przeplotem i nasyceniem (lata 90.).
  earlyBetacam1990s(
    label: 'Betacam TV (1990s)',
    badgeText: 'BETACAM SP · 50i',
    defaultGrain: 0.20,
    defaultSepia: 0.08,
    defaultVignette: 0.26,
    defaultTrackingJitter: 0.16,
    defaultScanlineOpacity: 0.18,
  ),

  /// Cyfrowa rekonstrukcja archiwalna bez degradacji obrazu.
  cleanRestoredDigital(
    label: 'Rekonstrukcja HD',
    badgeText: 'ARCHIVE HD · 60P',
    defaultGrain: 0.04,
    defaultSepia: 0.0,
    defaultVignette: 0.12,
    defaultTrackingJitter: 0.0,
    defaultScanlineOpacity: 0.0,
  );

  final String label;
  final String badgeText;
  final double defaultGrain;
  final double defaultSepia;
  final double defaultVignette;
  final double defaultTrackingJitter;
  final double defaultScanlineOpacity;

  const RetroBroadcastFilterMode({
    required this.label,
    required this.badgeText,
    required this.defaultGrain,
    required this.defaultSepia,
    required this.defaultVignette,
    required this.defaultTrackingJitter,
    required this.defaultScanlineOpacity,
  });
}

/// Preset historycznego roweru stalowego / wczesnotytanowego do renderera 3D.
enum SteelBikeFramePreset {
  columbusSlChrome1974(
    label: 'Columbus SL · 1974',
    decade: GoldenEraDecade.steelCannibalEra1970s,
    tubeDiameterScale: 1.0,
    chromeFactor: 1.25,
    supportsDowntubeShifters: true,
    frameColor: Color(0xFF8E4A49),
    jerseyColor: Color(0xFF8E4A49),
    stripeColor: Color(0xFFD4AF37),
  ),
  reynolds531Classic1978(
    label: 'Reynolds 531 · 1978',
    decade: GoldenEraDecade.steelCannibalEra1970s,
    tubeDiameterScale: 0.96,
    chromeFactor: 1.15,
    supportsDowntubeShifters: true,
    frameColor: Color(0xFF1F4E79),
    jerseyColor: Color(0xFF2563EB),
    stripeColor: Color(0xFFF3F4F6),
  ),
  columbusSlxTeam1985(
    label: 'Columbus SLX · 1985',
    decade: GoldenEraDecade.badgerAndAeroDawn1980s,
    tubeDiameterScale: 1.05,
    chromeFactor: 1.08,
    supportsDowntubeShifters: true,
    frameColor: Color(0xFFD4AF37),
    jerseyColor: Color(0xFF181B22),
    stripeColor: Color(0xFFD4AF37),
  ),
  titaniumEarlySti1994(
    label: 'Tytan Gr.9 · 1994',
    decade: GoldenEraDecade.stiAndRadioDawn1990s,
    tubeDiameterScale: 1.18,
    chromeFactor: 0.85,
    supportsDowntubeShifters: false,
    frameColor: Color(0xFF6B7280),
    jerseyColor: Color(0xFF10B981),
    stripeColor: Color(0xFFF3F4F6),
  );

  final String label;
  final GoldenEraDecade decade;
  final double tubeDiameterScale;
  final double chromeFactor;
  final bool supportsDowntubeShifters;
  final Color frameColor;
  final Color jerseyColor;
  final Color stripeColor;

  const SteelBikeFramePreset({
    required this.label,
    required this.decade,
    required this.tubeDiameterScale,
    required this.chromeFactor,
    required this.supportsDowntubeShifters,
    required this.frameColor,
    required this.jerseyColor,
    required this.stripeColor,
  });
}

/// Styl nakrycia głowy kolarza w widoku 3D ery historycznej.
enum RetroCapStyle {
  classicCottonCasquette('Czapeczka bawełniana'),
  hairnetLeatherBanane('Skórzany kask "Banane"'),
  teamWoolWinterCap('Czapka wełniana');

  final String label;
  const RetroCapStyle(this.label);
}

/// Konfiguracja renderera 3D chromowanych muf, czapeczek, bidonów i filtra TV.
@immutable
class RetroSepiaFilmConfig {
  final RetroBroadcastFilterMode filterMode;
  final double filmGrainIntensity;
  final double sepiaWarmth;
  final double vignetteStrength;
  final double vhsTrackingJitter;
  final double scanlineOpacity;
  final double chromeSpecularBoost;
  final bool enableHandlebarBidons;
  final bool enableCasquette;
  final bool enableDowntubeShifters;

  const RetroSepiaFilmConfig({
    this.filterMode = RetroBroadcastFilterMode.film16mmSepia1970s,
    this.filmGrainIntensity = 0.68,
    this.sepiaWarmth = 0.72,
    this.vignetteStrength = 0.58,
    this.vhsTrackingJitter = 0.08,
    this.scanlineOpacity = 0.06,
    this.chromeSpecularBoost = 1.15,
    this.enableHandlebarBidons = true,
    this.enableCasquette = true,
    this.enableDowntubeShifters = true,
  });

  /// Tworzy konfigurację dopasowaną do wybranej dekady trybu Złotej Ery.
  factory RetroSepiaFilmConfig.forDecade(GoldenEraDecade decade) {
    final RetroBroadcastFilterMode mode;
    switch (decade) {
      case GoldenEraDecade.steelCannibalEra1970s:
        mode = RetroBroadcastFilterMode.film16mmSepia1970s;
      case GoldenEraDecade.badgerAndAeroDawn1980s:
        mode = RetroBroadcastFilterMode.vhsAnalog1980s;
      case GoldenEraDecade.stiAndRadioDawn1990s:
        mode = RetroBroadcastFilterMode.earlyBetacam1990s;
      case GoldenEraDecade.carbonAndPowerEra2000s:
        mode = RetroBroadcastFilterMode.cleanRestoredDigital;
    }
    return RetroSepiaFilmConfig(
      filterMode: mode,
      filmGrainIntensity: mode.defaultGrain,
      sepiaWarmth: mode.defaultSepia,
      vignetteStrength: mode.defaultVignette,
      vhsTrackingJitter: mode.defaultTrackingJitter,
      scanlineOpacity: mode.defaultScanlineOpacity,
      chromeSpecularBoost: decade == GoldenEraDecade.steelCannibalEra1970s
          ? 1.25
          : decade == GoldenEraDecade.badgerAndAeroDawn1980s
              ? 1.10
              : 0.85,
      enableHandlebarBidons: decade == GoldenEraDecade.steelCannibalEra1970s ||
          decade == GoldenEraDecade.badgerAndAeroDawn1980s,
      enableCasquette: decade != GoldenEraDecade.carbonAndPowerEra2000s,
      enableDowntubeShifters:
          decade == GoldenEraDecade.steelCannibalEra1970s ||
              decade == GoldenEraDecade.badgerAndAeroDawn1980s,
    );
  }

  RetroSepiaFilmConfig copyWith({
    RetroBroadcastFilterMode? filterMode,
    double? filmGrainIntensity,
    double? sepiaWarmth,
    double? vignetteStrength,
    double? vhsTrackingJitter,
    double? scanlineOpacity,
    double? chromeSpecularBoost,
    bool? enableHandlebarBidons,
    bool? enableCasquette,
    bool? enableDowntubeShifters,
  }) {
    return RetroSepiaFilmConfig(
      filterMode: filterMode ?? this.filterMode,
      filmGrainIntensity:
          (filmGrainIntensity ?? this.filmGrainIntensity).clamp(0.0, 1.0),
      sepiaWarmth: (sepiaWarmth ?? this.sepiaWarmth).clamp(0.0, 1.0),
      vignetteStrength:
          (vignetteStrength ?? this.vignetteStrength).clamp(0.0, 1.0),
      vhsTrackingJitter:
          (vhsTrackingJitter ?? this.vhsTrackingJitter).clamp(0.0, 1.0),
      scanlineOpacity:
          (scanlineOpacity ?? this.scanlineOpacity).clamp(0.0, 1.0),
      chromeSpecularBoost:
          (chromeSpecularBoost ?? this.chromeSpecularBoost).clamp(0.0, 1.5),
      enableHandlebarBidons:
          enableHandlebarBidons ?? this.enableHandlebarBidons,
      enableCasquette: enableCasquette ?? this.enableCasquette,
      enableDowntubeShifters:
          enableDowntubeShifters ?? this.enableDowntubeShifters,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RetroSepiaFilmConfig &&
        other.filterMode == filterMode &&
        other.filmGrainIntensity == filmGrainIntensity &&
        other.sepiaWarmth == sepiaWarmth &&
        other.vignetteStrength == vignetteStrength &&
        other.vhsTrackingJitter == vhsTrackingJitter &&
        other.scanlineOpacity == scanlineOpacity &&
        other.chromeSpecularBoost == chromeSpecularBoost &&
        other.enableHandlebarBidons == enableHandlebarBidons &&
        other.enableCasquette == enableCasquette &&
        other.enableDowntubeShifters == enableDowntubeShifters;
  }

  @override
  int get hashCode => Object.hash(
        filterMode,
        filmGrainIntensity,
        sepiaWarmth,
        vignetteStrength,
        vhsTrackingJitter,
        scanlineOpacity,
        chromeSpecularBoost,
        enableHandlebarBidons,
        enableCasquette,
        enableDowntubeShifters,
      );
}

/// Pozycja i stan lutowanej chromowanej mufy stalowej ramy w przestrzeni 3D.
@immutable
class ChromeLug3dSpec {
  final String id;
  final vm.Vector3 position3d;
  final double radiusMeters;
  final double sleeveLengthMeters;
  final double specularIntensity;

  const ChromeLug3dSpec({
    required this.id,
    required this.position3d,
    required this.radiusMeters,
    required this.sleeveLengthMeters,
    required this.specularIntensity,
  });
}

/// Bidon aluminiowy w drucianym koszyku montowanym na kierownicy (lata 70./80.).
@immutable
class HandlebarBidonCage3dSpec {
  final bool isLeftSide;
  final vm.Vector3 mountPosition3d;
  final double liquidFillRatio;
  final double swayAngleRad;
  final Color bottleColor;
  final Color stripeColor;

  const HandlebarBidonCage3dSpec({
    required this.isLeftSide,
    required this.mountPosition3d,
    required this.liquidFillRatio,
    required this.swayAngleRad,
    required this.bottleColor,
    required this.stripeColor,
  });
}

/// Parametry 3D bawełnianej czapeczki kolarskiej (Casquette) na głowie kolarza.
@immutable
class CyclingCasquette3dSpec {
  final RetroCapStyle style;
  final vm.Vector3 headAnchor3d;
  final double brimPitchRad;
  final double windFlutterRad;
  final Color crownColor;
  final Color centerStripeColor;

  const CyclingCasquette3dSpec({
    required this.style,
    required this.headAnchor3d,
    required this.brimPitchRad,
    required this.windFlutterRad,
    required this.crownColor,
    required this.centerStripeColor,
  });
}

/// Wejściowa poza kolarza i parametry jazdy do ewaluacji klatki 3D.
@immutable
class RetroSteelBikeRider3dPose {
  final SteelBikeFramePreset framePreset;
  final RetroCapStyle capStyle;
  final double speedKmh;
  final double cadenceRpm;
  final double roadGradientPercent;
  final double cameraYawRad;
  final double cameraPitchRad;
  final double leftBidonFill;
  final double rightBidonFill;
  final bool isOutOfSaddle;

  const RetroSteelBikeRider3dPose({
    this.framePreset = SteelBikeFramePreset.columbusSlChrome1974,
    this.capStyle = RetroCapStyle.classicCottonCasquette,
    this.speedKmh = 41.5,
    this.cadenceRpm = 88.0,
    this.roadGradientPercent = 6.2,
    this.cameraYawRad = 0.48,
    this.cameraPitchRad = 0.16,
    this.leftBidonFill = 0.78,
    this.rightBidonFill = 0.54,
    this.isOutOfSaddle = false,
  });

  RetroSteelBikeRider3dPose copyWith({
    SteelBikeFramePreset? framePreset,
    RetroCapStyle? capStyle,
    double? speedKmh,
    double? cadenceRpm,
    double? roadGradientPercent,
    double? cameraYawRad,
    double? cameraPitchRad,
    double? leftBidonFill,
    double? rightBidonFill,
    bool? isOutOfSaddle,
  }) {
    return RetroSteelBikeRider3dPose(
      framePreset: framePreset ?? this.framePreset,
      capStyle: capStyle ?? this.capStyle,
      speedKmh: (speedKmh ?? this.speedKmh).clamp(5.0, 95.0),
      cadenceRpm: (cadenceRpm ?? this.cadenceRpm).clamp(35.0, 140.0),
      roadGradientPercent:
          (roadGradientPercent ?? this.roadGradientPercent).clamp(-18.0, 24.0),
      cameraYawRad: cameraYawRad ?? this.cameraYawRad,
      cameraPitchRad: (cameraPitchRad ?? this.cameraPitchRad).clamp(-0.35, 0.75),
      leftBidonFill: (leftBidonFill ?? this.leftBidonFill).clamp(0.0, 1.0),
      rightBidonFill: (rightBidonFill ?? this.rightBidonFill).clamp(0.0, 1.0),
      isOutOfSaddle: isOutOfSaddle ?? this.isOutOfSaddle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RetroSteelBikeRider3dPose &&
        other.framePreset == framePreset &&
        other.capStyle == capStyle &&
        other.speedKmh == speedKmh &&
        other.cadenceRpm == cadenceRpm &&
        other.roadGradientPercent == roadGradientPercent &&
        other.cameraYawRad == cameraYawRad &&
        other.cameraPitchRad == cameraPitchRad &&
        other.leftBidonFill == leftBidonFill &&
        other.rightBidonFill == rightBidonFill &&
        other.isOutOfSaddle == isOutOfSaddle;
  }

  @override
  int get hashCode => Object.hash(
        framePreset,
        capStyle,
        speedKmh,
        cadenceRpm,
        roadGradientPercent,
        cameraYawRad,
        cameraPitchRad,
        leftBidonFill,
        rightBidonFill,
        isOutOfSaddle,
      );
}

/// Wynik rzutowania punktu 3D na ekran 2D wraz z głębokością Z-buffer.
@immutable
class Projected3dVertex {
  final Offset offset;
  final double depth;
  final double scale;

  const Projected3dVertex({
    required this.offset,
    required this.depth,
    required this.scale,
  });
}

/// Pełny stan wyrenderowanej klatki 3D z telemetrią muf, bidonów, czapeczki i filtra TV.
@immutable
class RetroFilmGrainFrameState {
  final RetroSepiaFilmConfig config;
  final RetroSteelBikeRider3dPose pose;
  final double timeSeconds;
  final int frameIndex;
  final double crankAngleRad;
  final double effectiveSepiaAmount;
  final double vhsHorizontalShiftPx;
  final double vhsTrackingBandY;
  final double chromaticAberrationPx;
  final double estimatedSignalDb;
  final List<ChromeLug3dSpec> chromeLugs;
  final List<HandlebarBidonCage3dSpec> handlebarBidons;
  final CyclingCasquette3dSpec casquette;

  const RetroFilmGrainFrameState({
    required this.config,
    required this.pose,
    required this.timeSeconds,
    required this.frameIndex,
    required this.crankAngleRad,
    required this.effectiveSepiaAmount,
    required this.vhsHorizontalShiftPx,
    required this.vhsTrackingBandY,
    required this.chromaticAberrationPx,
    required this.estimatedSignalDb,
    required this.chromeLugs,
    required this.handlebarBidons,
    required this.casquette,
  });
}

/// Deterministyczny silnik ewaluacji sceny 3D stalowych rowerów i filtra 16mm/VHS.
class RetroSepiaFilmGrainAndSteelBikes3dRenderer {
  const RetroSepiaFilmGrainAndSteelBikes3dRenderer();

  /// Ewaluuje geometrię chromowanych muf, bidonów na kierownicy, czapeczki oraz zakłóceń TV.
  RetroFilmGrainFrameState evaluateFrame({
    required RetroSepiaFilmConfig config,
    required RetroSteelBikeRider3dPose pose,
    required double timeSeconds,
  }) {
    final double safeTime = timeSeconds.isFinite ? math.max(0.0, timeSeconds) : 0.0;
    final int fps = config.filterMode == RetroBroadcastFilterMode.film16mmSepia1970s
        ? 24
        : 30;
    final int frameIndex = (safeTime * fps).floor();

    // Kąt korby wynikający z kadencji RPM
    final double omegaRadPerSec = (pose.cadenceRpm / 60.0) * math.pi * 2.0;
    final double crankAngle = (safeTime * omegaRadPerSec) % (math.pi * 2.0);

    // Subtelne kołysanie roweru przy pedałowaniu (mocniejsze na stojąco)
    final double bikeRockAmp = pose.isOutOfSaddle ? 0.065 : 0.018;
    final double sway = math.sin(crankAngle) * bikeRockAmp;

    // Chromowane mufy lutowane (5 kluczowych węzłów ramy stalowej)
    final double chromeBoost =
        (config.chromeSpecularBoost * pose.framePreset.chromeFactor)
            .clamp(0.0, 2.0);
    final double specPulse =
        0.72 + 0.28 * math.sin(safeTime * 2.1 + pose.cameraYawRad * 2.0);

    final List<ChromeLug3dSpec> lugs = <ChromeLug3dSpec>[
      ChromeLug3dSpec(
        id: 'head_upper',
        position3d: vm.Vector3(0.36, 0.86, 0.0),
        radiusMeters: 0.022 * pose.framePreset.tubeDiameterScale,
        sleeveLengthMeters: 0.048,
        specularIntensity: (specPulse * chromeBoost).clamp(0.0, 1.5),
      ),
      ChromeLug3dSpec(
        id: 'head_lower',
        position3d: vm.Vector3(0.39, 0.72, 0.0),
        radiusMeters: 0.023 * pose.framePreset.tubeDiameterScale,
        sleeveLengthMeters: 0.052,
        specularIntensity: ((1.0 - specPulse * 0.3) * chromeBoost).clamp(0.0, 1.5),
      ),
      ChromeLug3dSpec(
        id: 'seat_cluster',
        position3d: vm.Vector3(-0.18, 0.84, 0.0),
        radiusMeters: 0.021 * pose.framePreset.tubeDiameterScale,
        sleeveLengthMeters: 0.045,
        specularIntensity: (specPulse * chromeBoost).clamp(0.0, 1.5),
      ),
      ChromeLug3dSpec(
        id: 'bottom_bracket',
        position3d: vm.Vector3(-0.04, 0.31, 0.0),
        radiusMeters: 0.028 * pose.framePreset.tubeDiameterScale,
        sleeveLengthMeters: 0.068,
        specularIntensity: (0.85 * chromeBoost).clamp(0.0, 1.5),
      ),
      ChromeLug3dSpec(
        id: 'fork_crown',
        position3d: vm.Vector3(0.41, 0.65, 0.0),
        radiusMeters: 0.020 * pose.framePreset.tubeDiameterScale,
        sleeveLengthMeters: 0.042,
        specularIntensity: (specPulse * chromeBoost).clamp(0.0, 1.5),
      ),
    ];

    // Podwójne bidony w koszykach na kierownicy (ikona wyścigów lat 70./80.)
    final List<HandlebarBidonCage3dSpec> bidons = config.enableHandlebarBidons
        ? <HandlebarBidonCage3dSpec>[
            HandlebarBidonCage3dSpec(
              isLeftSide: true,
              mountPosition3d: vm.Vector3(0.45, 0.90, -0.11),
              liquidFillRatio: pose.leftBidonFill,
              swayAngleRad: sway,
              bottleColor: const Color(0xFFE5E7EB),
              stripeColor: pose.framePreset.frameColor,
            ),
            HandlebarBidonCage3dSpec(
              isLeftSide: false,
              mountPosition3d: vm.Vector3(0.45, 0.90, 0.11),
              liquidFillRatio: pose.rightBidonFill,
              swayAngleRad: sway,
              bottleColor: const Color(0xFFE5E7EB),
              stripeColor: pose.framePreset.stripeColor,
            ),
          ]
        : const <HandlebarBidonCage3dSpec>[];

    // Czapeczka kolarska (Casquette) z podniesionym daszkiem drgającym od wiatru
    final double windFlutter =
        math.sin(safeTime * (6.0 + pose.speedKmh * 0.18)) * 0.045;
    final CyclingCasquette3dSpec casquette = CyclingCasquette3dSpec(
      style: pose.capStyle,
      headAnchor3d: vm.Vector3(0.14, pose.isOutOfSaddle ? 1.52 : 1.44, 0.0),
      brimPitchRad: -0.34 + windFlutter,
      windFlutterRad: windFlutter,
      crownColor: pose.framePreset.jerseyColor,
      centerStripeColor: pose.framePreset.stripeColor,
    );

    // Zakłócenia VHS / 16mm
    final double jitter = config.vhsTrackingJitter;
    final double vhsHorizontalShift = jitter > 0.01
        ? math.sin(safeTime * 19.3 + frameIndex * 1.7) * jitter * 8.5
        : 0.0;
    final double vhsBandY = (safeTime * 0.27) % 1.0;
    final double chromaPx =
        (jitter * 3.2 + config.filmGrainIntensity * 1.1).clamp(0.0, 5.0);
    final double signalDb =
        (48.0 - config.filmGrainIntensity * 14.0 - jitter * 12.0)
            .clamp(16.0, 52.0);

    return RetroFilmGrainFrameState(
      config: config,
      pose: pose,
      timeSeconds: safeTime,
      frameIndex: frameIndex,
      crankAngleRad: crankAngle,
      effectiveSepiaAmount: config.sepiaWarmth,
      vhsHorizontalShiftPx: vhsHorizontalShift,
      vhsTrackingBandY: vhsBandY,
      chromaticAberrationPx: chromaPx,
      estimatedSignalDb: signalDb,
      chromeLugs: lugs,
      handlebarBidons: bidons,
      casquette: casquette,
    );
  }

  /// Rzutuje punkt z lokalnej przestrzeni 3D roweru na 2D Canvas.
  Projected3dVertex projectPoint3d({
    required vm.Vector3 point,
    required Size viewport,
    required double yawRad,
    required double pitchRad,
    double focalLengthFactor = 1.65,
  }) {
    final double cosY = math.cos(yawRad);
    final double sinY = math.sin(yawRad);
    final double cosP = math.cos(pitchRad);
    final double sinP = math.sin(pitchRad);

    // Obrót wokół osi Y (yaw), potem X (pitch)
    final double x1 = point.x * cosY - point.z * sinY;
    final double z1 = point.x * sinY + point.z * cosY;
    final double y1 = point.y - 0.65; // Środek wysokości roweru

    final double y2 = y1 * cosP - z1 * sinP;
    final double z2 = y1 * sinP + z1 * cosP;

    const double cameraDist = 2.55;
    final double depth = math.max(0.45, cameraDist + z2);
    final double baseDim = math.min(viewport.width, viewport.height);
    final double scale = (baseDim * focalLengthFactor) / depth;

    final double screenX = viewport.width * 0.5 + x1 * scale;
    final double screenY = viewport.height * 0.58 - y2 * scale;

    return Projected3dVertex(
      offset: Offset(screenX, screenY),
      depth: depth,
      scale: scale,
    );
  }
}

/// CustomPainter rysujący stalowy rower z chromowanymi mufami, bidonami na kierownicy,
/// czapeczką kolarską oraz nakładką filtra TV 16mm/VHS.
class RetroSepiaFilmGrainAndSteelBikesPainter extends CustomPainter {
  final RetroFilmGrainFrameState frameState;
  final RetroSepiaFilmGrainAndSteelBikes3dRenderer renderer;

  const RetroSepiaFilmGrainAndSteelBikesPainter({
    required this.frameState,
    this.renderer = const RetroSepiaFilmGrainAndSteelBikes3dRenderer(),
  });

  Projected3dVertex _proj(vm.Vector3 p, Size size) {
    return renderer.projectPoint3d(
      point: p,
      viewport: size,
      yawRad: frameState.pose.cameraYawRad,
      pitchRad: frameState.pose.cameraPitchRad,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Delikatne drganie kamery VHS
    if (frameState.config.vhsTrackingJitter > 0.02) {
      canvas.translate(frameState.vhsHorizontalShiftPx * 0.35, 0.0);
    }

    _drawBackgroundAndRoad(canvas, size);
    _drawWheels(canvas, size);
    _drawSteelFrameAndChromeLugs(canvas, size);
    _drawDowntubeShiftersAndCables(canvas, size);
    _drawHandlebarBidons(canvas, size);
    _drawRiderAndCasquette(canvas, size);

    canvas.restore();

    // Post-processing 16mm Sepia / VHS / Vignette
    _drawRetroFilmAndVhsOverlay(canvas, size);
  }

  void _drawBackgroundAndRoad(Canvas canvas, Size size) {
    final double horizonY = size.height * 0.42;

    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF1A2230),
          Color(0xFF2B3444),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, horizonY));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizonY), skyPaint);

    final Paint roadPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF262A34),
          Color(0xFF14171F),
        ],
      ).createShader(
          Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY));
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
      roadPaint,
    );

    // Pasy ruchu na asfalcie zależne od prędkości
    final double roadOffset =
        (frameState.timeSeconds * frameState.pose.speedKmh * 6.5) % 90.0;
    final Paint dashPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.22)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final double groundY = size.height * 0.84;
    for (double x = -roadOffset; x < size.width + 60; x += 90.0) {
      canvas.drawLine(
        Offset(x, groundY),
        Offset(x + 36.0, groundY),
        dashPaint,
      );
    }
  }

  void _drawWheels(Canvas canvas, Size size) {
    final Projected3dVertex rearHub = _proj(vm.Vector3(-0.50, 0.34, 0.0), size);
    final Projected3dVertex frontHub = _proj(vm.Vector3(0.49, 0.34, 0.0), size);
    final double wheelRadiusPx = 0.34 * ((rearHub.scale + frontHub.scale) * 0.5);

    _drawSingleSpokedWheel(
      canvas,
      rearHub.offset,
      wheelRadiusPx,
      frameState.crankAngleRad * 3.2,
    );
    _drawSingleSpokedWheel(
      canvas,
      frontHub.offset,
      wheelRadiusPx,
      frameState.crankAngleRad * 3.2,
    );
  }

  void _drawSingleSpokedWheel(
    Canvas canvas,
    Offset center,
    double radius,
    double spinAngle,
  ) {
    // Opona szytka z beżowym bokiem (Skinwall Tubular)
    final Paint tirePaint = Paint()
      ..color = const Color(0xFF1F232B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3.5, radius * 0.11);
    canvas.drawCircle(center, radius, tirePaint);

    final Paint skinwallPaint = Paint()
      ..color = const Color(0xFFC29B61).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, radius * 0.045);
    canvas.drawCircle(center, radius * 0.94, skinwallPaint);

    // Płaska aluminiowa obręcz box-section
    final Paint rimPaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, radius * 0.04);
    canvas.drawCircle(center, radius * 0.90, rimPaint);

    // 16 widocznych par szprych stalowych z błyskiem
    final Paint spokePaint = Paint()
      ..color = const Color(0xFFE5E7EB).withValues(alpha: 0.55)
      ..strokeWidth = 1.0;
    const int spokeCount = 16;
    for (int i = 0; i < spokeCount; i++) {
      final double a = spinAngle + (i / spokeCount) * math.pi * 2.0;
      canvas.drawLine(
        center,
        Offset(
          center.dx + math.cos(a) * radius * 0.89,
          center.dy + math.sin(a) * radius * 0.89,
        ),
        spokePaint,
      );
    }

    // Piasta chromowana
    canvas.drawCircle(
      center,
      math.max(3.0, radius * 0.08),
      Paint()..color = const Color(0xFFF3F4F6),
    );
  }

  void _drawSteelFrameAndChromeLugs(Canvas canvas, Size size) {
    final Projected3dVertex bb = _proj(vm.Vector3(-0.04, 0.31, 0.0), size);
    final Projected3dVertex seatTop = _proj(vm.Vector3(-0.18, 0.84, 0.0), size);
    final Projected3dVertex headTop = _proj(vm.Vector3(0.36, 0.86, 0.0), size);
    final Projected3dVertex headBot = _proj(vm.Vector3(0.39, 0.72, 0.0), size);
    final Projected3dVertex rearDrop = _proj(vm.Vector3(-0.50, 0.34, 0.0), size);
    final Projected3dVertex frontDrop = _proj(vm.Vector3(0.49, 0.34, 0.0), size);
    final Projected3dVertex forkCrown = _proj(vm.Vector3(0.41, 0.65, 0.0), size);

    final double tubeStroke = math.max(
      3.0,
      bb.scale * 0.026 * frameState.pose.framePreset.tubeDiameterScale,
    );

    final Paint framePaint = Paint()
      ..color = frameState.pose.framePreset.frameColor
      ..strokeWidth = tubeStroke
      ..strokeCap = StrokeCap.round;

    final Paint stayPaint = Paint()
      ..color = frameState.pose.framePreset.frameColor
      ..strokeWidth = tubeStroke * 0.68
      ..strokeCap = StrokeCap.round;

    // Tylny trójkąt (chromowane dolne widełki + lakierowane górne)
    canvas.drawLine(bb.offset, rearDrop.offset, stayPaint);
    canvas.drawLine(seatTop.offset, rearDrop.offset, stayPaint);

    // Główny diament ramy stalowej
    canvas.drawLine(bb.offset, seatTop.offset, framePaint);
    canvas.drawLine(seatTop.offset, headTop.offset, framePaint);
    canvas.drawLine(bb.offset, headBot.offset, framePaint);
    canvas.drawLine(headTop.offset, headBot.offset, framePaint);

    // Widelec przedni (chromowany dół + lakierowana góra)
    canvas.drawLine(headBot.offset, forkCrown.offset, framePaint);
    final Paint chromeForkPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = tubeStroke * 0.82
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(forkCrown.offset, frontDrop.offset, chromeForkPaint);

    // Rysowanie chromowanych muf lutowanych (Chrome Lugs) z gradientem metalicznym
    for (final ChromeLug3dSpec lug in frameState.chromeLugs) {
      final Projected3dVertex p = _proj(lug.position3d, size);
      final double r = math.max(4.5, lug.radiusMeters * p.scale * 1.45);

      final Rect lugRect = Rect.fromCircle(center: p.offset, radius: r);
      final Paint lugPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withValues(
              alpha: (0.75 + lug.specularIntensity * 0.25).clamp(0.0, 1.0),
            ),
            const Color(0xFFBFC5CE),
            const Color(0xFF4B5563),
            const Color(0xFFF9FAFB),
          ],
          stops: const <double>[0.0, 0.35, 0.72, 1.0],
        ).createShader(lugRect);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: p.offset,
            width: r * 2.1,
            height: r * 1.45,
          ),
          Radius.circular(r * 0.45),
        ),
        lugPaint,
      );

      // Ostry błysk lustrzany na mufie
      if (lug.specularIntensity > 0.55) {
        canvas.drawCircle(
          p.offset + Offset(-r * 0.35, -r * 0.22),
          math.max(1.5, r * 0.28),
          Paint()
            ..color = Colors.white.withValues(
              alpha: (lug.specularIntensity * 0.55).clamp(0.0, 0.9),
            ),
        );
      }
    }

    // Korba i pedały z noskami (Toe Clips)
    final double crankR = 0.17 * bb.scale;
    final Offset pedalPos = Offset(
      bb.offset.dx + math.cos(frameState.crankAngleRad) * crankR,
      bb.offset.dy + math.sin(frameState.crankAngleRad) * crankR,
    );
    canvas.drawCircle(
      bb.offset,
      crankR * 0.42,
      Paint()
        ..color = const Color(0xFFD1D5DB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.drawLine(
      bb.offset,
      pedalPos,
      Paint()
        ..color = const Color(0xFFE5E7EB)
        ..strokeWidth = math.max(2.5, tubeStroke * 0.55)
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawDowntubeShiftersAndCables(Canvas canvas, Size size) {
    final Projected3dVertex headTop = _proj(vm.Vector3(0.36, 0.86, 0.0), size);
    final Projected3dVertex stemEnd = _proj(vm.Vector3(0.45, 0.95, 0.0), size);
    final Projected3dVertex barDrop = _proj(vm.Vector3(0.51, 0.80, 0.0), size);

    // Klasyczny wspornik kierownicy (Quill Stem) i kierownica baranek
    final Paint stemPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = math.max(3.0, headTop.scale * 0.022)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(headTop.offset, stemEnd.offset, stemPaint);

    final Path barPath = Path()
      ..moveTo(stemEnd.offset.dx, stemEnd.offset.dy)
      ..quadraticBezierTo(
        barDrop.offset.dx + 8,
        stemEnd.offset.dy + 2,
        barDrop.offset.dx,
        barDrop.offset.dy,
      )
      ..quadraticBezierTo(
        barDrop.offset.dx - 10,
        barDrop.offset.dy + 6,
        stemEnd.offset.dx - 2,
        barDrop.offset.dy + 4,
      );
    canvas.drawPath(
      barPath,
      Paint()
        ..color = const Color(0xFF1F2937)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.8, headTop.scale * 0.02)
        ..strokeCap = StrokeCap.round,
    );

    // Odsłonięte linki hamulcowe łukiem nad kierownicą
    final Path brakeCable = Path()
      ..moveTo(stemEnd.offset.dx + 4, stemEnd.offset.dy + 2)
      ..quadraticBezierTo(
        stemEnd.offset.dx - 16,
        stemEnd.offset.dy - 26,
        headTop.offset.dx - 6,
        headTop.offset.dy + 12,
      );
    canvas.drawPath(
      brakeCable,
      Paint()
        ..color = const Color(0xFF9CA3AF).withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Manetki na dolnej rurze ramy (Downtube Shifters)
    if (frameState.config.enableDowntubeShifters &&
        frameState.pose.framePreset.supportsDowntubeShifters) {
      final Projected3dVertex shifterMount =
          _proj(vm.Vector3(0.24, 0.58, 0.0), size);
      canvas.drawCircle(
        shifterMount.offset,
        math.max(3.0, shifterMount.scale * 0.018),
        Paint()..color = const Color(0xFFE5E7EB),
      );
      canvas.drawLine(
        shifterMount.offset,
        shifterMount.offset + const Offset(-7, -9),
        Paint()
          ..color = const Color(0xFFF3F4F6)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawHandlebarBidons(Canvas canvas, Size size) {
    if (!frameState.config.enableHandlebarBidons ||
        frameState.handlebarBidons.isEmpty) {
      return;
    }

    for (final HandlebarBidonCage3dSpec bidon in frameState.handlebarBidons) {
      final Projected3dVertex pos = _proj(bidon.mountPosition3d, size);
      final double w = math.max(9.0, pos.scale * 0.052);
      final double h = math.max(20.0, pos.scale * 0.125);

      canvas.save();
      canvas.translate(pos.offset.dx, pos.offset.dy);
      canvas.rotate(bidon.swayAngleRad);

      // Korpus aluminiowego bidonu
      final RRect bottleRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        Radius.circular(w * 0.35),
      );
      canvas.drawRRect(
        bottleRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              const Color(0xFF9CA3AF),
              bidon.bottleColor,
              const Color(0xFF6B7280),
            ],
          ).createShader(bottleRect.outerRect),
      );

      // Pasek drużynowy na bidonie
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: w, height: h * 0.24),
        Paint()..color = bidon.stripeColor,
      );

      // Korek / ustnik u góry
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0, -h * 0.54),
            width: w * 0.56,
            height: h * 0.16,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = AppColors.goldAccent,
      );

      // Druciany koszyk na kierownicy
      canvas.drawRRect(
        bottleRect,
        Paint()
          ..color = const Color(0xFFE5E7EB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );

      canvas.restore();
    }
  }

  void _drawRiderAndCasquette(Canvas canvas, Size size) {
    final Projected3dVertex hip = _proj(
      vm.Vector3(-0.18, frameState.pose.isOutOfSaddle ? 1.05 : 0.96, 0.0),
      size,
    );
    final Projected3dVertex shoulder = _proj(
      vm.Vector3(0.10, frameState.pose.isOutOfSaddle ? 1.35 : 1.28, 0.0),
      size,
    );
    final Projected3dVertex head =
        _proj(frameState.casquette.headAnchor3d, size);
    final Projected3dVertex hand = _proj(vm.Vector3(0.47, 0.92, 0.0), size);
    final Projected3dVertex bb = _proj(vm.Vector3(-0.04, 0.31, 0.0), size);

    final double crankR = 0.17 * bb.scale;
    final Offset foot = Offset(
      bb.offset.dx + math.cos(frameState.crankAngleRad) * crankR,
      bb.offset.dy + math.sin(frameState.crankAngleRad) * crankR,
    );
    final Offset knee = Offset(
      (hip.offset.dx + foot.dx) * 0.5 + crankR * 0.45,
      (hip.offset.dy + foot.dy) * 0.5 - crankR * 0.25,
    );

    // Noga
    final Paint legPaint = Paint()
      ..color = const Color(0xFFD6A888)
      ..strokeWidth = math.max(6.0, hip.scale * 0.065)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(hip.offset, knee, legPaint);
    canvas.drawLine(knee, foot, legPaint);

    // Wełniana koszulka drużynowa (Tułów)
    final Paint jerseyPaint = Paint()
      ..color = frameState.casquette.crownColor
      ..strokeWidth = math.max(10.0, hip.scale * 0.125)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(hip.offset, shoulder.offset, jerseyPaint);

    // Pasek mistrzowski na koszulce
    final Offset midTorso = Offset.lerp(hip.offset, shoulder.offset, 0.52)!;
    canvas.drawCircle(
      midTorso,
      math.max(4.5, hip.scale * 0.055),
      Paint()..color = frameState.casquette.centerStripeColor,
    );

    // Ramię do kierownicy
    canvas.drawLine(
      shoulder.offset,
      hand.offset,
      Paint()
        ..color = const Color(0xFFD6A888)
        ..strokeWidth = math.max(5.0, shoulder.scale * 0.052)
        ..strokeCap = StrokeCap.round,
    );

    // Głowa
    final double headR = math.max(8.0, head.scale * 0.092);
    canvas.drawCircle(
      head.offset,
      headR,
      Paint()..color = const Color(0xFFE0B495),
    );

    // Czapeczka kolarska (Casquette) lub skórzany kask "Banane"
    if (frameState.config.enableCasquette) {
      canvas.save();
      canvas.translate(head.offset.dx, head.offset.dy - headR * 0.28);

      final Rect capRect = Rect.fromCenter(
        center: Offset.zero,
        width: headR * 2.15,
        height: headR * 1.45,
      );

      if (frameState.casquette.style == RetroCapStyle.hairnetLeatherBanane) {
        // Skórzane pasy kasku "Banane"
        canvas.drawArc(
          capRect,
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = const Color(0xFF4B2E1E)
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(3.0, headR * 0.35),
        );
      } else {
        // Bawełniana/wełniana czapeczka kolarska
        canvas.drawArc(
          capRect,
          math.pi,
          math.pi,
          true,
          Paint()..color = frameState.casquette.crownColor,
        );
        // Centralny pas drużynowy na czapeczce
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(0, -headR * 0.35),
            width: headR * 0.45,
            height: headR * 0.62,
          ),
          Paint()..color = frameState.casquette.centerStripeColor,
        );
        // Podniesiony daszek (Casquette Brim) drgający na wietrze
        canvas.save();
        canvas.translate(headR * 0.92, -headR * 0.06);
        canvas.rotate(frameState.casquette.brimPitchRad);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, -headR * 0.16, headR * 0.95, headR * 0.30),
            const Radius.circular(3),
          ),
          Paint()..color = frameState.casquette.crownColor,
        );
        canvas.restore();
      }
      canvas.restore();
    }
  }

  void _drawRetroFilmAndVhsOverlay(Canvas canvas, Size size) {
    final RetroSepiaFilmConfig cfg = frameState.config;

    // 1. Ciepła sepia 16mm
    if (frameState.effectiveSepiaAmount > 0.01) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = const Color(0xFF704214)
              .withValues(alpha: frameState.effectiveSepiaAmount * 0.34)
          ..blendMode = BlendMode.color,
      );
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = const Color(0xFFD4AF37)
              .withValues(alpha: frameState.effectiveSepiaAmount * 0.10),
      );
    }

    // 2. Linie skanowania VHS / Betacam
    if (cfg.scanlineOpacity > 0.01) {
      final Paint scanPaint = Paint()
        ..color = Colors.black.withValues(alpha: cfg.scanlineOpacity * 0.65)
        ..strokeWidth = 1.0;
      for (double y = 0; y < size.height; y += 3.5) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), scanPaint);
      }
    }

    // 3. Pas zakłóceń VHS Tracking
    if (cfg.vhsTrackingJitter > 0.05) {
      final double bandY = frameState.vhsTrackingBandY * size.height;
      final double bandH = 12.0 + cfg.vhsTrackingJitter * 18.0;
      canvas.drawRect(
        Rect.fromLTWH(0, bandY, size.width, bandH),
        Paint()
          ..color = Colors.white.withValues(alpha: cfg.vhsTrackingJitter * 0.14),
      );
    }

    // 4. Deterministyczne ziarno 16mm i pionowe rysy celuloidu
    if (cfg.filmGrainIntensity > 0.02) {
      final math.Random rng = math.Random(frameState.frameIndex + 565);
      final int speckCount = (cfg.filmGrainIntensity * 140).round();
      final Paint grainLight = Paint()
        ..color = Colors.white.withValues(alpha: cfg.filmGrainIntensity * 0.18);
      final Paint grainDark = Paint()
        ..color = Colors.black.withValues(alpha: cfg.filmGrainIntensity * 0.22);

      for (int i = 0; i < speckCount; i++) {
        final double gx = rng.nextDouble() * size.width;
        final double gy = rng.nextDouble() * size.height;
        final double gr = 0.7 + rng.nextDouble() * 1.4;
        canvas.drawCircle(
          Offset(gx, gy),
          gr,
          i.isEven ? grainLight : grainDark,
        );
      }

      if (cfg.filterMode == RetroBroadcastFilterMode.film16mmSepia1970s &&
          frameState.frameIndex % 3 == 0) {
        final double scratchX = rng.nextDouble() * size.width;
        canvas.drawLine(
          Offset(scratchX, 0),
          Offset(scratchX + (rng.nextDouble() - 0.5) * 3.0, size.height),
          Paint()
            ..color = Colors.white.withValues(alpha: cfg.filmGrainIntensity * 0.16)
            ..strokeWidth = 0.9,
        );
      }
    }

    // 5. Winieta obiektywu archiwalnego
    if (cfg.vignetteStrength > 0.01) {
      final Rect fullRect = Offset.zero & size;
      canvas.drawRect(
        fullRect,
        Paint()
          ..shader = RadialGradient(
            radius: 0.95,
            colors: <Color>[
              Colors.transparent,
              Colors.black.withValues(alpha: cfg.vignetteStrength * 0.72),
            ],
            stops: const <double>[0.48, 1.0],
          ).createShader(fullRect),
      );
    }
  }

  @override
  bool shouldRepaint(covariant RetroSepiaFilmGrainAndSteelBikesPainter oldDelegate) {
    return oldDelegate.frameState.timeSeconds != frameState.timeSeconds ||
        oldDelegate.frameState.config != frameState.config ||
        oldDelegate.frameState.pose != frameState.pose;
  }
}

/// Produkcyjny panel kontrolny i podgląd 3D renderera ery stali, czapeczek,
/// bidonów na kierownicy oraz filtra TV 16mm/VHS.
class RetroSepiaFilmGrainAndSteelBikesPanel extends StatefulWidget {
  final RetroSepiaFilmConfig initialConfig;
  final RetroSteelBikeRider3dPose initialPose;
  final ValueChanged<RetroSepiaFilmConfig>? onConfigChanged;

  const RetroSepiaFilmGrainAndSteelBikesPanel({
    super.key,
    this.initialConfig = const RetroSepiaFilmConfig(),
    this.initialPose = const RetroSteelBikeRider3dPose(),
    this.onConfigChanged,
  });

  @override
  State<RetroSepiaFilmGrainAndSteelBikesPanel> createState() =>
      _RetroSepiaFilmGrainAndSteelBikesPanelState();
}

class _RetroSepiaFilmGrainAndSteelBikesPanelState
    extends State<RetroSepiaFilmGrainAndSteelBikesPanel>
    with SingleTickerProviderStateMixin {
  final RetroSepiaFilmGrainAndSteelBikes3dRenderer _renderer =
      const RetroSepiaFilmGrainAndSteelBikes3dRenderer();

  late AnimationController _animController;
  late RetroSepiaFilmConfig _config;
  late RetroSteelBikeRider3dPose _pose;
  double _elapsedSeconds = 0.35;
  bool _isPlaying = true;
  DateTime? _lastTick;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _pose = widget.initialPose;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addListener(_onTick);
    _animController.repeat();
  }

  void _onTick() {
    final DateTime now = DateTime.now();
    if (_lastTick != null && _isPlaying) {
      final double dt =
          (now.difference(_lastTick!).inMicroseconds / 1000000.0)
              .clamp(0.0, 0.1);
      setState(() {
        _elapsedSeconds += dt;
      });
    }
    _lastTick = now;
  }

  @override
  void dispose() {
    _animController.removeListener(_onTick);
    _animController.dispose();
    super.dispose();
  }

  void _updateConfig(RetroSepiaFilmConfig next) {
    setState(() {
      _config = next;
    });
    widget.onConfigChanged?.call(next);
  }

  void _applyFilterMode(RetroBroadcastFilterMode mode) {
    _updateConfig(
      _config.copyWith(
        filterMode: mode,
        filmGrainIntensity: mode.defaultGrain,
        sepiaWarmth: mode.defaultSepia,
        vignetteStrength: mode.defaultVignette,
        vhsTrackingJitter: mode.defaultTrackingJitter,
        scanlineOpacity: mode.defaultScanlineOpacity,
      ),
    );
  }

  void _applyFramePreset(SteelBikeFramePreset preset) {
    setState(() {
      _pose = _pose.copyWith(framePreset: preset);
      if (!preset.supportsDowntubeShifters && _config.enableDowntubeShifters) {
        _config = _config.copyWith(enableDowntubeShifters: false);
      }
    });
    widget.onConfigChanged?.call(_config);
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _lastTick = DateTime.now();
        _animController.repeat();
      } else {
        _animController.stop();
      }
    });
  }

  void _resetDefaults() {
    setState(() {
      _elapsedSeconds = 0.35;
      _pose = widget.initialPose;
      _config = widget.initialConfig;
    });
    widget.onConfigChanged?.call(_config);
  }

  @override
  Widget build(BuildContext context) {
    final RetroFilmGrainFrameState frameState = _renderer.evaluateFrame(
      config: _config,
      pose: _pose,
      timeSeconds: _elapsedSeconds,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 640;
        final bool isWide = constraints.maxWidth >= 960;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildHeader(frameState, isCompact),
                const SizedBox(height: 12),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(flex: 6, child: _buildViewport(frameState)),
                      const SizedBox(width: 16),
                      Expanded(flex: 5, child: _buildControls(frameState)),
                    ],
                  )
                else ...<Widget>[
                  _buildViewport(frameState),
                  const SizedBox(height: 12),
                  _buildControls(frameState),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(RetroFilmGrainFrameState state, bool isCompact) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Icon(
                Icons.movie_filter_rounded,
                color: AppColors.goldAccent,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Renderer 3D: Era Stali, Mufy i Filtr 16mm/VHS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    '${state.pose.framePreset.label} · ${state.config.filterMode.badgeText}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.goldAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _RetroActionButton(
              tooltip: _isPlaying ? 'Pauza animacji' : 'Wznów animację',
              icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              isActive: _isPlaying,
              onPressed: _togglePlayPause,
            ),
            const SizedBox(width: 8),
            _RetroActionButton(
              tooltip: 'Resetuj ustawienia',
              icon: Icons.restart_alt_rounded,
              isActive: false,
              onPressed: _resetDefaults,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewport(RetroFilmGrainFrameState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CustomPaint(
                  painter: RetroSepiaFilmGrainAndSteelBikesPainter(
                    frameState: state,
                    renderer: _renderer,
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Text(
                      state.config.filterMode.badgeText,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldAccent,
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              border: Border(
                top: BorderSide(color: AppTheme.borderColor, width: 1.0),
              ),
            ),
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              children: <Widget>[
                _TelemetryChip(
                  label: 'Mufy 3D',
                  value: '${state.chromeLugs.length} lut.',
                ),
                _TelemetryChip(
                  label: 'Bidony',
                  value: state.handlebarBidons.isEmpty
                      ? 'Wył.'
                      : '${state.handlebarBidons.length}x kier.',
                ),
                _TelemetryChip(
                  label: 'Sygnał TV',
                  value: '${state.estimatedSignalDb.toStringAsFixed(1)} dB',
                ),
                _TelemetryChip(
                  label: 'Kadencja',
                  value: '${state.pose.cadenceRpm.round()} RPM',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(RetroFilmGrainFrameState state) {
    final bool canUseDowntube = _pose.framePreset.supportsDowntubeShifters;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Filtr Transmisji TV',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: RetroBroadcastFilterMode.values
                .map(
                  (RetroBroadcastFilterMode mode) => _RetroChoiceChip(
                    label: mode.label,
                    selected: _config.filterMode == mode,
                    onTap: () => _applyFilterMode(mode),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Rama Stalowa & Epoka',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: SteelBikeFramePreset.values
                .map(
                  (SteelBikeFramePreset preset) => _RetroChoiceChip(
                    label: preset.label,
                    selected: _pose.framePreset == preset,
                    onTap: () => _applyFramePreset(preset),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _RetroToggleChip(
                label: 'Bidony na kierownicy',
                active: _config.enableHandlebarBidons,
                enabled: true,
                onChanged: (bool v) =>
                    _updateConfig(_config.copyWith(enableHandlebarBidons: v)),
              ),
              _RetroToggleChip(
                label: 'Czapeczka (Casquette)',
                active: _config.enableCasquette,
                enabled: true,
                onChanged: (bool v) =>
                    _updateConfig(_config.copyWith(enableCasquette: v)),
              ),
              _RetroToggleChip(
                label: 'Manetki na ramie',
                active: _config.enableDowntubeShifters,
                enabled: canUseDowntube,
                onChanged: (bool v) =>
                    _updateConfig(_config.copyWith(enableDowntubeShifters: v)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RetroSliderRow(
            label: 'Ziarno 16mm / Szum',
            value: _config.filmGrainIntensity,
            min: 0.0,
            max: 1.0,
            valueText: '${(_config.filmGrainIntensity * 100).round()}%',
            onChanged: (double v) =>
                _updateConfig(_config.copyWith(filmGrainIntensity: v)),
          ),
          _RetroSliderRow(
            label: 'Ciepło Sepii',
            value: _config.sepiaWarmth,
            min: 0.0,
            max: 1.0,
            valueText: '${(_config.sepiaWarmth * 100).round()}%',
            onChanged: (double v) =>
                _updateConfig(_config.copyWith(sepiaWarmth: v)),
          ),
          _RetroSliderRow(
            label: 'Połysk Chromu Muf',
            value: _config.chromeSpecularBoost,
            min: 0.0,
            max: 1.5,
            valueText: '${(_config.chromeSpecularBoost * 100).round()}%',
            onChanged: (double v) =>
                _updateConfig(_config.copyWith(chromeSpecularBoost: v)),
          ),
          _RetroSliderRow(
            label: 'Kąt kamery 3D',
            value: _pose.cameraYawRad,
            min: -1.2,
            max: 1.2,
            valueText: '${(_pose.cameraYawRad * 180 / math.pi).round()}°',
            onChanged: (double v) => setState(() {
              _pose = _pose.copyWith(cameraYawRad: v);
            }),
          ),
        ],
      ),
    );
  }
}

class _TelemetryChip extends StatelessWidget {
  final String label;
  final String value;

  const _TelemetryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _RetroActionButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final bool isActive;
  final VoidCallback? onPressed;

  const _RetroActionButton({
    required this.tooltip,
    required this.icon,
    required this.isActive,
    required this.onPressed,
  });

  @override
  State<_RetroActionButton> createState() => _RetroActionButtonState();
}

class _RetroActionButtonState extends State<_RetroActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final Color borderColor = _focused
        ? AppColors.goldAccent
        : widget.isActive
            ? AppColors.primaryAccent
            : AppTheme.borderColor;
    final Color bgColor = !enabled
        ? AppColors.surface
        : _pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.35)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
        onShowFocusHighlight: (bool v) => setState(() => _focused = v),
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: !enabled
                  ? AppColors.textSecondary.withValues(alpha: 0.4)
                  : widget.isActive
                      ? AppColors.goldAccent
                      : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RetroChoiceChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RetroChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_RetroChoiceChip> createState() => _RetroChoiceChipState();
}

class _RetroChoiceChipState extends State<_RetroChoiceChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.selected
        ? AppColors.primaryAccent
        : _pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.3)
            : _hovered
                ? AppColors.surface
                : AppColors.background;
    final Color border = _focused
        ? AppColors.goldAccent
        : widget.selected
            ? AppColors.goldAccent.withValues(alpha: 0.85)
            : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: _focused ? 1.5 : 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: widget.selected
                  ? Colors.white
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RetroToggleChip extends StatefulWidget {
  final String label;
  final bool active;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _RetroToggleChip({
    required this.label,
    required this.active,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_RetroToggleChip> createState() => _RetroToggleChipState();
}

class _RetroToggleChipState extends State<_RetroToggleChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = !widget.enabled
        ? AppColors.surface.withValues(alpha: 0.5)
        : widget.active
            ? AppColors.goldAccent.withValues(alpha: 0.16)
            : _pressed
                ? AppColors.surface
                : _hovered
                    ? AppColors.surface
                    : AppColors.background;
    final Color border = !widget.enabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _focused
            ? AppColors.goldAccent
            : widget.active
                ? AppColors.goldAccent
                : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? () => widget.onChanged(!widget.active) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                widget.active
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 14,
                color: !widget.enabled
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : widget.active
                        ? AppColors.goldAccent
                        : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: !widget.enabled
                      ? AppColors.textSecondary.withValues(alpha: 0.45)
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

class _RetroSliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String valueText;
  final ValueChanged<double> onChanged;

  const _RetroSliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.valueText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 122,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.goldAccent,
                inactiveTrackColor: AppTheme.borderColor,
                thumbColor: AppColors.goldAccent,
                overlayColor: AppColors.goldAccent.withValues(alpha: 0.18),
                trackHeight: 3.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              valueText,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
