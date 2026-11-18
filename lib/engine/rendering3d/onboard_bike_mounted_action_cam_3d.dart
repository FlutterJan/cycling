// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Pozycja montażu kamery akcji na rowerze wyścigowym.
enum ActionCamMountPosition {
  /// Kamera zamontowana pod mostkiem/kierownicą skierowana do przodu:
  /// ukazuje tylne koło i kasetę kolarza jadącego z przodu oraz walkę na łokcie.
  handlebarForward(
    label: 'Na kierownicy (Przód)',
    shortLabel: 'Kierownica',
    mountCode: 'CAM-01 // STEM',
  ),

  /// Kamera zamontowana pod szynami siodełka skierowana do tyłu:
  /// ukazuje własne tylne koło, kasetę oraz goniących rywali za plecami.
  underSaddleRear(
    label: 'Pod siodełkiem (Tył)',
    shortLabel: 'Pod siodłem',
    mountCode: 'CAM-02 // SADDLE',
  ),

  /// Widok podwójny (główna kamera na kierownicy + podgląd PiP spod siodełka).
  dualSplitCam(
    label: 'Dual Cam (Przód + Tył)',
    shortLabel: 'Dual Cam',
    mountCode: 'CAM-DUAL // 140°',
  );

  final String label;
  final String shortLabel;
  final String mountCode;

  const ActionCamMountPosition({
    required this.label,
    required this.shortLabel,
    required this.mountCode,
  });
}

/// Rodzaj nawierzchni wpływający na mikro-drgania obiektywu kamery akcji.
enum ActionCamRoadSurface {
  smoothTarmac(
    label: 'Gładki asfalt',
    roughnessMultiplier: 0.55,
    baseFrequencyHz: 26.0,
  ),
  coarseAsphalt(
    label: 'Szorstki asfalt',
    roughnessMultiplier: 1.0,
    baseFrequencyHz: 34.0,
  ),
  urbanCobbles(
    label: 'Bruk miejski',
    roughnessMultiplier: 2.15,
    baseFrequencyHz: 44.0,
  );

  final String label;
  final double roughnessMultiplier;
  final double baseFrequencyHz;

  const ActionCamRoadSurface({
    required this.label,
    required this.roughnessMultiplier,
    required this.baseFrequencyHz,
  });
}

/// Konfiguracja optyki i fizyki kamery akcji 140° FOV.
class ActionCam140Config {
  /// Kąt widzenia obiektywu rybiego oka [stopnie] (domyślnie 140°).
  final double fovDegrees;

  /// Siła dystorsji beczkowej obiektywu rybiego oka (0.0 - 1.0).
  final double fisheyeDistortionStrength;

  /// Czy włączona jest elektroniczna stabilizacja obrazu (tłumi mikro-drgania o 62%).
  final bool stabilizationEnabled;

  /// Czy wyświetlać nakładkę OSD kamery (REC, 4K 120FPS, telemetria sprintu).
  final bool showCameraOsd;

  /// Aktualna nawierzchnia trasy.
  final ActionCamRoadSurface roadSurface;

  /// Aktywne mocowanie kamery.
  final ActionCamMountPosition mountPosition;

  const ActionCam140Config({
    this.fovDegrees = 140.0,
    this.fisheyeDistortionStrength = 0.78,
    this.stabilizationEnabled = true,
    this.showCameraOsd = true,
    this.roadSurface = ActionCamRoadSurface.coarseAsphalt,
    this.mountPosition = ActionCamMountPosition.handlebarForward,
  });

  ActionCam140Config copyWith({
    double? fovDegrees,
    double? fisheyeDistortionStrength,
    bool? stabilizationEnabled,
    bool? showCameraOsd,
    ActionCamRoadSurface? roadSurface,
    ActionCamMountPosition? mountPosition,
  }) {
    return ActionCam140Config(
      fovDegrees: (fovDegrees ?? this.fovDegrees).clamp(115.0, 155.0),
      fisheyeDistortionStrength:
          (fisheyeDistortionStrength ?? this.fisheyeDistortionStrength)
              .clamp(0.0, 1.0),
      stabilizationEnabled: stabilizationEnabled ?? this.stabilizationEnabled,
      showCameraOsd: showCameraOsd ?? this.showCameraOsd,
      roadSurface: roadSurface ?? this.roadSurface,
      mountPosition: mountPosition ?? this.mountPosition,
    );
  }
}

/// Wynik rzutowania punktu 3D przez obiektyw rybiego oka 140° na ekran 2D.
class FisheyeProjectedPoint {
  final Offset screenOffset;
  final double scale;
  final double radialNormalized;
  final bool isVisible;

  const FisheyeProjectedPoint({
    required this.screenOffset,
    required this.scale,
    required this.radialNormalized,
    required this.isVisible,
  });

  static const FisheyeProjectedPoint hidden = FisheyeProjectedPoint(
    screenOffset: Offset.zero,
    scale: 0.0,
    radialNormalized: 2.0,
    isVisible: false,
  );
}

/// Matematyka obiektywu rybiego oka (Equidistant Fisheye 140° FOV).
class FisheyeLens140Projection {
  const FisheyeLens140Projection._();

  /// Rzutuje punkt w układzie kamery `(x: prawo, y: góra, z: przód > 0)` na płótno [viewport].
  static FisheyeProjectedPoint project({
    required double x,
    required double y,
    required double z,
    required Size viewport,
    double fovDegrees = 140.0,
    double distortionStrength = 0.78,
    Offset vibrationOffsetPx = Offset.zero,
    double rollRadians = 0.0,
  }) {
    if (z <= 0.04 || viewport.width <= 0 || viewport.height <= 0) {
      return FisheyeProjectedPoint.hidden;
    }

    // Obrót kamery wokół osi Z (pochylenie roweru / wstrząs).
    final double cosR = math.cos(rollRadians);
    final double sinR = math.sin(rollRadians);
    final double rx = x * cosR - y * sinR;
    final double ry = x * sinR + y * cosR;

    final double planarDist = math.sqrt(rx * rx + ry * ry);
    final double theta = math.atan2(planarDist, z); // Kąt od osi optycznej [rad].
    final double halfFovRad = (fovDegrees * 0.5) * math.pi / 180.0;

    if (theta > halfFovRad * 1.18) {
      return FisheyeProjectedPoint.hidden;
    }

    // Hybryda rzutowania prostoliniowego i równoodległościowego fisheye: r = f * theta.
    final double linearR = planarDist / z;
    final double fisheyeR = theta / math.tan(halfFovRad * 0.5).clamp(0.45, 3.0);
    final double maxFisheyeNorm = halfFovRad;
    final double normalizedTheta = theta / maxFisheyeNorm;

    // Krzywa beczkowa Brown-Conrady dla realizmu obiektywu 140°.
    final double barrelFactor =
        1.0 - 0.14 * distortionStrength * normalizedTheta * normalizedTheta;
    final double blendedR = ui.lerpDouble(
          linearR,
          normalizedTheta * barrelFactor,
          distortionStrength,
        ) ??
        fisheyeR;

    final double dirX = planarDist > 1e-6 ? rx / planarDist : 0.0;
    final double dirY = planarDist > 1e-6 ? ry / planarDist : 0.0;

    final double halfW = viewport.width * 0.5;
    final double halfH = viewport.height * 0.5;
    final double focalRadius = math.max(halfW, halfH) * 0.96;

    final double px = halfW + dirX * blendedR * focalRadius + vibrationOffsetPx.dx;
    final double py = halfH - dirY * blendedR * focalRadius + vibrationOffsetPx.dy;

    final double perspectiveScale = (1.0 / z).clamp(0.05, 8.0) *
        (1.0 - 0.22 * distortionStrength * normalizedTheta).clamp(0.35, 1.15);

    return FisheyeProjectedPoint(
      screenOffset: Offset(px, py),
      scale: perspectiveScale,
      radialNormalized: normalizedTheta.clamp(0.0, 1.5),
      isVisible: true,
    );
  }
}

/// Próbka mikro-drgań asfaltu działających na mocowanie kamery w danej milisekundzie.
class AsphaltMicroVibrationSample {
  final Offset offsetPx;
  final double rollJitterRadians;
  final double gForceRms;
  final double dominantFrequencyHz;

  const AsphaltMicroVibrationSample({
    required this.offsetPx,
    required this.rollJitterRadians,
    required this.gForceRms,
    required this.dominantFrequencyHz,
  });
}

/// Generator proceduralnych mikro-drgań asfaltu zależnych od prędkości, nawierzchni i kadencji.
class AsphaltMicroVibrationModel {
  const AsphaltMicroVibrationModel._();

  static AsphaltMicroVibrationSample compute({
    required double timeSeconds,
    required double speedKmh,
    required ActionCamRoadSurface surface,
    required bool stabilizationEnabled,
    required double cadenceRpm,
    required double elbowBumpImpulse,
  }) {
    final double speedFactor = (speedKmh / 55.0).clamp(0.25, 1.55);
    final double damper = stabilizationEnabled ? 0.38 : 1.0;
    final double rough = surface.roughnessMultiplier;
    final double freq = surface.baseFrequencyHz * (0.85 + 0.35 * speedFactor);

    // 3 harmoniczne chropowatości asfaltu + okresowe łączenia nawierzchni.
    final double highFreqX = math.sin(timeSeconds * freq * 2.0 * math.pi) * 0.55 +
        math.sin(timeSeconds * (freq * 1.63) * 2.0 * math.pi + 1.1) * 0.35;
    final double highFreqY = math.cos(timeSeconds * (freq * 1.17) * 2.0 * math.pi) * 0.65 +
        math.sin(timeSeconds * (freq * 2.11) * 2.0 * math.pi + 0.4) * 0.35;

    // Impulsy szczelin asfaltu co ~1.4 m przejechanej drogi.
    final double speedMs = speedKmh / 3.6;
    final double seamPhase = (timeSeconds * speedMs / 1.4) % 1.0;
    final double seamPulse = seamPhase < 0.08 ? math.sin(seamPhase / 0.08 * math.pi) : 0.0;

    // Delikatne bujanie od kadencji podczas sprintu.
    final double cadenceRad = timeSeconds * (cadenceRpm / 60.0) * 2.0 * math.pi;
    final double pedalRockX = math.sin(cadenceRad) * 1.9 * damper;
    final double pedalRoll = math.sin(cadenceRad) * 0.022 * damper;

    final double ampX = (1.65 * rough * speedFactor + elbowBumpImpulse * 6.5) * damper;
    final double ampY = (2.15 * rough * speedFactor + seamPulse * 4.2 * rough) * damper;

    final Offset offset = Offset(
      highFreqX * ampX + pedalRockX,
      highFreqY * ampY,
    );

    final double rollJitter =
        pedalRoll + highFreqX * 0.008 * rough * damper + elbowBumpImpulse * 0.045;
    final double gForceRms =
        (0.42 * rough * speedFactor + seamPulse * 0.65 + elbowBumpImpulse * 1.4) *
            (stabilizationEnabled ? 0.52 : 1.0);

    return AsphaltMicroVibrationSample(
      offsetPx: offset,
      rollJitterRadians: rollJitter,
      gForceRms: gForceRms.clamp(0.1, 4.5),
      dominantFrequencyHz: freq,
    );
  }
}

/// Rywal walczący łokieć w łokieć o pozycję na ostatnich 1500 m przed sprintem.
class SprintElbowRival3D {
  final String riderCode;
  final String teamName;
  final Color jerseyPrimary;
  final Color jerseyAccent;
  final Color helmetColor;

  /// Odstęp wzdłużny od kamery [m] (dodatni = przed nami, ujemny = za nami).
  final double longitudinalOffsetMeters;

  /// Odstęp poprzeczny od osi naszego roweru [m] (- = lewa strona, + = prawa strona).
  final double lateralOffsetMeters;

  /// Siła wciskania się łokciem w naszą linię (0.0 - 1.0).
  final double elbowPressure;

  /// Aktualna kadencja rywala [RPM].
  final double cadenceRpm;

  const SprintElbowRival3D({
    required this.riderCode,
    required this.teamName,
    required this.jerseyPrimary,
    required this.jerseyAccent,
    required this.helmetColor,
    required this.longitudinalOffsetMeters,
    required this.lateralOffsetMeters,
    required this.elbowPressure,
    required this.cadenceRpm,
  });
}

/// Pełny stan klatki dla widoku kamery akcji na ostatnich 1500 m przed sprintem.
class OnBoardActionCamFrameState {
  final double distanceToFinishMeters;
  final double speedKmh;
  final double powerWatts;
  final double cadenceRpm;
  final int gearRearTeeth;
  final int gearFrontTeeth;
  final double leadWheelGapMeters;
  final double elapsedTimeSeconds;
  final double elbowCollisionRisk;
  final List<SprintElbowRival3D> nearbyRivals;
  final AsphaltMicroVibrationSample vibration;

  const OnBoardActionCamFrameState({
    required this.distanceToFinishMeters,
    required this.speedKmh,
    required this.powerWatts,
    required this.cadenceRpm,
    required this.gearRearTeeth,
    required this.gearFrontTeeth,
    required this.leadWheelGapMeters,
    required this.elapsedTimeSeconds,
    required this.elbowCollisionRisk,
    required this.nearbyRivals,
    required this.vibration,
  });
}

/// Generator deterministycznej sceny ostatnich 1500 m walki sprinterskiej.
class Final1500mSprintBattleGenerator {
  const Final1500mSprintBattleGenerator._();

  static OnBoardActionCamFrameState buildFrame({
    required double elapsedSeconds,
    required double distanceToFinishMeters,
    required double speedKmh,
    required ActionCam140Config config,
  }) {
    final double clampedDist = distanceToFinishMeters.clamp(0.0, 1500.0);
    final double intensity = (1.0 - clampedDist / 1500.0).clamp(0.15, 1.0);
    final double cadence = 98.0 + 18.0 * intensity + math.sin(elapsedSeconds * 1.4) * 3.5;

    // Pociąg sprinterski przed nami (luka 0.28 - 0.52 m do tylnego koła rywala z przodu).
    final double leadGap = 0.34 + math.sin(elapsedSeconds * 2.1) * 0.09;

    // Rywale wciskający się łokciami z lewej i prawej strony na ostatnich 1500 m.
    final double leftSqueeze = 0.56 - 0.14 * intensity - math.sin(elapsedSeconds * 1.85) * 0.08;
    final double rightSqueeze = 0.58 - 0.16 * intensity - math.cos(elapsedSeconds * 1.55) * 0.09;

    final double leftPressure = ((0.64 - leftSqueeze) / 0.28).clamp(0.0, 1.0);
    final double rightPressure = ((0.64 - rightSqueeze) / 0.28).clamp(0.0, 1.0);
    final double bumpImpulse = math.max(leftPressure, rightPressure) * 0.65;

    final List<SprintElbowRival3D> rivals = <SprintElbowRival3D>[
      SprintElbowRival3D(
        riderCode: 'PHI',
        teamName: 'Alpecin Leadout',
        jerseyPrimary: const Color(0xFF1D4ED8),
        jerseyAccent: AppColors.goldAccent,
        helmetColor: AppColors.textPrimary,
        longitudinalOffsetMeters: 1.58 + leadGap,
        lateralOffsetMeters: math.sin(elapsedSeconds * 1.3) * 0.07,
        elbowPressure: 0.25,
        cadenceRpm: cadence + 2.0,
      ),
      SprintElbowRival3D(
        riderCode: 'MIL',
        teamName: 'Lidl-Sprint',
        jerseyPrimary: AppColors.crimsonAlert,
        jerseyAccent: AppColors.goldAccent,
        helmetColor: AppColors.goldAccent,
        longitudinalOffsetMeters: 0.52 + math.sin(elapsedSeconds * 1.1) * 0.18,
        lateralOffsetMeters: -leftSqueeze,
        elbowPressure: leftPressure,
        cadenceRpm: cadence + 4.0,
      ),
      SprintElbowRival3D(
        riderCode: 'MER',
        teamName: 'QuickStep Wolf',
        jerseyPrimary: AppColors.accentBlue,
        jerseyAccent: AppColors.textPrimary,
        helmetColor: AppColors.accentBlue,
        longitudinalOffsetMeters: 0.44 + math.cos(elapsedSeconds * 1.25) * 0.20,
        lateralOffsetMeters: rightSqueeze,
        elbowPressure: rightPressure,
        cadenceRpm: cadence + 3.0,
      ),
      SprintElbowRival3D(
        riderCode: 'GRO',
        teamName: 'Jayco Aero',
        jerseyPrimary: AppColors.statusSuccess,
        jerseyAccent: AppColors.textPrimary,
        helmetColor: AppColors.textPrimary,
        longitudinalOffsetMeters: -1.45 + math.sin(elapsedSeconds * 0.9) * 0.16,
        lateralOffsetMeters: -0.32 + math.cos(elapsedSeconds * 1.4) * 0.10,
        elbowPressure: 0.55 * intensity,
        cadenceRpm: cadence - 1.5,
      ),
      SprintElbowRival3D(
        riderCode: 'KOO',
        teamName: 'Visma Sprint',
        jerseyPrimary: AppColors.amberWarning,
        jerseyAccent: AppColors.background,
        helmetColor: AppColors.amberWarning,
        longitudinalOffsetMeters: -1.62 + math.cos(elapsedSeconds * 1.05) * 0.14,
        lateralOffsetMeters: 0.36 + math.sin(elapsedSeconds * 1.2) * 0.11,
        elbowPressure: 0.48 * intensity,
        cadenceRpm: cadence + 1.0,
      ),
    ];

    final AsphaltMicroVibrationSample vibration = AsphaltMicroVibrationModel.compute(
      timeSeconds: elapsedSeconds,
      speedKmh: speedKmh,
      surface: config.roadSurface,
      stabilizationEnabled: config.stabilizationEnabled,
      cadenceRpm: cadence,
      elbowBumpImpulse: bumpImpulse,
    );

    final double power = 740.0 + 580.0 * intensity + math.sin(elapsedSeconds * 3.1) * 45.0;
    final int rearTeeth = speedKmh > 66.0 ? 11 : (speedKmh > 58.0 ? 12 : 13);

    return OnBoardActionCamFrameState(
      distanceToFinishMeters: clampedDist,
      speedKmh: speedKmh,
      powerWatts: power,
      cadenceRpm: cadence,
      gearRearTeeth: rearTeeth,
      gearFrontTeeth: 54,
      leadWheelGapMeters: leadGap,
      elapsedTimeSeconds: elapsedSeconds,
      elbowCollisionRisk: math.max(leftPressure, rightPressure),
      nearbyRivals: rivals,
      vibration: vibration,
    );
  }
}

/// Painter 3D renderujący widok z kamery akcji 140° FOV (kierownica lub pod siodełkiem).
class OnBoardActionCam3dPainter extends CustomPainter {
  final ActionCam140Config config;
  final OnBoardActionCamFrameState frame;
  final ActionCamMountPosition renderMount;
  final bool isPictureInPicture;

  const OnBoardActionCam3dPainter({
    required this.config,
    required this.frame,
    required this.renderMount,
    this.isPictureInPicture = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 4 || size.height <= 4) return;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final bool isRearMount = renderMount == ActionCamMountPosition.underSaddleRear;
    final double dirSign = isRearMount ? -1.0 : 1.0;

    // 1. Niebo i horyzont z zakrzywieniem obiektywu rybiego oka 140°.
    _paintFisheyeSkyAndHorizon(canvas, size, isRearMount);

    // 2. Wstęga asfaltu, krawężniki, barierki sprinterskie i pasy drogi.
    _paintFisheyeRoadAndSprintBarriers(canvas, size, isRearMount);

    // 3. Brama Flamme Rouge (1000 m) lub banery końcowych metrów.
    _paintDistanceArchIfVisible(canvas, size, isRearMount);

    // 4. Kolarz bezpośrednio przed nami (tylne koło + kaseta) lub goniący rywale za nami.
    _paintRivalsAndLeadWheel(canvas, size, dirSign, isRearMount);

    // 5. Własne elementy roweru na krawędzi kadru (mostek/kierownica albo sztyca/tylne koło).
    if (!isRearMount) {
      _paintOwnHandlebarEdge(canvas, size);
    } else {
      _paintOwnUnderSaddleWheelAndCassette(canvas, size);
    }

    // 6. Linie pędu prędkości i winieta obiektywu rybiego oka 140°.
    _paintSpeedBlurAndFisheyeVignette(canvas, size);

    canvas.restore();
  }

  FisheyeProjectedPoint _projectPoint({
    required double x,
    required double y,
    required double z,
    required Size size,
  }) {
    return FisheyeLens140Projection.project(
      x: x,
      y: y,
      z: z,
      viewport: size,
      fovDegrees: config.fovDegrees,
      distortionStrength: config.fisheyeDistortionStrength,
      vibrationOffsetPx: isPictureInPicture
          ? frame.vibration.offsetPx * 0.45
          : frame.vibration.offsetPx,
      rollRadians: frame.vibration.rollJitterRadians,
    );
  }

  void _paintFisheyeSkyAndHorizon(Canvas canvas, Size size, bool isRearMount) {
    final Rect fullRect = Offset.zero & size;
    final Paint skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size.height * 0.56),
        <Color>[
          const Color(0xFF0A1424),
          const Color(0xFF1B2C47),
          const Color(0xFF334766),
        ],
        <double>[0.0, 0.58, 1.0],
      );
    canvas.drawRect(fullRect, skyPaint);

    // Słońce / rozbłysk optyczny w obiektywie szerokokątnym.
    final Offset sunCenter = Offset(
      size.width * (isRearMount ? 0.76 : 0.22),
      size.height * 0.16,
    );
    final Paint flarePaint = Paint()
      ..shader = ui.Gradient.radial(
        sunCenter,
        size.width * 0.22,
        <Color>[
          AppColors.goldAccent.withValues(alpha: 0.36),
          AppColors.amberWarning.withValues(alpha: 0.10),
          Colors.transparent,
        ],
        <double>[0.0, 0.45, 1.0],
      );
    canvas.drawCircle(sunCenter, size.width * 0.22, flarePaint);
  }

  void _paintFisheyeRoadAndSprintBarriers(
    Canvas canvas,
    Size size,
    bool isRearMount,
  ) {
    final double camHeight = isRearMount ? 0.86 : 0.94;
    final double speedMs = frame.speedKmh / 3.6;
    final double travelOffset = frame.elapsedTimeSeconds * speedMs;

    // Budujemy segmenty wstęgi asfaltu od 0.6 m do 48 m.
    final List<double> zSteps = <double>[
      0.65,
      1.1,
      1.7,
      2.5,
      3.8,
      5.5,
      8.0,
      12.0,
      18.0,
      28.0,
      44.0,
    ];

    final Path roadPath = Path();
    final List<Offset> leftEdgePts = <Offset>[];
    final List<Offset> rightEdgePts = <Offset>[];

    for (final double z in zSteps) {
      final FisheyeProjectedPoint lp = _projectPoint(
        x: -3.6,
        y: -camHeight,
        z: z,
        size: size,
      );
      final FisheyeProjectedPoint rp = _projectPoint(
        x: 3.6,
        y: -camHeight,
        z: z,
        size: size,
      );
      if (lp.isVisible && rp.isVisible) {
        leftEdgePts.add(lp.screenOffset);
        rightEdgePts.add(rp.screenOffset);
      }
    }

    if (leftEdgePts.length >= 2 && rightEdgePts.length >= 2) {
      roadPath.moveTo(leftEdgePts.first.dx, leftEdgePts.first.dy);
      for (int i = 1; i < leftEdgePts.length; i++) {
        roadPath.lineTo(leftEdgePts[i].dx, leftEdgePts[i].dy);
      }
      for (int i = rightEdgePts.length - 1; i >= 0; i--) {
        roadPath.lineTo(rightEdgePts[i].dx, rightEdgePts[i].dy);
      }
      roadPath.close();

      final Color roadTop = config.roadSurface == ActionCamRoadSurface.urbanCobbles
          ? const Color(0xFF282C36)
          : const Color(0xFF1D212A);
      final Color roadBottom = config.roadSurface == ActionCamRoadSurface.urbanCobbles
          ? const Color(0xFF171A21)
          : const Color(0xFF11141B);

      canvas.drawPath(
        roadPath,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, size.height * 0.42),
            Offset(0, size.height),
            <Color>[roadTop, roadBottom],
          ),
      );

      // Przerywane białe pasy osi jezdni z efektem pędu.
      final Paint dashPaint = Paint()
        ..color = AppColors.textPrimary.withValues(alpha: 0.42)
        ..strokeCap = StrokeCap.round;

      const double dashPeriod = 4.5;
      final double phase = travelOffset % dashPeriod;
      for (double z = 0.9 + (dashPeriod - phase); z < 36.0; z += dashPeriod) {
        final double zEnd = z + 1.65;
        final FisheyeProjectedPoint p1 =
            _projectPoint(x: 0.0, y: -camHeight + 0.01, z: z, size: size);
        final FisheyeProjectedPoint p2 =
            _projectPoint(x: 0.0, y: -camHeight + 0.01, z: zEnd, size: size);
        if (p1.isVisible && p2.isVisible) {
          dashPaint.strokeWidth = (p1.scale * 4.5).clamp(1.2, 10.0);
          canvas.drawLine(p1.screenOffset, p2.screenOffset, dashPaint);
        }
      }

      // Efekt faktury bruku lub chropowatego asfaltu przy wysokim zbliżeniu.
      if (config.roadSurface != ActionCamRoadSurface.smoothTarmac) {
        final Paint grainPaint = Paint()
          ..color = AppColors.textSecondary.withValues(
            alpha: config.roadSurface == ActionCamRoadSurface.urbanCobbles
                ? 0.22
                : 0.09,
          )
          ..strokeWidth = 1.4;
        final double grainStep =
            config.roadSurface == ActionCamRoadSurface.urbanCobbles ? 0.55 : 0.95;
        final double gPhase = travelOffset % grainStep;
        for (double z = 0.75 + (grainStep - gPhase); z < 11.0; z += grainStep) {
          final FisheyeProjectedPoint gl =
              _projectPoint(x: -2.4, y: -camHeight + 0.01, z: z, size: size);
          final FisheyeProjectedPoint gr =
              _projectPoint(x: 2.4, y: -camHeight + 0.01, z: z, size: size);
          if (gl.isVisible && gr.isVisible) {
            canvas.drawLine(gl.screenOffset, gr.screenOffset, grainPaint);
          }
        }
      }
    }

    // Barierki sprinterskie po obu stronach szosy na ostatnich 1500 m.
    final Paint barrierPaint = Paint()
      ..color = AppColors.primaryAccent.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isPictureInPicture ? 1.5 : 2.5;
    final Paint postPaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.65)
      ..strokeWidth = isPictureInPicture ? 1.2 : 2.0;

    for (final double sideX in const <double>[-3.75, 3.75]) {
      final Path railPath = Path();
      bool started = false;
      for (final double z in zSteps) {
        final FisheyeProjectedPoint topP = _projectPoint(
          x: sideX,
          y: -camHeight + 0.95,
          z: z,
          size: size,
        );
        if (topP.isVisible) {
          if (!started) {
            railPath.moveTo(topP.screenOffset.dx, topP.screenOffset.dy);
            started = true;
          } else {
            railPath.lineTo(topP.screenOffset.dx, topP.screenOffset.dy);
          }
        }
      }
      if (started) {
        canvas.drawPath(railPath, barrierPaint);
      }

      final double postPhase = travelOffset % 3.0;
      for (double z = 1.1 + (3.0 - postPhase); z < 32.0; z += 3.0) {
        final FisheyeProjectedPoint b =
            _projectPoint(x: sideX, y: -camHeight, z: z, size: size);
        final FisheyeProjectedPoint t =
            _projectPoint(x: sideX, y: -camHeight + 0.95, z: z, size: size);
        if (b.isVisible && t.isVisible) {
          canvas.drawLine(b.screenOffset, t.screenOffset, postPaint);
        }
      }
    }
  }

  void _paintDistanceArchIfVisible(
    Canvas canvas,
    Size size,
    bool isRearMount,
  ) {
    if (isRearMount) return;
    // Brama Flamme Rouge przy 1000 m lub Meta przy < 50 m.
    double archZ = -1.0;
    String archText = '';
    Color archColor = AppColors.crimsonAlert;

    if (frame.distanceToFinishMeters >= 980.0 &&
        frame.distanceToFinishMeters <= 1040.0) {
      archZ = (frame.distanceToFinishMeters - 980.0) * 0.65 + 4.0;
      archText = '1 KM // FLAMME ROUGE';
      archColor = AppColors.crimsonAlert;
    } else if (frame.distanceToFinishMeters <= 60.0) {
      archZ = frame.distanceToFinishMeters.clamp(2.5, 45.0);
      archText = 'FINISH // SPRINT';
      archColor = AppColors.goldAccent;
    }

    if (archZ <= 0) return;

    final FisheyeProjectedPoint leftBase =
        _projectPoint(x: -3.7, y: -0.94, z: archZ, size: size);
    final FisheyeProjectedPoint leftTop =
        _projectPoint(x: -3.7, y: 2.8, z: archZ, size: size);
    final FisheyeProjectedPoint rightTop =
        _projectPoint(x: 3.7, y: 2.8, z: archZ, size: size);
    final FisheyeProjectedPoint rightBase =
        _projectPoint(x: 3.7, y: -0.94, z: archZ, size: size);

    if (!leftBase.isVisible ||
        !leftTop.isVisible ||
        !rightTop.isVisible ||
        !rightBase.isVisible) {
      return;
    }

    final Paint archPaint = Paint()
      ..color = archColor.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (leftTop.scale * 14.0).clamp(3.0, 18.0);

    final Path archPath = Path()
      ..moveTo(leftBase.screenOffset.dx, leftBase.screenOffset.dy)
      ..lineTo(leftTop.screenOffset.dx, leftTop.screenOffset.dy)
      ..lineTo(rightTop.screenOffset.dx, rightTop.screenOffset.dy)
      ..lineTo(rightBase.screenOffset.dx, rightBase.screenOffset.dy);
    canvas.drawPath(archPath, archPaint);

    if (!isPictureInPicture) {
      final Offset midTop = Offset(
        (leftTop.screenOffset.dx + rightTop.screenOffset.dx) * 0.5,
        (leftTop.screenOffset.dy + rightTop.screenOffset.dy) * 0.5,
      );
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: archText,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: (leftTop.scale * 22.0).clamp(8.0, 15.0),
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, midTop - Offset(tp.width * 0.5, tp.height * 0.5));
    }
  }

  void _paintRivalsAndLeadWheel(
    Canvas canvas,
    Size size,
    double dirSign,
    bool isRearMount,
  ) {
    // Filtruj i sortuj rywali od najdalszego do najbliższego (painter's algorithm).
    final List<SprintElbowRival3D> visibleRivals = frame.nearbyRivals
        .where((SprintElbowRival3D r) =>
            (r.longitudinalOffsetMeters * dirSign) > 0.20)
        .toList()
      ..sort((SprintElbowRival3D a, SprintElbowRival3D b) =>
          (b.longitudinalOffsetMeters * dirSign)
              .compareTo(a.longitudinalOffsetMeters * dirSign));

    for (final SprintElbowRival3D rival in visibleRivals) {
      final double z = (rival.longitudinalOffsetMeters * dirSign).abs();
      final double x = rival.lateralOffsetMeters * dirSign;

      if (!isRearMount && rival.longitudinalOffsetMeters > 1.2) {
        // Kolarz bezpośrednio przed nami: szczegółowy widok tylnego koła, kasety i przerzutki!
        _paintLeadRiderRearWheelAndCassette(
          canvas: canvas,
          size: size,
          rival: rival,
          zWheel: z - 0.55,
          xOffset: x,
        );
      } else {
        // Rywale wciskający się łokciami z boku lub goniący za tylną kamerą.
        _paintElbowSqueezingRival(
          canvas: canvas,
          size: size,
          rival: rival,
          z: z,
          x: x,
          isRearMount: isRearMount,
        );
      }
    }
  }

  /// Rysuje szczegółowe tylne koło, 12-rzędową kasetę, łańcuch i nogi kolarza jadącego tuż przed nami.
  void _paintLeadRiderRearWheelAndCassette({
    required Canvas canvas,
    required Size size,
    required SprintElbowRival3D rival,
    required double zWheel,
    required double xOffset,
  }) {
    const double camHeight = 0.94;
    const double wheelRadius = 0.34;
    final double zCenter = zWheel.clamp(0.42, 4.5);

    final FisheyeProjectedPoint hubCenter = _projectPoint(
      x: xOffset,
      y: -camHeight + wheelRadius,
      z: zCenter,
      size: size,
    );
    final FisheyeProjectedPoint tireBottom = _projectPoint(
      x: xOffset,
      y: -camHeight,
      z: zCenter,
      size: size,
    );
    final FisheyeProjectedPoint saddleCenter = _projectPoint(
      x: xOffset,
      y: -camHeight + 1.02,
      z: zCenter + 0.25,
      size: size,
    );

    if (!hubCenter.isVisible || !tireBottom.isVisible) return;

    final double wheelPxHeight =
        (tireBottom.screenOffset.dy - hubCenter.screenOffset.dy).abs() * 2.0;
    final double tireWidth = (wheelPxHeight * 0.085).clamp(4.0, 26.0);
    final double rimWidth = tireWidth * 0.72;

    // Cień pod tylnym kołem.
    canvas.drawOval(
      Rect.fromCenter(
        center: tireBottom.screenOffset + const Offset(0, 3),
        width: tireWidth * 2.6,
        height: tireWidth * 0.7,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    // Sylwetka kolarza z przodu (siodełko, spodenki, koszulka, łokcie na baranku).
    if (saddleCenter.isVisible) {
      final double bodyWidth = (wheelPxHeight * 0.46).clamp(18.0, 140.0);
      final Rect torsoRect = Rect.fromCenter(
        center: saddleCenter.screenOffset - Offset(0, wheelPxHeight * 0.36),
        width: bodyWidth,
        height: wheelPxHeight * 0.72,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(torsoRect, Radius.circular(bodyWidth * 0.32)),
        Paint()
          ..shader = ui.Gradient.linear(
            torsoRect.topCenter,
            torsoRect.bottomCenter,
            <Color>[rival.jerseyPrimary, const Color(0xFF101319)],
          ),
      );
      // Pasek drużynowy na koszulce.
      canvas.drawRect(
        Rect.fromLTWH(
          torsoRect.left + bodyWidth * 0.1,
          torsoRect.top + torsoRect.height * 0.24,
          bodyWidth * 0.8,
          torsoRect.height * 0.12,
        ),
        Paint()..color = rival.jerseyAccent,
      );

      // Kask lidera pociągu.
      canvas.drawOval(
        Rect.fromCenter(
          center: torsoRect.topCenter - Offset(0, bodyWidth * 0.18),
          width: bodyWidth * 0.38,
          height: bodyWidth * 0.34,
        ),
        Paint()..color = rival.helmetColor,
      );
    }

    // Animacja obrotu nóg w korbie.
    final double crankAngle =
        frame.elapsedTimeSeconds * (rival.cadenceRpm / 60.0) * 2.0 * math.pi;
    final double leftFootY = math.sin(crankAngle) * wheelPxHeight * 0.14;
    final double rightFootY = -leftFootY;

    final Paint legPaint = Paint()
      ..color = const Color(0xFFD6A888)
      ..strokeWidth = (tireWidth * 0.88).clamp(4.0, 18.0)
      ..strokeCap = StrokeCap.round;

    final Offset hipLeft = hubCenter.screenOffset +
        Offset(-tireWidth * 1.45, -wheelPxHeight * 0.56);
    final Offset hipRight = hubCenter.screenOffset +
        Offset(tireWidth * 1.45, -wheelPxHeight * 0.56);

    canvas.drawLine(
      hipLeft,
      hubCenter.screenOffset + Offset(-tireWidth * 1.55, leftFootY),
      legPaint,
    );
    canvas.drawLine(
      hipRight,
      hubCenter.screenOffset + Offset(tireWidth * 1.55, rightFootY),
      legPaint,
    );

    // Tylne widełki ramy (seatstays).
    final Paint framePaint = Paint()
      ..color = const Color(0xFF232834)
      ..strokeWidth = (tireWidth * 0.32).clamp(2.0, 7.0)
      ..strokeCap = StrokeCap.round;
    if (saddleCenter.isVisible) {
      canvas.drawLine(
        saddleCenter.screenOffset,
        hubCenter.screenOffset + Offset(-tireWidth * 0.7, 0),
        framePaint,
      );
      canvas.drawLine(
        saddleCenter.screenOffset,
        hubCenter.screenOffset + Offset(tireWidth * 0.7, 0),
        framePaint,
      );
    }

    // Opona i wysoki karbonowy stożek tylnego koła.
    final Rect wheelRect = Rect.fromCenter(
      center: hubCenter.screenOffset,
      width: tireWidth,
      height: wheelPxHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(wheelRect, Radius.circular(tireWidth * 0.5)),
      Paint()..color = const Color(0xFF14161D),
    );
    final Rect rimRect = wheelRect.deflate(tireWidth * 0.14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rimRect, Radius.circular(rimWidth * 0.5)),
      Paint()..color = const Color(0xFF2B313F),
    );

    // Szprychy i błysk rotacji koła.
    final double spokePhase = (frame.elapsedTimeSeconds * 24.0) % 1.0;
    final Paint spokePaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.48)
      ..strokeWidth = 1.2;
    for (int i = 0; i < 6; i++) {
      final double normY = ((i / 6.0 + spokePhase) % 1.0) * 2.0 - 1.0;
      final double sy = hubCenter.screenOffset.dy + normY * wheelPxHeight * 0.42;
      canvas.drawLine(
        Offset(hubCenter.screenOffset.dx - rimWidth * 0.32, sy),
        Offset(hubCenter.screenOffset.dx + rimWidth * 0.32, sy),
        spokePaint,
      );
    }

    // 12-rzędowa kaseta po prawej stronie tylnej piasty + wózek przerzutki i łańcuch!
    final double cassetteX = hubCenter.screenOffset.dx + tireWidth * 0.72;
    final double cassetteY = hubCenter.screenOffset.dy;
    final double cassetteHeight = (wheelPxHeight * 0.19).clamp(6.0, 42.0);
    final double cassetteWidth = (tireWidth * 0.56).clamp(3.0, 15.0);

    for (int cog = 0; cog < 6; cog++) {
      final double frac = cog / 5.0;
      final double cogH = cassetteHeight * (1.0 - frac * 0.55);
      final double cogX = cassetteX + frac * cassetteWidth * 0.55;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cogX, cassetteY),
            width: (cassetteWidth * 0.14).clamp(1.2, 3.2),
            height: cogH,
          ),
          const Radius.circular(1.0),
        ),
        Paint()
          ..color = cog.isEven
              ? const Color(0xFFD1D5DB)
              : const Color(0xFF9CA3AF),
      );
    }

    // Wózek tylnej przerzutki i napinany łańcuch.
    final Offset derailleurBottom =
        Offset(cassetteX + cassetteWidth * 0.25, cassetteY + cassetteHeight * 0.78);
    canvas.drawLine(
      Offset(cassetteX + cassetteWidth * 0.15, cassetteY + cassetteHeight * 0.2),
      derailleurBottom,
      Paint()
        ..color = const Color(0xFF111318)
        ..strokeWidth = (tireWidth * 0.22).clamp(1.8, 5.0)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      derailleurBottom,
      (tireWidth * 0.18).clamp(1.5, 4.5),
      Paint()..color = AppColors.goldAccent.withValues(alpha: 0.85),
    );
  }

  /// Rysuje rywali wciskających się łokciami z boku (lub goniących w kamerze pod siodełkiem).
  void _paintElbowSqueezingRival({
    required Canvas canvas,
    required Size size,
    required SprintElbowRival3D rival,
    required double z,
    required double x,
    required bool isRearMount,
  }) {
    final double camHeight = isRearMount ? 0.86 : 0.94;
    final FisheyeProjectedPoint center = _projectPoint(
      x: x,
      y: -camHeight + 0.88,
      z: z,
      size: size,
    );
    final FisheyeProjectedPoint ground = _projectPoint(
      x: x,
      y: -camHeight,
      z: z,
      size: size,
    );

    if (!center.isVisible || !ground.isVisible) return;

    final double heightPx =
        (ground.screenOffset.dy - center.screenOffset.dy).abs() * 1.45;
    final double bodyWidth = (heightPx * 0.42).clamp(16.0, 150.0);

    // Tułów i barki.
    final Rect jerseyRect = Rect.fromCenter(
      center: center.screenOffset,
      width: bodyWidth,
      height: heightPx * 0.65,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(jerseyRect, Radius.circular(bodyWidth * 0.28)),
      Paint()
        ..shader = ui.Gradient.linear(
          jerseyRect.topCenter,
          jerseyRect.bottomCenter,
          <Color>[rival.jerseyPrimary, const Color(0xFF141820)],
        ),
    );

    // Wystający łokieć i przedramię w walce o pozycję!
    final double sideToCam = x > 0 ? -1.0 : 1.0;
    final double elbowOut = bodyWidth * (0.58 + rival.elbowPressure * 0.26);
    final Offset shoulder = Offset(
      jerseyRect.center.dx + sideToCam * bodyWidth * 0.42,
      jerseyRect.top + jerseyRect.height * 0.22,
    );
    final Offset elbow = Offset(
      jerseyRect.center.dx + sideToCam * elbowOut,
      jerseyRect.top + jerseyRect.height * 0.45,
    );
    final Offset hand = Offset(
      jerseyRect.center.dx + sideToCam * bodyWidth * 0.34,
      jerseyRect.top + jerseyRect.height * 0.62,
    );

    final Paint armPaint = Paint()
      ..color = const Color(0xFFD9AE90)
      ..strokeWidth = (bodyWidth * 0.16).clamp(3.0, 16.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Path armPath = Path()
      ..moveTo(shoulder.dx, shoulder.dy)
      ..lineTo(elbow.dx, elbow.dy)
      ..lineTo(hand.dx, hand.dy);
    canvas.drawPath(armPath, armPaint);

    // Kask.
    canvas.drawOval(
      Rect.fromCenter(
        center: jerseyRect.topCenter - Offset(0, bodyWidth * 0.16),
        width: bodyWidth * 0.36,
        height: bodyWidth * 0.30,
      ),
      Paint()..color = rival.helmetColor,
    );

    // Ostrzeżenie kolizyjne łokcia przy bardzo bliskim kontakcie.
    if (!isPictureInPicture && rival.elbowPressure > 0.55) {
      canvas.drawCircle(
        elbow,
        (bodyWidth * 0.14).clamp(5.0, 18.0),
        Paint()
          ..color = AppColors.crimsonAlert.withValues(
            alpha: (rival.elbowPressure * 0.55).clamp(0.15, 0.7),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  /// Dolna krawędź własnego mostka, kierownicy i licznika w kamerze przedniej.
  void _paintOwnHandlebarEdge(Canvas canvas, Size size) {
    final double barY = size.height * 0.90 + frame.vibration.offsetPx.dy * 0.35;
    final Paint carbonPaint = Paint()
      ..color = const Color(0xFF151820)
      ..strokeWidth = isPictureInPicture ? 8.0 : 18.0
      ..strokeCap = StrokeCap.round;

    // Lekko wygięta szerokokątnym obiektywem kierownica na dole kadru.
    final Path barPath = Path()
      ..moveTo(-10, size.height * 0.98)
      ..quadraticBezierTo(size.width * 0.5, barY, size.width + 10, size.height * 0.98);
    canvas.drawPath(barPath, carbonPaint);

    // Krawędź uchwytu kamery / mostka na środku.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, barY + 6),
          width: isPictureInPicture ? 24 : 52,
          height: isPictureInPicture ? 10 : 20,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF262B36),
    );
  }

  /// Własne tylne koło i kaseta widziane z kamery pod siodełkiem.
  void _paintOwnUnderSaddleWheelAndCassette(Canvas canvas, Size size) {
    final Offset topCenter = Offset(size.width * 0.5, size.height * 0.56);
    final double wheelW = isPictureInPicture ? 14.0 : 32.0;
    final double wheelH = size.height * 0.44;

    final Rect tireRect = Rect.fromLTWH(
      topCenter.dx - wheelW * 0.5,
      topCenter.dy,
      wheelW,
      wheelH,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tireRect, Radius.circular(wheelW * 0.5)),
      Paint()..color = const Color(0xFF12151C),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        tireRect.deflate(wheelW * 0.16),
        Radius.circular(wheelW * 0.34),
      ),
      Paint()..color = const Color(0xFF282E3B),
    );

    // Widoczna prawa kaseta na dole kadru pod siodłem.
    final double cogBaseX = topCenter.dx + wheelW * 0.64;
    final double cogBaseY = size.height * 0.84;
    for (int i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cogBaseX + i * (isPictureInPicture ? 2.0 : 4.2), cogBaseY),
            width: isPictureInPicture ? 1.5 : 2.8,
            height: (isPictureInPicture ? 14.0 : 30.0) - i * 3.5,
          ),
          const Radius.circular(1),
        ),
        Paint()..color = const Color(0xFFC4C9D4),
      );
    }
  }

  void _paintSpeedBlurAndFisheyeVignette(Canvas canvas, Size size) {
    // Promieniste smugi prędkości na skraju obiektywu 140°.
    final double speedIntensity = ((frame.speedKmh - 42.0) / 36.0).clamp(0.0, 1.0);
    if (speedIntensity > 0.05) {
      final Offset center = Offset(size.width * 0.5, size.height * 0.48);
      final double maxR = size.longestSide * 0.65;
      final Paint streakPaint = Paint()
        ..color = AppColors.textPrimary.withValues(alpha: 0.14 * speedIntensity)
        ..strokeWidth = isPictureInPicture ? 0.9 : 1.5
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 16; i++) {
        final double angle =
            (i / 16.0) * 2.0 * math.pi + (frame.elapsedTimeSeconds * 0.4);
        final double rStart = maxR * (0.64 + ((i * 19) % 10) * 0.02);
        final double rEnd = maxR * 0.98;
        canvas.drawLine(
          center + Offset(math.cos(angle) * rStart, math.sin(angle) * rStart),
          center + Offset(math.cos(angle) * rEnd, math.sin(angle) * rEnd),
          streakPaint,
        );
      }
    }

    // Winieta obiektywu rybiego oka 140°.
    final Paint vignette = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.5),
        size.longestSide * 0.62,
        <Color>[
          Colors.transparent,
          Colors.transparent,
          Colors.black.withValues(alpha: 0.58),
        ],
        <double>[0.0, 0.64, 1.0],
      );
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant OnBoardActionCam3dPainter oldDelegate) {
    return oldDelegate.frame.elapsedTimeSeconds != frame.elapsedTimeSeconds ||
        oldDelegate.config.mountPosition != config.mountPosition ||
        oldDelegate.config.roadSurface != config.roadSurface ||
        oldDelegate.config.stabilizationEnabled != config.stabilizationEnabled ||
        oldDelegate.config.fovDegrees != config.fovDegrees ||
        oldDelegate.renderMount != renderMount;
  }
}

/// Główny widget widoku 3D Kamery Akcji Zamontowanej Pod Siodełkiem i Na Kierownicy.
///
/// Obsługuje szeroki kąt 140° FOV, mikro-drgania asfaltu, widok tylnego koła i kasety
/// kolarza z przodu oraz symulację walki łokieć w łokieć na ostatnich 1500 m przed sprintem.
class OnBoardBikeMountedActionCam3d extends StatefulWidget {
  final ActionCam140Config initialConfig;
  final double initialDistanceToFinishMeters;
  final double initialSpeedKmh;
  final bool autoPlay;
  final ValueChanged<ActionCam140Config>? onConfigChanged;

  const OnBoardBikeMountedActionCam3d({
    super.key,
    this.initialConfig = const ActionCam140Config(),
    this.initialDistanceToFinishMeters = 1500.0,
    this.initialSpeedKmh = 64.5,
    this.autoPlay = true,
    this.onConfigChanged,
  });

  @override
  State<OnBoardBikeMountedActionCam3d> createState() =>
      _OnBoardBikeMountedActionCam3dState();
}

class _OnBoardBikeMountedActionCam3dState
    extends State<OnBoardBikeMountedActionCam3d>
    with SingleTickerProviderStateMixin {
  late ActionCam140Config _config;
  late double _distanceToFinishMeters;
  late double _speedKmh;
  late bool _isPlaying;
  late Ticker _ticker;
  Duration _lastTick = Duration.zero;
  double _elapsedSeconds = 0.0;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _distanceToFinishMeters =
        widget.initialDistanceToFinishMeters.clamp(0.0, 1500.0);
    _speedKmh = widget.initialSpeedKmh.clamp(35.0, 78.0);
    _isPlaying = widget.autoPlay;

    _ticker = createTicker(_onTick);
    if (_isPlaying) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (!_isPlaying) return;
    final Duration delta =
        _lastTick == Duration.zero ? const Duration(milliseconds: 16) : elapsed - _lastTick;
    _lastTick = elapsed;
    final double dt = (delta.inMicroseconds / 1000000.0).clamp(0.0, 0.05);

    setState(() {
      _elapsedSeconds += dt;
      final double speedMs = _speedKmh / 3.6;
      _distanceToFinishMeters -= speedMs * dt;
      if (_distanceToFinishMeters <= 0.0) {
        _distanceToFinishMeters = 1500.0;
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _updateConfig(ActionCam140Config next) {
    setState(() {
      _config = next;
    });
    widget.onConfigChanged?.call(next);
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _lastTick = Duration.zero;
        if (!_ticker.isActive) {
          _ticker.start();
        }
      } else {
        _ticker.stop();
      }
    });
  }

  void _resetTo1500m() {
    setState(() {
      _distanceToFinishMeters = 1500.0;
      _elapsedSeconds = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final OnBoardActionCamFrameState frame =
        Final1500mSprintBattleGenerator.buildFrame(
      elapsedSeconds: _elapsedSeconds,
      distanceToFinishMeters: _distanceToFinishMeters,
      speedKmh: _speedKmh,
      config: _config,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isDesktopWide = constraints.maxWidth >= 920;
          final bool isCompactMobile = constraints.maxWidth < 520;

          final Widget viewport = _buildCameraViewport(
            frame: frame,
            isCompact: isCompactMobile,
          );
          final Widget controls = _buildControlPanel(
            frame: frame,
            isCompact: isCompactMobile,
          );

          if (isDesktopWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(flex: 13, child: viewport),
                const SizedBox(width: 14),
                SizedBox(
                  width: 340,
                  child: SingleChildScrollView(child: controls),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  height: isCompactMobile ? 250 : 340,
                  child: viewport,
                ),
                const SizedBox(height: 12),
                controls,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCameraViewport({
    required OnBoardActionCamFrameState frame,
    required bool isCompact,
  }) {
    final ActionCamMountPosition mainMount =
        _config.mountPosition == ActionCamMountPosition.underSaddleRear
            ? ActionCamMountPosition.underSaddleRear
            : ActionCamMountPosition.handlebarForward;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CustomPaint(
              painter: OnBoardActionCam3dPainter(
                config: _config,
                frame: frame,
                renderMount: mainMount,
              ),
            ),
            if (_config.mountPosition == ActionCamMountPosition.dualSplitCam)
              Positioned(
                right: 12,
                bottom: 12,
                width: isCompact ? 116 : 186,
                height: isCompact ? 76 : 112,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.goldAccent.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        CustomPaint(
                          painter: OnBoardActionCam3dPainter(
                            config: _config,
                            frame: frame,
                            renderMount: ActionCamMountPosition.underSaddleRear,
                            isPictureInPicture: true,
                          ),
                        ),
                        Positioned(
                          left: 6,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'POD SIODŁEM',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.goldAccent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_config.showCameraOsd)
              _buildCameraOsdOverlay(frame: frame, isCompact: isCompact),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraOsdOverlay({
    required OnBoardActionCamFrameState frame,
    required bool isCompact,
  }) {
    final bool highElbowRisk = frame.elbowCollisionRisk > 0.55;

    return Padding(
      padding: EdgeInsets.all(isCompact ? 8 : 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 6,
            spacing: 6,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A2F3D)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isPlaying
                            ? AppColors.crimsonAlert
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_config.mountPosition.mountCode} • ${_config.fovDegrees.round()}° FOV',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isCompact ? 10 : 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: frame.distanceToFinishMeters <= 500
                        ? AppColors.goldAccent
                        : const Color(0xFF2A2F3D),
                  ),
                ),
                child: Text(
                  'META: ${frame.distanceToFinishMeters.toStringAsFixed(0)} m',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 10 : 12,
                    fontWeight: FontWeight.w800,
                    color: frame.distanceToFinishMeters <= 500
                        ? AppColors.goldAccent
                        : AppColors.textPrimary,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            runSpacing: 6,
            spacing: 6,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A2F3D)),
                ),
                child: Text(
                  '${frame.speedKmh.toStringAsFixed(1)} km/h  |  '
                  '${frame.powerWatts.round()} W  |  '
                  '${frame.gearFrontTeeth}x${frame.gearRearTeeth}T',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 10 : 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentBlue,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              if (highElbowRisk && !isCompact)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.crimsonAlert.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.crimsonAlert),
                  ),
                  child: const Text(
                    'KONTAKT ŁOKCIEM!',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.crimsonAlert,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel({
    required OnBoardActionCamFrameState frame,
    required bool isCompact,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.videocam_rounded,
                color: AppColors.goldAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Kamera Akcji 140° FOV',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              _ActionCamInteractiveChip(
                label: _isPlaying ? 'Pauza' : 'Start',
                isSelected: _isPlaying,
                accentColor: AppColors.statusSuccess,
                onTap: _togglePlayPause,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Mocowanie kamery',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ActionCamMountPosition.values
                .map(
                  (ActionCamMountPosition pos) => _ActionCamInteractiveChip(
                    label: pos.shortLabel,
                    isSelected: _config.mountPosition == pos,
                    accentColor: AppColors.goldAccent,
                    onTap: () => _updateConfig(_config.copyWith(mountPosition: pos)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nawierzchnia i mikro-drgania',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ActionCamRoadSurface.values
                .map(
                  (ActionCamRoadSurface surf) => _ActionCamInteractiveChip(
                    label: surf.label,
                    isSelected: _config.roadSurface == surf,
                    accentColor: AppColors.accentBlue,
                    onTap: () => _updateConfig(_config.copyWith(roadSurface: surf)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _ActionCamInteractiveChip(
                label: _config.stabilizationEnabled
                    ? 'Stabilizacja: ON'
                    : 'Stabilizacja: OFF',
                isSelected: _config.stabilizationEnabled,
                accentColor: AppColors.cyanAccent,
                onTap: () => _updateConfig(
                  _config.copyWith(
                    stabilizationEnabled: !_config.stabilizationEnabled,
                  ),
                ),
              ),
              _ActionCamInteractiveChip(
                label: _config.showCameraOsd ? 'OSD: ON' : 'OSD: OFF',
                isSelected: _config.showCameraOsd,
                accentColor: AppColors.primaryAccent,
                onTap: () => _updateConfig(
                  _config.copyWith(showCameraOsd: !_config.showCameraOsd),
                ),
              ),
              _ActionCamInteractiveChip(
                label: 'Reset 1500 m',
                isSelected: false,
                accentColor: AppColors.amberWarning,
                onTap: _resetTo1500m,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTelemetrySlider(
            label: 'Prędkość pociągu sprinterskiego',
            valueLabel: '${_speedKmh.toStringAsFixed(1)} km/h',
            value: _speedKmh,
            min: 40.0,
            max: 76.0,
            onChanged: (double v) => setState(() => _speedKmh = v),
          ),
          const SizedBox(height: 8),
          _buildTelemetrySlider(
            label: 'Obiektyw rybie oko FOV',
            valueLabel: '${_config.fovDegrees.round()}°',
            value: _config.fovDegrees,
            min: 120.0,
            max: 150.0,
            onChanged: (double v) =>
                _updateConfig(_config.copyWith(fovDegrees: v)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2F3D)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _buildMetricColumn(
                    'Luka przód',
                    '${(frame.leadWheelGapMeters * 100).round()} cm',
                    AppColors.accentBlue,
                  ),
                ),
                Expanded(
                  child: _buildMetricColumn(
                    'Drgania RMS',
                    '${frame.vibration.gForceRms.toStringAsFixed(2)} G',
                    AppColors.amberWarning,
                  ),
                ),
                Expanded(
                  child: _buildMetricColumn(
                    'Presja łokci',
                    '${(frame.elbowCollisionRisk * 100).round()}%',
                    frame.elbowCollisionRisk > 0.55
                        ? AppColors.crimsonAlert
                        : AppColors.statusSuccess,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetrySlider({
    required String label,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              valueLabel,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.goldAccent,
            inactiveTrackColor: const Color(0xFF2A2F3D),
            thumbColor: AppColors.textPrimary,
            overlayColor: AppColors.goldAccent.withValues(alpha: 0.18),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricColumn(String title, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Interaktywny przycisk wyboru z pełnymi stanami hover, active, focus i disabled.
class _ActionCamInteractiveChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback? onTap;

  const _ActionCamInteractiveChip({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    this.onTap,
  });

  @override
  State<_ActionCamInteractiveChip> createState() =>
      _ActionCamInteractiveChipState();
}

class _ActionCamInteractiveChipState extends State<_ActionCamInteractiveChip> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onTap == null;

    final Color bgColor = isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.isSelected
            ? widget.accentColor.withValues(alpha: _isPressed ? 0.34 : 0.22)
            : _isPressed
                ? AppColors.surfaceLight
                : _isHovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.85)
                    : AppColors.background;

    final Color borderColor = isDisabled
        ? const Color(0xFF2A2F3D).withValues(alpha: 0.5)
        : _isFocused
            ? AppColors.textPrimary
            : widget.isSelected
                ? widget.accentColor
                : _isHovered
                    ? widget.accentColor.withValues(alpha: 0.6)
                    : const Color(0xFF2A2F3D);

    return FocusableActionDetector(
      enabled: !isDisabled,
      onShowHoverHighlight: (bool hover) => setState(() => _isHovered = hover),
      onShowFocusHighlight: (bool focus) => setState(() => _isFocused = focus),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
          onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
          onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1.0),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isDisabled
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : widget.isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
