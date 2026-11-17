// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../models/race/cyclocross_course_and_mud_model.dart';
import '../physics/cyclocross_bunnyhop_and_carry_solver.dart';

// =============================================================================
// 1. PRESETY ARENY PRZEŁAJOWEJ CX I KONFIGURACJA RENDERERA 3D
// =============================================================================

/// Charakterystyka stylistyczna areny przełajowej (CX).
enum CyclocrossArenaStylePreset {
  koksijdeDunes(
    labelPl: 'Koksijde (Wydmy & Morze)',
    shortTag: 'KOKSIJDE',
    locationPl: 'Wybrzeże Morza Północnego, Belgia',
    hasCoastalSea: true,
    defaultSandDepthCm: 24.0,
    defaultMudCondition: CyclocrossMudCondition.tackyLoam,
  ),
  zonhovenSandBowl(
    labelPl: 'Zonhoven (Piaskowy Kocioł)',
    shortTag: 'ZONHOVEN',
    locationPl: 'De Kuil, Limburgia, Belgia',
    hasCoastalSea: true,
    defaultSandDepthCm: 28.0,
    defaultMudCondition: CyclocrossMudCondition.heavyMud,
  ),
  namurCitadelMud(
    labelPl: 'Namur (Cytadela & Błoto)',
    shortTag: 'NAMUR',
    locationPl: 'Cytadela nad Mozą, Walonia',
    hasCoastalSea: false,
    defaultSandDepthCm: 0.0,
    defaultMudCondition: CyclocrossMudCondition.boggySwamp,
  ),
  gavereMeadow(
    labelPl: 'Gavere (Łąka, Belki & Schody)',
    shortTag: 'GAVERE',
    locationPl: 'Flandria Wschodnia, Belgia',
    hasCoastalSea: false,
    defaultSandDepthCm: 8.0,
    defaultMudCondition: CyclocrossMudCondition.heavyMud,
  );

  final String labelPl;
  final String shortTag;
  final String locationPl;
  final bool hasCoastalSea;
  final double defaultSandDepthCm;
  final CyclocrossMudCondition defaultMudCondition;

  const CyclocrossArenaStylePreset({
    required this.labelPl,
    required this.shortTag,
    required this.locationPl,
    required this.hasCoastalSea,
    required this.defaultSandDepthCm,
    required this.defaultMudCondition,
  });
}

/// Konfiguracja kamery i detali sceny 3D dla areny przełajowej.
class Cyclocross3dArenaConfig {
  final CyclocrossArenaStylePreset stylePreset;
  final double fieldOfViewDegrees;
  final double maxDrawDistanceMeters;
  final double courseWidthMeters;
  final double tapePostSpacingMeters;
  final double seaWindSpeedMps;
  final double mudWetnessFactor;
  final bool showFritesTentsAndSpectators;
  final bool showDoublePitBox;
  final bool showCoastalSandAndSea;
  final bool showTelemetryOverlay;

  const Cyclocross3dArenaConfig({
    this.stylePreset = CyclocrossArenaStylePreset.koksijdeDunes,
    this.fieldOfViewDegrees = 56.0,
    this.maxDrawDistanceMeters = 190.0,
    this.courseWidthMeters = 3.4,
    this.tapePostSpacingMeters = 3.5,
    this.seaWindSpeedMps = 7.5,
    this.mudWetnessFactor = 0.82,
    this.showFritesTentsAndSpectators = true,
    this.showDoublePitBox = true,
    this.showCoastalSandAndSea = true,
    this.showTelemetryOverlay = true,
  });

  Cyclocross3dArenaConfig copyWith({
    CyclocrossArenaStylePreset? stylePreset,
    double? fieldOfViewDegrees,
    double? maxDrawDistanceMeters,
    double? courseWidthMeters,
    double? tapePostSpacingMeters,
    double? seaWindSpeedMps,
    double? mudWetnessFactor,
    bool? showFritesTentsAndSpectators,
    bool? showDoublePitBox,
    bool? showCoastalSandAndSea,
    bool? showTelemetryOverlay,
  }) {
    return Cyclocross3dArenaConfig(
      stylePreset: stylePreset ?? this.stylePreset,
      fieldOfViewDegrees: fieldOfViewDegrees ?? this.fieldOfViewDegrees,
      maxDrawDistanceMeters:
          maxDrawDistanceMeters ?? this.maxDrawDistanceMeters,
      courseWidthMeters: courseWidthMeters ?? this.courseWidthMeters,
      tapePostSpacingMeters:
          tapePostSpacingMeters ?? this.tapePostSpacingMeters,
      seaWindSpeedMps: seaWindSpeedMps ?? this.seaWindSpeedMps,
      mudWetnessFactor: mudWetnessFactor ?? this.mudWetnessFactor,
      showFritesTentsAndSpectators:
          showFritesTentsAndSpectators ?? this.showFritesTentsAndSpectators,
      showDoublePitBox: showDoublePitBox ?? this.showDoublePitBox,
      showCoastalSandAndSea:
          showCoastalSandAndSea ?? this.showCoastalSandAndSea,
      showTelemetryOverlay: showTelemetryOverlay ?? this.showTelemetryOverlay,
    );
  }
}

// =============================================================================
// 2. MODELE GEOMETRII OBIEKTÓW 3D ARENY CX
// =============================================================================

/// Próbka osi krętej trasy CX w przestrzeni 3D (układ X-Y-Z).
class CyclocrossCourseSample3D {
  final double distanceMeters;
  final Vector3 center;
  final Vector3 tangent;
  final Vector3 lateralRight;
  final Vector3 normal;
  final CyclocrossTerrainType terrainType;
  final double halfWidthMeters;
  final double camberRadians;

  const CyclocrossCourseSample3D({
    required this.distanceMeters,
    required this.center,
    required this.tangent,
    required this.lateralRight,
    required this.normal,
    required this.terrainType,
    required this.halfWidthMeters,
    required this.camberRadians,
  });

  Vector3 get leftEdge => center - (lateralRight * halfWidthMeters);
  Vector3 get rightEdge => center + (lateralRight * halfWidthMeters);
}

/// Słupek wyznaczający taśmę trasy przełajowej.
class CourseTapePost3D {
  final double distanceMeters;
  final bool isRightSide;
  final Vector3 basePosition;
  final Vector3 topPosition;
  final Color postColor;
  final Color tapeColorPrimary;
  final Color tapeColorSecondary;

  const CourseTapePost3D({
    required this.distanceMeters,
    required this.isRightSide,
    required this.basePosition,
    required this.topPosition,
    required this.postColor,
    required this.tapeColorPrimary,
    required this.tapeColorSecondary,
  });
}

/// Drewniana belka przeszkodowa CX (zwykle 2 belki o wysokości 40 cm).
class CyclocrossWoodenPlankBarrier3D {
  final int barrierIndex;
  final double distanceMeters;
  final double heightMeters;
  final Vector3 leftFoot;
  final Vector3 rightFoot;
  final Vector3 leftTop;
  final Vector3 rightTop;
  final bool isBunnyHoppable;

  const CyclocrossWoodenPlankBarrier3D({
    required this.barrierIndex,
    required this.distanceMeters,
    required this.heightMeters,
    required this.leftFoot,
    required this.rightFoot,
    required this.leftTop,
    required this.rightTop,
    required this.isBunnyHoppable,
  });
}

/// Schody przełajowe (Run-Up Staircase) w 3D.
class CyclocrossStaircaseRunUp3D {
  final double startDistanceMeters;
  final double endDistanceMeters;
  final int stepCount;
  final double totalRiseMeters;
  final List<Vector3> stepLeftEdges;
  final List<Vector3> stepRightEdges;

  const CyclocrossStaircaseRunUp3D({
    required this.startDistanceMeters,
    required this.endDistanceMeters,
    required this.stepCount,
    required this.totalRiseMeters,
    required this.stepLeftEdges,
    required this.stepRightEdges,
  });
}

/// Nadmorska ławica piasku i wydmy w stylu Koksijde/Zonhoven.
class CyclocrossCoastalSandPit3D {
  final double startDistanceMeters;
  final double endDistanceMeters;
  final double sandDepthCm;
  final List<Vector3> leftDuneCrest;
  final List<Vector3> rightDuneCrest;
  final List<Vector3> marramGrassTufts;

  const CyclocrossCoastalSandPit3D({
    required this.startDistanceMeters,
    required this.endDistanceMeters,
    required this.sandDepthCm,
    required this.leftDuneCrest,
    required this.rightDuneCrest,
    required this.marramGrassTufts,
  });
}

/// Namiot z frytkami ("FRIETEN / BIER") i grupą kibiców przy taśmie.
class CyclocrossFritesTentAndSpectators3D {
  final int tentId;
  final String signText;
  final Vector3 baseCenter;
  final Vector3 tangent;
  final Vector3 lateralRight;
  final double widthMeters;
  final double depthMeters;
  final double heightMeters;
  final Color awningPrimaryColor;
  final Color awningSecondaryColor;
  final List<CyclocrossSpectator3D> nearbySpectators;

  const CyclocrossFritesTentAndSpectators3D({
    required this.tentId,
    required this.signText,
    required this.baseCenter,
    required this.tangent,
    required this.lateralRight,
    required this.widthMeters,
    required this.depthMeters,
    required this.heightMeters,
    required this.awningPrimaryColor,
    required this.awningSecondaryColor,
    required this.nearbySpectators,
  });
}

/// Pojedynczy kibic przełajowy przy taśmie (kurtka, czapka, flaga lub kubek).
class CyclocrossSpectator3D {
  final Vector3 position;
  final Color jacketColor;
  final Color beanieColor;
  final bool hasFlag;
  final List<Color> flagColors;
  final double phaseOffset;
  final bool hasCowbell;

  const CyclocrossSpectator3D({
    required this.position,
    required this.jacketColor,
    required this.beanieColor,
    required this.hasFlag,
    required this.flagColors,
    required this.phaseOffset,
    required this.hasCowbell,
  });
}

/// Mechanik w boksie technicznym trzymający zapasowy rower gotowy do wymiany.
class CyclocrossPitMechanic3D {
  final int boxIndex;
  final String teamCode;
  final Vector3 position;
  final Vector3 facingDirection;
  final Color teamColor;
  final Color spareBikeFrameColor;
  final bool holdingSpareBikeReady;
  final bool hasPressureWasherSpray;

  const CyclocrossPitMechanic3D({
    required this.boxIndex,
    required this.teamCode,
    required this.position,
    required this.facingDirection,
    required this.teamColor,
    required this.spareBikeFrameColor,
    required this.holdingSpareBikeReady,
    required this.hasPressureWasherSpray,
  });
}

/// Boks techniczny (Double Pit Lane) z konstrukcjami, stojakami i mechanikami.
class CyclocrossPitBoxAndMechanics3D {
  final double startDistanceMeters;
  final double endDistanceMeters;
  final CyclocrossPitLaneSide side;
  final List<CyclocrossPitMechanic3D> mechanics;
  final List<Vector3> pitCanopyCorners;

  const CyclocrossPitBoxAndMechanics3D({
    required this.startDistanceMeters,
    required this.endDistanceMeters,
    required this.side,
    required this.mechanics,
    required this.pitCanopyCorners,
  });
}

// =============================================================================
// 3. ANIMATOR 3D KOLARZA BIEGNĄCEGO Z ROWEREM NA PRAWYM RAMIENIU
// =============================================================================

/// Stan wejściowy animowanego kolarza przełajowego w scenie 3D.
class CyclocrossRider3DActor {
  final String riderId;
  final String shortName;
  final Color jerseyColor;
  final Color helmetColor;
  final Color bikeFrameColor;
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double speedMps;
  final CyclocrossTraversalMode traversalMode;
  final double animationTimeSeconds;
  final double mudAccumulationRatio;

  const CyclocrossRider3DActor({
    required this.riderId,
    required this.shortName,
    required this.jerseyColor,
    required this.helmetColor,
    required this.bikeFrameColor,
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.speedMps,
    required this.traversalMode,
    required this.animationTimeSeconds,
    this.mudAccumulationRatio = 0.35,
  });
}

/// Rozwiązana poza 3D kolarza biegnącego z rowerem na prawym ramieniu
/// (lub jadącego w siodle / wykonującego bunny-hop).
class CyclocrossShoulderCarryPose3D {
  final CyclocrossTraversalMode mode;
  final Vector3 pelvis;
  final Vector3 chest;
  final Vector3 head;
  final Vector3 leftShoulder;
  final Vector3 rightShoulder;
  final Vector3 leftElbow;
  final Vector3 leftHand;
  final Vector3 rightElbow;
  final Vector3 rightHand;
  final Vector3 leftHip;
  final Vector3 leftKnee;
  final Vector3 leftFoot;
  final Vector3 rightHip;
  final Vector3 rightKnee;
  final Vector3 rightFoot;
  // Geometria roweru (na prawym ramieniu podczas biegu lub pod kolarzem podczas jazdy)
  final Vector3 bikeRearAxle;
  final Vector3 bikeFrontAxle;
  final Vector3 bikeBottomBracket;
  final Vector3 bikeSeatCluster;
  final Vector3 bikeHeadTubeTop;
  final Vector3 bikeHandlebarRight;
  final Vector3 bikeHandlebarLeft;
  final double wheelRadiusMeters;
  final double verticalHopHeightMeters;
  final double stridePhaseRadians;

  const CyclocrossShoulderCarryPose3D({
    required this.mode,
    required this.pelvis,
    required this.chest,
    required this.head,
    required this.leftShoulder,
    required this.rightShoulder,
    required this.leftElbow,
    required this.leftHand,
    required this.rightElbow,
    required this.rightHand,
    required this.leftHip,
    required this.leftKnee,
    required this.leftFoot,
    required this.rightHip,
    required this.rightKnee,
    required this.rightFoot,
    required this.bikeRearAxle,
    required this.bikeFrontAxle,
    required this.bikeBottomBracket,
    required this.bikeSeatCluster,
    required this.bikeHeadTubeTop,
    required this.bikeHandlebarRight,
    required this.bikeHandlebarLeft,
    required this.wheelRadiusMeters,
    required this.verticalHopHeightMeters,
    required this.stridePhaseRadians,
  });
}

/// Kinematyczny animator 3D kolarza biegnącego z rowerem na prawym ramieniu
/// (`CyclocrossCarryTechnique.shoulderCarry`), z obsługą przejść do jazdy i bunny-hopa.
class CyclocrossShoulderCarryRunnerAnimator {
  const CyclocrossShoulderCarryRunnerAnimator();

  /// Wylicza pełną pozę 3D szkieletu kolarza i ramy roweru w układzie świata.
  CyclocrossShoulderCarryPose3D evaluatePose({
    required CyclocrossRider3DActor actor,
    required CyclocrossCourseSample3D courseSample,
  }) {
    final forward = courseSample.tangent.normalized();
    final right = courseSample.lateralRight.normalized();
    final up = courseSample.normal.normalized();

    final baseOrigin = courseSample.center + (right * actor.lateralOffsetMeters);
    final speed = actor.speedMps.clamp(1.5, 14.0);

    if (actor.traversalMode == CyclocrossTraversalMode.dismountAndRun) {
      return _buildShoulderCarryRunningPose(
        origin: baseOrigin,
        forward: forward,
        right: right,
        up: up,
        speedMps: speed,
        timeSec: actor.animationTimeSeconds,
      );
    } else if (actor.traversalMode == CyclocrossTraversalMode.bunnyHop) {
      return _buildBunnyHopPose(
        origin: baseOrigin,
        forward: forward,
        right: right,
        up: up,
        speedMps: speed,
        timeSec: actor.animationTimeSeconds,
      );
    }
    return _buildRidingInSaddlePose(
      origin: baseOrigin,
      forward: forward,
      right: right,
      up: up,
      speedMps: speed,
      timeSec: actor.animationTimeSeconds,
    );
  }

  /// Klasyczny bieg przełajowy z rowerem zarzuconym na PRAWE ramię:
  /// - prawa ręka przechodzi przez przedni trójkąt ramy i trzyma prawy chwyt kierownicy/widelec,
  /// - górna rura ramy spoczywa na prawym barku,
  /// - lewa ręka pracuje w przeciwfazie do lewej nogi dla równowagi w błocie/piasku/na schodach.
  CyclocrossShoulderCarryPose3D _buildShoulderCarryRunningPose({
    required Vector3 origin,
    required Vector3 forward,
    required Vector3 right,
    required Vector3 up,
    required double speedMps,
    required double timeSec,
  }) {
    final strideHz = (1.65 + (speedMps * 0.24)).clamp(1.8, 3.6);
    final phase = timeSec * strideHz * 2.0 * math.pi;
    final bounce = (math.sin(phase * 2.0).abs()) * 0.075;
    final torsoTwist = math.sin(phase) * 0.08;

    final pelvis = origin + up * (0.90 + bounce);
    final chest = pelvis + up * 0.44 + forward * 0.17;
    final head = chest + up * 0.24 + forward * 0.07;

    // Prawy bark lekko podniesiony, bo spoczywa na nim rama roweru (7.8-8.5 kg)
    final rightShoulder =
        chest + right * (0.21 + torsoTwist * 0.2) + up * 0.05;
    final leftShoulder =
        chest - right * (0.21 - torsoTwist * 0.2) + up * 0.01;

    // Prawa ręka: przechodzi pod górną rurą i chwyta dolny chwyt kierownicy / koronę widelca
    final rightElbow = rightShoulder + forward * 0.14 - up * 0.18 + right * 0.06;
    final rightHand = rightShoulder + forward * 0.31 - up * 0.04 + right * 0.11;

    // Lewa ręka: dynamiczny wymach biegowy w przeciwfazie do prawej nogi
    final leftArmSwing = math.sin(phase);
    final leftElbow = leftShoulder -
        forward * (0.12 * leftArmSwing) -
        up * 0.20 -
        right * 0.07;
    final leftHand =
        leftElbow + forward * (0.22 + 0.14 * leftArmSwing) + up * 0.08;

    // Nogi w pełnym cyklu biegu (unoszenie kolan w błocie / na schodach)
    final leftLeg = _solveRunningLeg(
      hip: pelvis - right * 0.10,
      phase: phase,
      forward: forward,
      up: up,
    );
    final rightLeg = _solveRunningLeg(
      hip: pelvis + right * 0.10,
      phase: phase + math.pi,
      forward: forward,
      up: up,
    );

    // Rower zarzucony na PRAWE ramię:
    // Górna rura spoczywa bezpośrednio na `rightShoulder + up * 0.03`.
    // Koła lekko bujają się w rytm kroków biegacza.
    final bikeOscillation = math.sin(phase) * 0.035;
    final bikeCarryAnchor = rightShoulder + right * 0.05 + up * 0.04;

    // Orientacja ramy na prawym ramieniu: przód skierowany do przodu i lekko w prawo,
    // tył za plecami lekko w lewo-dół.
    final bikeForwardAxis =
        (forward * 0.92 + up * (0.14 + bikeOscillation) + right * 0.18)
            .normalized();
    final bikeUpAxis = (up * 0.90 + right * 0.36 - forward * 0.12).normalized();
    final bikeRightAxis = bikeForwardAxis.cross(bikeUpAxis).normalized();

    final seatCluster = bikeCarryAnchor - bikeForwardAxis * 0.24 - bikeUpAxis * 0.02;
    final headTubeTop = bikeCarryAnchor + bikeForwardAxis * 0.30 + bikeUpAxis * 0.03;
    final bottomBracket =
        bikeCarryAnchor + bikeForwardAxis * 0.02 - bikeUpAxis * 0.44;
    final rearAxle =
        bottomBracket - bikeForwardAxis * 0.42 + bikeUpAxis * 0.05;
    final frontAxle =
        bottomBracket + bikeForwardAxis * 0.58 + bikeUpAxis * 0.05;

    final barCenter = headTubeTop + bikeUpAxis * 0.07 + bikeForwardAxis * 0.07;
    final handlebarRight = barCenter + bikeRightAxis * 0.21;
    final handlebarLeft = barCenter - bikeRightAxis * 0.21;

    return CyclocrossShoulderCarryPose3D(
      mode: CyclocrossTraversalMode.dismountAndRun,
      pelvis: pelvis,
      chest: chest,
      head: head,
      leftShoulder: leftShoulder,
      rightShoulder: rightShoulder,
      leftElbow: leftElbow,
      leftHand: leftHand,
      rightElbow: rightElbow,
      rightHand: rightHand,
      leftHip: pelvis - right * 0.10,
      leftKnee: leftLeg.$1,
      leftFoot: leftLeg.$2,
      rightHip: pelvis + right * 0.10,
      rightKnee: rightLeg.$1,
      rightFoot: rightLeg.$2,
      bikeRearAxle: rearAxle,
      bikeFrontAxle: frontAxle,
      bikeBottomBracket: bottomBracket,
      bikeSeatCluster: seatCluster,
      bikeHeadTubeTop: headTubeTop,
      bikeHandlebarRight: handlebarRight,
      bikeHandlebarLeft: handlebarLeft,
      wheelRadiusMeters: 0.34,
      verticalHopHeightMeters: bounce,
      stridePhaseRadians: phase,
    );
  }

  /// Kinematyka nogi biegacza w przód/tył z wysokim unoszeniem kolana nad błotem.
  (Vector3, Vector3) _solveRunningLeg({
    required Vector3 hip,
    required double phase,
    required Vector3 forward,
    required Vector3 up,
  }) {
    final swing = math.sin(phase);
    final lift = math.max(0.0, math.cos(phase));
    final knee = hip +
        forward * (0.28 * swing + 0.09) -
        up * (0.37 - 0.16 * lift);
    final foot = knee +
        forward * (0.14 * swing - 0.16 * lift) -
        up * (0.39 - 0.08 * lift);
    return (knee, foot);
  }

  /// Poza przeskoku Bunny-Hop nad drewnianymi belkami 40 cm.
  CyclocrossShoulderCarryPose3D _buildBunnyHopPose({
    required Vector3 origin,
    required Vector3 forward,
    required Vector3 right,
    required Vector3 up,
    required double speedMps,
    required double timeSec,
  }) {
    final hopPhase = (timeSec * 1.4) % 1.0;
    final hopHeight = math.sin(hopPhase * math.pi).clamp(0.0, 1.0) * 0.48;
    final pitchLift = math.sin(hopPhase * math.pi) * 0.18;

    return _buildRidingInSaddlePose(
      origin: origin + up * hopHeight,
      forward: (forward + up * pitchLift).normalized(),
      right: right,
      up: (up - forward * pitchLift).normalized(),
      speedMps: speedMps,
      timeSec: timeSec,
      standingHeightOffset: 0.16,
      modeOverride: CyclocrossTraversalMode.bunnyHop,
      hopHeight: hopHeight,
    );
  }

  /// Standardowa pozycja jazdy w siodle po błocie, łące lub piasku.
  CyclocrossShoulderCarryPose3D _buildRidingInSaddlePose({
    required Vector3 origin,
    required Vector3 forward,
    required Vector3 right,
    required Vector3 up,
    required double speedMps,
    required double timeSec,
    double standingHeightOffset = 0.0,
    CyclocrossTraversalMode modeOverride = CyclocrossTraversalMode.rideInSaddle,
    double hopHeight = 0.0,
  }) {
    const wheelR = 0.34;
    final rearAxle = origin - forward * 0.50 + up * wheelR;
    final frontAxle = origin + forward * 0.52 + up * wheelR;
    final bottomBracket = origin + up * (wheelR - 0.05);
    final seatCluster = bottomBracket - forward * 0.16 + up * 0.52;
    final headTubeTop = bottomBracket + forward * 0.41 + up * 0.54;
    final barCenter = headTubeTop + forward * 0.10 + up * 0.05;
    final handlebarRight = barCenter + right * 0.21;
    final handlebarLeft = barCenter - right * 0.21;

    final pelvis = seatCluster + up * (0.14 + standingHeightOffset);
    final chest = pelvis + forward * 0.34 + up * 0.28;
    final head = chest + forward * 0.14 + up * 0.18;

    final leftShoulder = chest - right * 0.19;
    final rightShoulder = chest + right * 0.19;
    final leftElbow = (leftShoulder + handlebarLeft) * 0.5 - up * 0.06;
    final rightElbow = (rightShoulder + handlebarRight) * 0.5 - up * 0.06;

    final crankPhase = timeSec * (speedMps * 1.35);
    final leftFoot = bottomBracket +
        forward * (math.cos(crankPhase) * 0.17) +
        up * (math.sin(crankPhase) * 0.17) -
        right * 0.09;
    final rightFoot = bottomBracket -
        forward * (math.cos(crankPhase) * 0.17) -
        up * (math.sin(crankPhase) * 0.17) +
        right * 0.09;

    final leftHip = pelvis - right * 0.10;
    final rightHip = pelvis + right * 0.10;
    final leftKnee = (leftHip + leftFoot) * 0.5 + forward * 0.14;
    final rightKnee = (rightHip + rightFoot) * 0.5 + forward * 0.14;

    return CyclocrossShoulderCarryPose3D(
      mode: modeOverride,
      pelvis: pelvis,
      chest: chest,
      head: head,
      leftShoulder: leftShoulder,
      rightShoulder: rightShoulder,
      leftElbow: leftElbow,
      leftHand: handlebarLeft,
      rightElbow: rightElbow,
      rightHand: handlebarRight,
      leftHip: leftHip,
      leftKnee: leftKnee,
      leftFoot: leftFoot,
      rightHip: rightHip,
      rightKnee: rightKnee,
      rightFoot: rightFoot,
      bikeRearAxle: rearAxle,
      bikeFrontAxle: frontAxle,
      bikeBottomBracket: bottomBracket,
      bikeSeatCluster: seatCluster,
      bikeHeadTubeTop: headTubeTop,
      bikeHandlebarRight: handlebarRight,
      bikeHandlebarLeft: handlebarLeft,
      wheelRadiusMeters: wheelR,
      verticalHopHeightMeters: hopHeight,
      stridePhaseRadians: crankPhase,
    );
  }
}

// =============================================================================
// 4. TELEMETRIA I GŁÓWNY RENDERER 3D ARENY PRZEŁAJOWEJ
// =============================================================================

/// Podsumowanie wyrenderowanej klatki 3D areny przełajowej.
class Cyclocross3dArenaTelemetry {
  final int visibleCourseSamples;
  final int tapePostsRendered;
  final int woodenPlanksRendered;
  final int staircasesRendered;
  final int sandPitSectionsRendered;
  final int fritesTentsRendered;
  final int spectatorsRendered;
  final int pitMechanicsRendered;
  final int runningShoulderCarryRiders;
  final double cameraDistanceMeters;

  const Cyclocross3dArenaTelemetry({
    required this.visibleCourseSamples,
    required this.tapePostsRendered,
    required this.woodenPlanksRendered,
    required this.staircasesRendered,
    required this.sandPitSectionsRendered,
    required this.fritesTentsRendered,
    required this.spectatorsRendered,
    required this.pitMechanicsRendered,
    required this.runningShoulderCarryRiders,
    required this.cameraDistanceMeters,
  });

  static const empty = Cyclocross3dArenaTelemetry(
    visibleCourseSamples: 0,
    tapePostsRendered: 0,
    woodenPlanksRendered: 0,
    staircasesRendered: 0,
    sandPitSectionsRendered: 0,
    fritesTentsRendered: 0,
    spectatorsRendered: 0,
    pitMechanicsRendered: 0,
    runningShoulderCarryRiders: 0,
    cameraDistanceMeters: 0.0,
  );
}

/// Wewnętrzny projektowany punkt 2D z głębokością Z w przestrzeni kamery.
class _Projected2D {
  final Offset offset;
  final double depthW;
  final bool isVisible;

  const _Projected2D(this.offset, this.depthW, this.isVisible);
}

/// Dedykowany renderer 3D areny kolarstwa przełajowego (CX):
/// - kręta trasa wyznaczona taśmami w błocie i na łące,
/// - drewniane belki do przeskakiwania,
/// - schody (run-up staircase),
/// - nadmorska ławica piasku i wydmy (styl Koksijde/Zonhoven),
/// - namioty z frytkami ("FRIETEN / BIER") i kibicami,
/// - podwójny boks techniczny z mechanikami trzymającymi zapasowe rowery,
/// - pełna animacja 3D kolarza biegnącego z rowerem na prawym ramieniu.
class Cyclocross3dArenaAndBarriersRenderer {
  final Cyclocross3dArenaConfig config;
  final CyclocrossCourseAndMudModel? courseModel;
  final CyclocrossShoulderCarryRunnerAnimator runnerAnimator;

  const Cyclocross3dArenaAndBarriersRenderer({
    this.config = const Cyclocross3dArenaConfig(),
    this.courseModel,
    this.runnerAnimator = const CyclocrossShoulderCarryRunnerAnimator(),
  });

  /// Wyznacza krętą oś trasy przełajowej w układzie 3D (X-Y-Z) na podstawie dystansu [m].
  CyclocrossCourseSample3D sampleCourseAt(double distanceMeters) {
    final s = distanceMeters;
    // Kręta geometria CX: esy, nawroty w błocie i wzniesienia na wydmy / schody
    final windingX =
        math.sin(s * 0.045) * 9.5 + math.sin(s * 0.017) * 14.0;
    final dxDs =
        (math.cos(s * 0.045) * 9.5 * 0.045) + (math.cos(s * 0.017) * 14.0 * 0.017);

    final terrain = _resolveTerrainAt(s);
    double elevationY = math.sin(s * 0.028) * 1.4;
    double camberRad = 0.0;

    if (terrain == CyclocrossTerrainType.staircaseRunUp) {
      final local = (s - 62.0).clamp(0.0, 14.0);
      elevationY += (local / 14.0) * 3.4;
    } else if (terrain == CyclocrossTerrainType.sandPit) {
      elevationY += 0.45 + math.sin(s * 0.14) * 0.35;
    } else if (terrain == CyclocrossTerrainType.offCamberSlope) {
      camberRad = 0.20;
    }

    final dzDs = math.sqrt(math.max(0.15, 1.0 - (dxDs * dxDs).clamp(0.0, 0.85)));
    final center = Vector3(windingX, elevationY, s);
    final tangent = Vector3(dxDs, 0.0, dzDs).normalized();
    final worldUp = Vector3(0.0, 1.0, 0.0);
    final lateralRight = tangent.cross(worldUp).normalized();
    final normal = (lateralRight.cross(tangent) + lateralRight * math.sin(camberRad))
        .normalized();

    return CyclocrossCourseSample3D(
      distanceMeters: s,
      center: center,
      tangent: tangent,
      lateralRight: lateralRight,
      normal: normal,
      terrainType: terrain,
      halfWidthMeters: config.courseWidthMeters * 0.5,
      camberRadians: camberRad,
    );
  }

  CyclocrossTerrainType _resolveTerrainAt(double distanceMeters) {
    final model = courseModel;
    if (model != null && model.segments.isNotEmpty) {
      final wrapped =
          ((distanceMeters % model.lapLengthMeters) + model.lapLengthMeters) %
              model.lapLengthMeters;
      for (final seg in model.segments) {
        if (wrapped >= seg.startMeter && wrapped < seg.endMeter) {
          return seg.terrainType;
        }
      }
    }

    // Domyślny bogaty układ rundy CX (pokazuje wszystkie kluczowe elementy na 190m widoku)
    final mod = ((distanceMeters % 220.0) + 220.0) % 220.0;
    if (mod < 26.0) return CyclocrossTerrainType.meadowGrass;
    if (mod < 56.0) return CyclocrossTerrainType.deepMud;
    if (mod < 78.0) return CyclocrossTerrainType.staircaseRunUp;
    if (mod < 104.0) return CyclocrossTerrainType.planks;
    if (mod < 152.0) {
      return config.stylePreset.hasCoastalSea && config.showCoastalSandAndSea
          ? CyclocrossTerrainType.sandPit
          : CyclocrossTerrainType.offCamberSlope;
    }
    if (mod < 186.0) return CyclocrossTerrainType.doublePitLane;
    return CyclocrossTerrainType.deepMud;
  }

  /// Buduje widoczne elementy 3D przed kamerą (słupki z taśmą, belki, schody, wydmy, namioty, boks).
  _CyclocrossSceneObjects _buildSceneObjects({
    required double cameraDistanceMeters,
    required double timeSeconds,
  }) {
    final startD = (cameraDistanceMeters - 8.0).clamp(0.0, 100000.0);
    final endD = cameraDistanceMeters + config.maxDrawDistanceMeters;

    final samples = <CyclocrossCourseSample3D>[];
    for (double d = startD; d <= endD; d += 2.5) {
      samples.add(sampleCourseAt(d));
    }

    // 1. Słupki i taśmy po obu stronach krętej trasy
    final posts = <CourseTapePost3D>[];
    final step = config.tapePostSpacingMeters.clamp(2.0, 6.0);
    final firstPost = (startD / step).floor() * step;
    for (double d = firstPost; d <= endD; d += step) {
      if (d < startD) continue;
      final s = sampleCourseAt(d);
      final isMud = s.terrainType == CyclocrossTerrainType.deepMud;
      final leftBase = s.leftEdge - s.lateralRight * 0.18;
      final rightBase = s.rightEdge + s.lateralRight * 0.18;

      final primaryTape = isMud
          ? const Color(0xFFEF4444)
          : const Color(0xFFF59E0B);
      const secondaryTape = Color(0xFFF3F4F6);

      posts.add(
        CourseTapePost3D(
          distanceMeters: d,
          isRightSide: false,
          basePosition: leftBase,
          topPosition: leftBase + s.normal * 1.05,
          postColor: const Color(0xFF8B5A2B),
          tapeColorPrimary: primaryTape,
          tapeColorSecondary: secondaryTape,
        ),
      );
      posts.add(
        CourseTapePost3D(
          distanceMeters: d,
          isRightSide: true,
          basePosition: rightBase,
          topPosition: rightBase + s.normal * 1.05,
          postColor: const Color(0xFF8B5A2B),
          tapeColorPrimary: primaryTape,
          tapeColorSecondary: secondaryTape,
        ),
      );
    }

    // 2. Drewniane belki do przeskakiwania (para belek co 220m, wokół d%220 == 86 & 91)
    final planks = <CyclocrossWoodenPlankBarrier3D>[];
    final baseCycle = (startD / 220.0).floor() * 220.0;
    for (double cycle = baseCycle; cycle <= endD; cycle += 220.0) {
      for (int i = 0; i < 2; i++) {
        final d = cycle + 86.0 + i * 5.5;
        if (d < startD || d > endD) continue;
        final s = sampleCourseAt(d);
        final leftFoot = s.leftEdge;
        final rightFoot = s.rightEdge;
        planks.add(
          CyclocrossWoodenPlankBarrier3D(
            barrierIndex: i + 1,
            distanceMeters: d,
            heightMeters: 0.40,
            leftFoot: leftFoot,
            rightFoot: rightFoot,
            leftTop: leftFoot + s.normal * 0.40,
            rightTop: rightFoot + s.normal * 0.40,
            isBunnyHoppable: true,
          ),
        );
      }
    }

    // 3. Schody przełajowe (d%220 w [60, 74])
    final staircases = <CyclocrossStaircaseRunUp3D>[];
    for (double cycle = baseCycle; cycle <= endD; cycle += 220.0) {
      final sStart = cycle + 60.0;
      final sEnd = cycle + 74.0;
      if (sEnd < startD || sStart > endD) continue;
      const stepCount = 16;
      final leftEdges = <Vector3>[];
      final rightEdges = <Vector3>[];
      for (int i = 0; i <= stepCount; i++) {
        final d = sStart + (sEnd - sStart) * (i / stepCount);
        final s = sampleCourseAt(d);
        leftEdges.add(s.leftEdge);
        rightEdges.add(s.rightEdge);
      }
      staircases.add(
        CyclocrossStaircaseRunUp3D(
          startDistanceMeters: sStart,
          endDistanceMeters: sEnd,
          stepCount: stepCount,
          totalRiseMeters: 3.4,
          stepLeftEdges: leftEdges,
          stepRightEdges: rightEdges,
        ),
      );
    }

    // 4. Ławica piasku nad morzem (styl Koksijde/Zonhoven, d%220 w [106, 150])
    final sandPits = <CyclocrossCoastalSandPit3D>[];
    if (config.showCoastalSandAndSea && config.stylePreset.hasCoastalSea) {
      for (double cycle = baseCycle; cycle <= endD; cycle += 220.0) {
        final sStart = cycle + 106.0;
        final sEnd = cycle + 150.0;
        if (sEnd < startD || sStart > endD) continue;
        final leftDune = <Vector3>[];
        final rightDune = <Vector3>[];
        final grass = <Vector3>[];
        for (int i = 0; i <= 10; i++) {
          final d = sStart + (sEnd - sStart) * (i / 10.0);
          final s = sampleCourseAt(d);
          final duneH = 1.6 + math.sin(i * 0.7) * 0.8;
          leftDune.add(s.leftEdge - s.lateralRight * 3.8 + s.normal * duneH);
          rightDune.add(s.rightEdge + s.lateralRight * 4.2 + s.normal * (duneH + 0.5));
          if (i.isEven) {
            grass.add(s.leftEdge - s.lateralRight * 2.4 + s.normal * (duneH * 0.6));
            grass.add(s.rightEdge + s.lateralRight * 2.8 + s.normal * (duneH * 0.7));
          }
        }
        sandPits.add(
          CyclocrossCoastalSandPit3D(
            startDistanceMeters: sStart,
            endDistanceMeters: sEnd,
            sandDepthCm: config.stylePreset.defaultSandDepthCm,
            leftDuneCrest: leftDune,
            rightDuneCrest: rightDune,
            marramGrassTufts: grass,
          ),
        );
      }
    }

    // 5. Namioty z frytkami i kibicami
    final tents = <CyclocrossFritesTentAndSpectators3D>[];
    if (config.showFritesTentsAndSpectators) {
      for (double cycle = baseCycle; cycle <= endD; cycle += 220.0) {
        final tentPositions = <(double, bool, String, Color)>[
          (cycle + 34.0, true, 'FRIETEN • BIER', const Color(0xFFDC2626)),
          (cycle + 95.0, false, 'CX VIP • FRITES', const Color(0xFFD4AF37)),
        ];
        int idx = 0;
        for (final entry in tentPositions) {
          idx++;
          final d = entry.$1;
          if (d < startD || d > endD) continue;
          final s = sampleCourseAt(d);
          final sideSign = entry.$2 ? 1.0 : -1.0;
          final baseCenter = s.center +
              s.lateralRight * (sideSign * (s.halfWidthMeters + 3.6));

          final spectators = <CyclocrossSpectator3D>[];
          for (int k = 0; k < 7; k++) {
            final sd = d - 4.5 + k * 1.6;
            final ss = sampleCourseAt(sd);
            final specPos = ss.center +
                ss.lateralRight *
                    (sideSign * (ss.halfWidthMeters + 0.65 + (k % 2) * 0.35));
            spectators.add(
              CyclocrossSpectator3D(
                position: specPos,
                jacketColor: _spectatorJacketPalette[k % _spectatorJacketPalette.length],
                beanieColor: k.isEven ? AppColors.goldAccent : AppColors.crimsonAlert,
                hasFlag: k == 1 || k == 5,
                flagColors: k == 1
                    ? const [Color(0xFF181B22), Color(0xFFFACC15), Color(0xFFEF4444)]
                    : const [Color(0xFFAE1C28), Color(0xFFF3F4F6), Color(0xFF21468B)],
                phaseOffset: k * 0.8 + timeSeconds * 3.2,
                hasCowbell: k == 2 || k == 4,
              ),
            );
          }

          tents.add(
            CyclocrossFritesTentAndSpectators3D(
              tentId: idx,
              signText: entry.$3,
              baseCenter: baseCenter,
              tangent: s.tangent,
              lateralRight: s.lateralRight,
              widthMeters: 5.0,
              depthMeters: 3.4,
              heightMeters: 3.1,
              awningPrimaryColor: entry.$4,
              awningSecondaryColor: const Color(0xFFF3F4F6),
              nearbySpectators: spectators,
            ),
          );
        }
      }
    }

    // 6. Boks techniczny z mechanikami trzymającymi zapasowe rowery (d%220 w [154, 184])
    final pitBoxes = <CyclocrossPitBoxAndMechanics3D>[];
    if (config.showDoublePitBox) {
      for (double cycle = baseCycle; cycle <= endD; cycle += 220.0) {
        final sStart = cycle + 154.0;
        final sEnd = cycle + 184.0;
        if (sEnd < startD || sStart > endD) continue;
        final mechanics = <CyclocrossPitMechanic3D>[];
        const teamCodes = ['ALPECIN', 'BALOISE', 'PAUWELS', 'VISMA'];
        const teamColors = [
          Color(0xFF1E3A8A),
          Color(0xFFEF4444),
          Color(0xFF10B981),
          Color(0xFFFACC15),
        ];

        for (int i = 0; i < 4; i++) {
          final md = sStart + 4.0 + i * 6.8;
          final ms = sampleCourseAt(md);
          final mPos = ms.rightEdge + ms.lateralRight * 1.1;
          mechanics.add(
            CyclocrossPitMechanic3D(
              boxIndex: i + 1,
              teamCode: teamCodes[i],
              position: mPos,
              facingDirection: -ms.lateralRight,
              teamColor: teamColors[i],
              spareBikeFrameColor: i.isEven
                  ? AppColors.goldAccent
                  : const Color(0xFF38BDF8),
              holdingSpareBikeReady: true,
              hasPressureWasherSpray: i == 1 || i == 3,
            ),
          );
        }

        final p0 = sampleCourseAt(sStart).rightEdge + sampleCourseAt(sStart).lateralRight * 0.4;
        final p1 = sampleCourseAt(sEnd).rightEdge + sampleCourseAt(sEnd).lateralRight * 0.4;
        final p2 = sampleCourseAt(sEnd).rightEdge + sampleCourseAt(sEnd).lateralRight * 3.4;
        final p3 = sampleCourseAt(sStart).rightEdge + sampleCourseAt(sStart).lateralRight * 3.4;

        pitBoxes.add(
          CyclocrossPitBoxAndMechanics3D(
            startDistanceMeters: sStart,
            endDistanceMeters: sEnd,
            side: CyclocrossPitLaneSide.right,
            mechanics: mechanics,
            pitCanopyCorners: [p0, p1, p2, p3],
          ),
        );
      }
    }

    return _CyclocrossSceneObjects(
      samples: samples,
      posts: posts,
      planks: planks,
      staircases: staircases,
      sandPits: sandPits,
      tents: tents,
      pitBoxes: pitBoxes,
    );
  }

  static const List<Color> _spectatorJacketPalette = [
    Color(0xFF1E293B),
    Color(0xFF8E4A49),
    Color(0xFF0F766E),
    Color(0xFFCA8A04),
    Color(0xFF1D4ED8),
    Color(0xFF475569),
    Color(0xFF991B1B),
  ];

  /// Główna metoda renderująca pełną scenę 3D areny CX na [Canvas].
  Cyclocross3dArenaTelemetry renderFrame({
    required Canvas canvas,
    required Size size,
    required double cameraDistanceMeters,
    required double cameraYawOffsetRadians,
    required double cameraPitchDegrees,
    required double timeSeconds,
    required List<CyclocrossRider3DActor> riders,
  }) {
    if (size.width <= 1.0 || size.height <= 1.0) {
      return Cyclocross3dArenaTelemetry.empty;
    }

    final camSample = sampleCourseAt(cameraDistanceMeters);
    final camPos = camSample.center -
        camSample.tangent * 8.5 +
        camSample.normal * 3.4 +
        camSample.lateralRight * (math.sin(cameraYawOffsetRadians) * 4.5);
    final lookTarget = camSample.center +
        camSample.tangent * 18.0 +
        camSample.normal * 0.8;

    final viewMatrix = makeViewMatrix(
      camPos,
      lookTarget,
      Vector3(0.0, 1.0, 0.0),
    );
    final aspect = size.width / size.height;
    final projMatrix = makePerspectiveMatrix(
      radians(config.fieldOfViewDegrees),
      aspect,
      0.5,
      config.maxDrawDistanceMeters + 60.0,
    );
    final vpMatrix = projMatrix * viewMatrix;

    // 1. Tło nieba zimowego + Morze Północne (styl Koksijde/Zonhoven)
    _paintWinterSkyAndCoastalSea(canvas, size, timeSeconds);

    // 2. Zbuduj obiekty sceny 3D
    final scene = _buildSceneObjects(
      cameraDistanceMeters: cameraDistanceMeters,
      timeSeconds: timeSeconds,
    );

    // 3. Wstęga terenu (błoto, trawa łąkowa, piasek, strefa boksu)
    _paintCourseTerrainRibbon(canvas, size, vpMatrix, scene.samples);

    // 4. Wydmy i ławica piasku Koksijde/Zonhoven
    for (final sand in scene.sandPits) {
      _paintCoastalSandPit(canvas, size, vpMatrix, sand);
    }

    // 5. Schody przełajowe
    for (final stairs in scene.staircases) {
      _paintStaircase(canvas, size, vpMatrix, stairs);
    }

    // 6. Boks techniczny z mechanikami trzymającymi zapasowe rowery
    int mechanicsCount = 0;
    for (final pit in scene.pitBoxes) {
      _paintPitBox(canvas, size, vpMatrix, pit, timeSeconds);
      mechanicsCount += pit.mechanics.length;
    }

    // 7. Namioty z frytkami i kibicami
    int spectatorsCount = 0;
    for (final tent in scene.tents) {
      _paintFritesTentAndSpectators(canvas, size, vpMatrix, tent, timeSeconds);
      spectatorsCount += tent.nearbySpectators.length;
    }

    // 8. Taśmy wyznaczające krętą trasę + słupki
    _paintCourseTapesAndPosts(canvas, size, vpMatrix, scene.posts, timeSeconds);

    // 9. Drewniane belki do przeskakiwania
    for (final plank in scene.planks) {
      _paintWoodenPlankBarrier(canvas, size, vpMatrix, plank);
    }

    // 10. Kolarze 3D (sortowanie od najdalszego + animacja biegu z rowerem na prawym ramieniu)
    final sortedRiders = List<CyclocrossRider3DActor>.from(riders)
      ..sort((a, b) => b.distanceMeters.compareTo(a.distanceMeters));
    int runningCount = 0;
    for (final rider in sortedRiders) {
      if (rider.traversalMode == CyclocrossTraversalMode.dismountAndRun) {
        runningCount++;
      }
      final rSample = sampleCourseAt(rider.distanceMeters);
      final pose = runnerAnimator.evaluatePose(
        actor: rider,
        courseSample: rSample,
      );
      _paintCyclocrossRiderPose(canvas, size, vpMatrix, rider, pose);
    }

    return Cyclocross3dArenaTelemetry(
      visibleCourseSamples: scene.samples.length,
      tapePostsRendered: scene.posts.length,
      woodenPlanksRendered: scene.planks.length,
      staircasesRendered: scene.staircases.length,
      sandPitSectionsRendered: scene.sandPits.length,
      fritesTentsRendered: scene.tents.length,
      spectatorsRendered: spectatorsCount,
      pitMechanicsRendered: mechanicsCount,
      runningShoulderCarryRiders: runningCount,
      cameraDistanceMeters: cameraDistanceMeters,
    );
  }

  _Projected2D _project(Vector3 world, Size size, Matrix4 vpMatrix) {
    final v = Vector4(world.x, world.y, world.z, 1.0);
    vpMatrix.transform(v);
    if (v.w <= 0.15) {
      return const _Projected2D(Offset.zero, -1.0, false);
    }
    final ndcX = v.x / v.w;
    final ndcY = v.y / v.w;
    final sx = (ndcX + 1.0) * 0.5 * size.width;
    final sy = (1.0 - ndcY) * 0.5 * size.height;
    return _Projected2D(Offset(sx, sy), v.w, true);
  }

  void _paintWinterSkyAndCoastalSea(
    Canvas canvas,
    Size size,
    double timeSeconds,
  ) {
    final horizonY = size.height * 0.36;
    final skyRect = Rect.fromLTWH(0, 0, size.width, horizonY);
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: config.stylePreset.hasCoastalSea
          ? const [Color(0xFF131B26), Color(0xFF28384A), Color(0xFF475B70)]
          : const [Color(0xFF11151C), Color(0xFF1F2633), Color(0xFF333D4D)],
    );
    canvas.drawRect(skyRect, Paint()..shader = skyGradient.createShader(skyRect));

    if (config.stylePreset.hasCoastalSea && config.showCoastalSandAndSea) {
      // Pas Morza Północnego na horyzoncie (styl Koksijde)
      final seaRect = Rect.fromLTWH(0, horizonY - 12, size.width, 28);
      final seaPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF1E3A4C), Color(0xFF2B5268), Color(0xFF1B3444)],
        ).createShader(seaRect);
      canvas.drawRect(seaRect, seaPaint);

      // Białe grzebienie fal
      final wavePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..strokeWidth = 1.4;
      for (int i = 0; i < 6; i++) {
        final wy = horizonY - 4 + i * 3.5;
        final shift = ((timeSeconds * 18.0 + i * 47.0) % size.width);
        canvas.drawLine(
          Offset(shift - 26, wy),
          Offset(shift + 26, wy),
          wavePaint,
        );
      }
    }

    // Podłoże zimowej łąki / wybrzeża
    final groundRect =
        Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY);
    final groundColor = config.stylePreset.hasCoastalSea
        ? const [Color(0xFF262D22), Color(0xFF1A1E17)]
        : const [Color(0xFF1E261C), Color(0xFF141812)];
    canvas.drawRect(
      groundRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: groundColor,
        ).createShader(groundRect),
    );
  }

  void _paintCourseTerrainRibbon(
    Canvas canvas,
    Size size,
    Matrix4 vpMatrix,
    List<CyclocrossCourseSample3D> samples,
  ) {
    for (int i = samples.length - 2; i >= 0; i--) {
      final s0 = samples[i];
      final s1 = samples[i + 1];
      final l0 = _project(s0.leftEdge, size, vpMatrix);
      final r0 = _project(s0.rightEdge, size, vpMatrix);
      final l1 = _project(s1.leftEdge, size, vpMatrix);
      final r1 = _project(s1.rightEdge, size, vpMatrix);
      if (!l0.isVisible || !r0.isVisible || !l1.isVisible || !r1.isVisible) {
        continue;
      }

      final path = Path()
        ..moveTo(l0.offset.dx, l0.offset.dy)
        ..lineTo(r0.offset.dx, r0.offset.dy)
        ..lineTo(r1.offset.dx, r1.offset.dy)
        ..lineTo(l1.offset.dx, l1.offset.dy)
        ..close();

      final color = _terrainRibbonColor(s0.terrainType);
      canvas.drawPath(path, Paint()..color = color);

      // Koleiny błotne / piaskowe wewnątrz wstęgi trasy
      if (s0.terrainType == CyclocrossTerrainType.deepMud ||
          s0.terrainType == CyclocrossTerrainType.sandPit) {
        final rutL0 = _project(
          s0.center - s0.lateralRight * 0.45,
          size,
          vpMatrix,
        );
        final rutL1 = _project(
          s1.center - s1.lateralRight * 0.45,
          size,
          vpMatrix,
        );
        final rutR0 = _project(
          s0.center + s0.lateralRight * 0.45,
          size,
          vpMatrix,
        );
        final rutR1 = _project(
          s1.center + s1.lateralRight * 0.45,
          size,
          vpMatrix,
        );
        if (rutL0.isVisible && rutL1.isVisible) {
          canvas.drawLine(
            rutL0.offset,
            rutL1.offset,
            Paint()
              ..color = Colors.black.withValues(alpha: 0.28 * config.mudWetnessFactor)
              ..strokeWidth = (4.5 / (rutL0.depthW * 0.08 + 1.0)).clamp(1.0, 5.0),
          );
        }
        if (rutR0.isVisible && rutR1.isVisible) {
          canvas.drawLine(
            rutR0.offset,
            rutR1.offset,
            Paint()
              ..color = Colors.black.withValues(alpha: 0.25 * config.mudWetnessFactor)
              ..strokeWidth = (4.0 / (rutR0.depthW * 0.08 + 1.0)).clamp(1.0, 4.5),
          );
        }
      }
    }
  }

  Color _terrainRibbonColor(CyclocrossTerrainType terrain) {
    switch (terrain) {
      case CyclocrossTerrainType.deepMud:
        return Color.lerp(
          const Color(0xFF4A3525),
          const Color(0xFF2B1D13),
          config.mudWetnessFactor,
        )!;
      case CyclocrossTerrainType.sandPit:
        return const Color(0xFFC8A96E);
      case CyclocrossTerrainType.meadowGrass:
        return const Color(0xFF3E5A2E);
      case CyclocrossTerrainType.staircaseRunUp:
        return const Color(0xFF52483F);
      case CyclocrossTerrainType.doublePitLane:
        return const Color(0xFF3B4252);
      case CyclocrossTerrainType.planks:
        return const Color(0xFF4F3E2F);
      case CyclocrossTerrainType.offCamberSlope:
        return const Color(0xFF4B4730);
      case CyclocrossTerrainType.pavedStartFinish:
        return const Color(0xFF2A2F3D);
      case CyclocrossTerrainType.woodlandSingletrack:
        return const Color(0xFF3A2F24);
    }
  }

  void _paintCoastalSandPit(
    Canvas canvas,
    Size size,
    Matrix4 vpMatrix,
    CyclocrossCoastalSandPit3D sand,
  ) {
    final dunePaint = Paint()
      ..color = const Color(0xFFD9BE82).withValues(alpha: 0.78)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < sand.leftDuneCrest.length - 1; i++) {
      final p0 = _project(sand.leftDuneCrest[i], size, vpMatrix);
      final p1 = _project(sand.leftDuneCrest[i + 1], size, vpMatrix);
      if (p0.isVisible && p1.isVisible) {
        final path = Path()
          ..moveTo(p0.offset.dx - 24, p0.offset.dy + 20)
          ..lineTo(p0.offset.dx, p0.offset.dy)
          ..lineTo(p1.offset.dx, p1.offset.dy)
          ..lineTo(p1.offset.dx - 24, p1.offset.dy + 20)
          ..close();
        canvas.drawPath(path, dunePaint);
      }

      final r0 = _project(sand.rightDuneCrest[i], size, vpMatrix);
      final r1 = _project(sand.rightDuneCrest[i + 1], size, vpMatrix);
      if (r0.isVisible && r1.isVisible) {
        final path = Path()
          ..moveTo(r0.offset.dx + 24, r0.offset.dy + 20)
          ..lineTo(r0.offset.dx, r0.offset.dy)
          ..lineTo(r1.offset.dx, r1.offset.dy)
          ..lineTo(r1.offset.dx + 24, r1.offset.dy + 20)
          ..close();
        canvas.drawPath(path, dunePaint);
      }
    }

    // Kępy trawy wydmowej (piaskownica / marram grass)
    final grassPaint = Paint()
      ..color = const Color(0xFF6B7F46)
      ..strokeWidth = 1.6;
    for (final tuft in sand.marramGrassTufts) {
      final pt = _project(tuft, size, vpMatrix);
      if (!pt.isVisible) continue;
      final s = (18.0 / (pt.depthW * 0.1 + 1.0)).clamp(3.0, 14.0);
      canvas.drawLine(pt.offset, pt.offset + Offset(-s * 0.4, -s), grassPaint);
      canvas.drawLine(pt.offset, pt.offset + Offset(0, -s * 1.15), grassPaint);
      canvas.drawLine(pt.offset, pt.offset + Offset(s * 0.4, -s * 0.9), grassPaint);
    }
  }

  void _paintStaircase(
    Canvas canvas,
    Size size,
    Matrix4 vpMatrix,
    CyclocrossStaircaseRunUp3D stairs,
  ) {
    for (int i = stairs.stepLeftEdges.length - 1; i > 0; i--) {
      final l0 = _project(stairs.stepLeftEdges[i - 1], size, vpMatrix);
      final r0 = _project(stairs.stepRightEdges[i - 1], size, vpMatrix);
      final l1 = _project(stairs.stepLeftEdges[i], size, vpMatrix);
      final r1 = _project(stairs.stepRightEdges[i], size, vpMatrix);
      if (!l0.isVisible || !r0.isVisible || !l1.isVisible || !r1.isVisible) {
        continue;
      }
      final stepPath = Path()
        ..moveTo(l0.offset.dx, l0.offset.dy)
        ..lineTo(r0.offset.dx, r0.offset.dy)
        ..lineTo(r1.offset.dx, r1.offset.dy)
        ..lineTo(l1.offset.dx, l1.offset.dy)
        ..close();
      canvas.drawPath(
        stepPath,
        Paint()
          ..color = i.isEven ? const Color(0xFF786858) : const Color(0xFF5D5044),
      );
      canvas.drawLine(
        l1.offset,
        r1.offset,
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: 0.45)
          ..strokeWidth = 1.2,
      );
    }
  }

  void _paintCourseTapesAndPosts(
    Canvas canvas,
    Size size,
    Matrix4 vpMatrix,
    List<CourseTapePost3D> posts,
    double timeSeconds,
  ) {
    final leftPosts = posts.where((p) => !p.isRightSide).toList();
    final rightPosts = posts.where((p) => p.isRightSide).toList();

    for (final sideList in [leftPosts, rightPosts]) {
      for (int i = sideList.length - 1; i >= 0; i--) {
        final p = sideList[i];
        final base2d = _project(p.basePosition, size, vpMatrix);
        final top2d = _project(p.topPosition, size, vpMatrix);
        if (base2d.isVisible && top2d.isVisible) {
          final w = (10.0 / (base2d.depthW * 0.1 + 1.0)).clamp(1.2, 4.5);
          canvas.drawLine(
            base2d.offset,
            top2d.offset,
            Paint()
              ..color = p.postColor
              ..strokeWidth = w,
          );
        }

        if (i > 0) {
          final prev = sideList[i - 1];
          final flutter =
              math.sin(timeSeconds * 4.5 + p.distanceMeters) * 0.04;
          final prevTop = _project(
            prev.topPosition + Vector3(0, flutter, 0),
            size,
            vpMatrix,
          );
          if (top2d.isVisible && prevTop.isVisible) {
            final tapeW = (6.0 / (top2d.depthW * 0.12 + 1.0)).clamp(1.2, 4.2);
            canvas.drawLine(
              prevTop.offset,
              top2d.offset,
              Paint()
                ..color = i.isEven ? p.tapeColorPrimary : p.tapeColorSecondary
                ..strokeWidth = tapeW,
            );
          }
        }
      }
    }
  }

  void _paintWoodenPlankBarrier(
    Canvas canvas,
    Size size,
    Matrix4 vpMatrix,
    CyclocrossWoodenPlankBarrier3D plank,
  ) {
    final lf = _project(plank.leftFoot, size, vpMatrix);
    final rf = _project(plank.rightFoot, size, vpMatrix);
    final lt = _project(plank.leftTop, size, vpMatrix);
    final rt = _project(plank.rightTop, size, vpMatrix);
    if (!lf.isVisible || !rf.isVisible || !lt.isVisible || !rt.isVisible) {
      return;
    }

    final boardPath = Path()
      ..moveTo(lf.offset.dx, lf.offset.dy)
      ..lineTo(rf.offset.dx, rf.offset.dy)
      ..lineTo(rt.offset.dx, rt.offset.dy)
      ..lineTo(lt.offset.dx, lt.offset.dy)
      ..close();

    canvas.drawPath(boardPath, Paint()..color = const Color(0xFFB45309));
    // Pasy ostrzegawcze na belce
    const stripes = 6;
    for (int i = 0; i < stripes; i += 2) {
      final t0 = i / stripes;
      final t1 = (i + 1) / stripes;
      final b0 = Offset.lerp(lf.offset, rf.offset, t0)!;
      final b1 = Offset.lerp(lf.offset, rf.offset, t1)!;
      final u0 = Offset.lerp(lt.offset, rt.offset, t0)!;
      final u1 = Offset.lerp(lt.offset, rt.offset, t1)!;
      final stripePath = Path()
        ..moveTo(b0.dx, b0.dy)
        ..lineTo(b1.dx, b1.dy)
        ..lineTo(u1.dx, u1.dy)
        ..lineTo(u0.dx, u0.dy)
        ..close();
      canvas.drawPath(stripePath, Paint()..color = const Color(0xFFF3F4F6));
    }
    canvas.drawPath(
      boardPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _paintFritesTentAndSpectators(
    Canvas canvas,
    Size size,
    Matrix4 vpMatrix,
    CyclocrossFritesTentAndSpectators3D tent,
    double timeSeconds,
  ) {
    final halfW = tent.widthMeters * 0.5;
    final halfD = tent.depthMeters * 0.5;
    final up = Vector3(0.0, 1.0, 0.0);

    final c0 = tent.baseCenter - tent.tangent * halfW - tent.lateralRight * halfD;
    final c1 = tent.baseCenter + tent.tangent * halfW - tent.lateralRight * halfD;
    final c2 = tent.baseCenter + tent.tangent * halfW + tent.lateralRight * halfD;
    final c3 = tent.baseCenter - tent.tangent * halfW + tent.lateralRight * halfD;
    final t0 = c0 + up * tent.heightMeters;
    final t1 = c1 + up * tent.heightMeters;
    final apex = tent.baseCenter + up * (tent.heightMeters + 0.85);

    final pC0 = _project(c0, size, vpMatrix);
    final pC1 = _project(c1, size, vpMatrix);
    final pT0 = _project(t0, size, vpMatrix);
    final pT1 = _project(t1, size, vpMatrix);
    final pApex = _project(apex, size, vpMatrix);
    final pC2 = _project(c2, size, vpMatrix);
    final pC3 = _project(c3, size, vpMatrix);

    if (pC0.isVisible &&
        pC1.isVisible &&
        pT0.isVisible &&
        pT1.isVisible &&
        pApex.isVisible) {
      // Ciepłe światło wnętrza namiotu z frytkami
      final wall = Path()
        ..moveTo(pC0.offset.dx, pC0.offset.dy)
        ..lineTo(pC1.offset.dx, pC1.offset.dy)
        ..lineTo(pT1.offset.dx, pT1.offset.dy)
        ..lineTo(pT0.offset.dx, pT0.offset.dy)
        ..close();
      canvas.drawPath(
        wall,
        Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.35),
      );

      // Dach w paski
      final roof = Path()
        ..moveTo(pT0.offset.dx, pT0.offset.dy)
        ..lineTo(pT1.offset.dx, pT1.offset.dy)
        ..lineTo(pApex.offset.dx, pApex.offset.dy)
        ..close();
      canvas.drawPath(roof, Paint()..color = tent.awningPrimaryColor);

      // Para unosząca się znad frytkownicy
      for (int s = 0; s < 3; s++) {
        final drift = ((timeSeconds * 0.7 + s * 0.33) % 1.0);
        final steamPos = apex + up * (0.2 + drift * 1.4) + tent.tangent * (s * 0.4 - 0.4);
        final pSteam = _project(steamPos, size, vpMatrix);
        if (pSteam.isVisible) {
          canvas.drawCircle(
            pSteam.offset,
            (8.0 * (1.0 - drift * 0.4) / (pSteam.depthW * 0.08 + 1.0))
                .clamp(1.5, 9.0),
            Paint()..color = Colors.white.withValues(alpha: 0.22 * (1.0 - drift)),
          );
        }
      }

      // Szyld "FRIETEN • BIER"
      if (pT0.depthW < 75.0) {
        final midTop = (pT0.offset + pT1.offset) * 0.5;
        final textPainter = TextPainter(
          text: TextSpan(
            text: tent.signText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: (11.0 / (pT0.depthW * 0.04 + 1.0)).clamp(6.0, 11.0),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              backgroundColor: AppColors.surface.withValues(alpha: 0.85),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          midTop - Offset(textPainter.width * 0.5, textPainter.height + 2),
        );
      }
    }

    if (pC2.isVisible && pC3.isVisible && pT0.isVisible && pT1.isVisible) {
      canvas.drawLine(
        pC0.offset,
        pT0.offset,
        Paint()
          ..color = const Color(0xFF9CA3AF)
          ..strokeWidth = 1.5,
      );
      canvas.drawLine(
        pC1.offset,
        pT1.offset,
        Paint()
          ..color = const Color(0xFF9CA3AF)
          ..strokeWidth = 1.5,
      );
    }

    // Kibice przy taśmie
    for (final spec in tent.nearbySpectators) {
      _paintSpectator(canvas, size, vpMatrix, spec);
    }
  }

  void _paintSpectator(
    Canvas canvas,
    Size size,
    Matrix4 vpMatrix,
    CyclocrossSpectator3D spec,
  ) {
    final foot = _project(spec.position, size, vpMatrix);
    final head = _project(
      spec.position + Vector3(0.0, 1.65, 0.0),
      size,
      vpMatrix,
    );
    if (!foot.isVisible || !head.isVisible) return;

    final h = (foot.offset.dy - head.offset.dy).abs().clamp(4.0, 68.0);
    final bodyW = h * 0.34;
    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(
          head.offset.dx,
          head.offset.dy + h * 0.45,
        ),
        width: bodyW,
        height: h * 0.48,
      ),
      Radius.circular(bodyW * 0.25),
    );
    canvas.drawRRect(torsoRect, Paint()..color = spec.jacketColor);
    canvas.drawCircle(
      head.offset + Offset(0, h * 0.10),
      (h * 0.11).clamp(1.6, 7.0),
      Paint()..color = spec.beanieColor,
    );

    if (spec.hasFlag && spec.flagColors.isNotEmpty) {
      final wave = math.sin(spec.phaseOffset) * h * 0.14;
      final poleTop = head.offset + Offset(bodyW * 0.7 + wave * 0.3, -h * 0.55);
      canvas.drawLine(
        head.offset + Offset(bodyW * 0.5, h * 0.2),
        poleTop,
        Paint()
          ..color = const Color(0xFFE5E7EB)
          ..strokeWidth = 1.2,
      );
      final flagW = h * 0.42;
      final flagH = h * 0.25;
      final stripeH = flagH / spec.flagColors.length;
      for (int i = 0; i < spec.flagColors.length; i++) {
        canvas.drawRect(
          Rect.fromLTWH(
            poleTop.dx,
            poleTop.dy + i * stripeH,
            flagW,
            stripeH,
          ),
          Paint()..color = spec.flagColors[i],
        );
      }
    }
  }

  void _paintPitBox(
    Canvas canvas,
    Size size,
    Matrix4 vpMatrix,
    CyclocrossPitBoxAndMechanics3D pit,
    double timeSeconds,
  ) {
    if (pit.pitCanopyCorners.length == 4) {
      final pts = pit.pitCanopyCorners
          .map((c) => _project(c, size, vpMatrix))
          .toList();
      if (pts.every((p) => p.isVisible)) {
        final floor = Path()
          ..moveTo(pts[0].offset.dx, pts[0].offset.dy)
          ..lineTo(pts[1].offset.dx, pts[1].offset.dy)
          ..lineTo(pts[2].offset.dx, pts[2].offset.dy)
          ..lineTo(pts[3].offset.dx, pts[3].offset.dy)
          ..close();
        canvas.drawPath(
          floor,
          Paint()..color = AppColors.surfaceLight.withValues(alpha: 0.75),
        );
        canvas.drawPath(
          floor,
          Paint()
            ..color = AppColors.goldAccent.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    for (final mech in pit.mechanics) {
      final foot = _project(mech.position, size, vpMatrix);
      final head = _project(
        mech.position + Vector3(0.0, 1.72, 0.0),
        size,
        vpMatrix,
      );
      if (!foot.isVisible || !head.isVisible) continue;

      final h = (foot.offset.dy - head.offset.dy).abs().clamp(6.0, 74.0);
      final w = h * 0.34;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(head.offset.dx, head.offset.dy + h * 0.45),
            width: w,
            height: h * 0.50,
          ),
          Radius.circular(w * 0.25),
        ),
        Paint()..color = mech.teamColor,
      );
      canvas.drawCircle(
        head.offset + Offset(0, h * 0.1),
        (h * 0.11).clamp(2.0, 7.5),
        Paint()..color = AppColors.textPrimary,
      );

      // Zapasowy rower trzymany przed mechanikiem na wysokości klatki piersiowej
      if (mech.holdingSpareBikeReady) {
        final bikeCenter = mech.position +
            mech.facingDirection * 0.45 +
            Vector3(0.0, 0.92, 0.0);
        final rearW = _project(
          bikeCenter - Vector3(0.0, 0.0, 0.45),
          size,
          vpMatrix,
        );
        final frontW = _project(
          bikeCenter + Vector3(0.0, 0.0, 0.45),
          size,
          vpMatrix,
        );
        if (rearW.isVisible && frontW.isVisible) {
          final wheelR = (h * 0.19).clamp(2.5, 13.0);
          final wheelPaint = Paint()
            ..color = const Color(0xFFE5E7EB)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6;
          canvas.drawCircle(rearW.offset, wheelR, wheelPaint);
          canvas.drawCircle(frontW.offset, wheelR, wheelPaint);
          canvas.drawLine(
            rearW.offset,
            frontW.offset,
            Paint()
              ..color = mech.spareBikeFrameColor
              ..strokeWidth = 2.2,
          );
          canvas.drawLine(
            (rearW.offset + frontW.offset) * 0.5 - Offset(0, wheelR * 0.7),
            frontW.offset - Offset(0, wheelR * 0.75),
            Paint()
              ..color = mech.spareBikeFrameColor
              ..strokeWidth = 2.0,
          );
        }
      }

      // Mgiełka z myjki ciśnieniowej Karcher
      if (mech.hasPressureWasherSpray) {
        final pulse = (math.sin(timeSeconds * 6.0 + mech.boxIndex) + 1.0) * 0.5;
        canvas.drawCircle(
          foot.offset + Offset(w * 0.9, -h * 0.2),
          (h * 0.18 + pulse * 3.0).clamp(2.0, 14.0),
          Paint()..color = AppColors.cyanAccent.withValues(alpha: 0.22),
        );
      }
    }
  }

  void _paintCyclocrossRiderPose(
    Canvas canvas,
    Size size,
    Matrix4 vpMatrix,
    CyclocrossRider3DActor rider,
    CyclocrossShoulderCarryPose3D pose,
  ) {
    final rearAxle = _project(pose.bikeRearAxle, size, vpMatrix);
    final frontAxle = _project(pose.bikeFrontAxle, size, vpMatrix);
    final bb = _project(pose.bikeBottomBracket, size, vpMatrix);
    final seat = _project(pose.bikeSeatCluster, size, vpMatrix);
    final headTube = _project(pose.bikeHeadTubeTop, size, vpMatrix);
    final barR = _project(pose.bikeHandlebarRight, size, vpMatrix);
    final barL = _project(pose.bikeHandlebarLeft, size, vpMatrix);

    final pelvis = _project(pose.pelvis, size, vpMatrix);
    final chest = _project(pose.chest, size, vpMatrix);
    final head = _project(pose.head, size, vpMatrix);
    final lSh = _project(pose.leftShoulder, size, vpMatrix);
    final rSh = _project(pose.rightShoulder, size, vpMatrix);
    final lEl = _project(pose.leftElbow, size, vpMatrix);
    final lHa = _project(pose.leftHand, size, vpMatrix);
    final rEl = _project(pose.rightElbow, size, vpMatrix);
    final rHa = _project(pose.rightHand, size, vpMatrix);
    final lHi = _project(pose.leftHip, size, vpMatrix);
    final lKn = _project(pose.leftKnee, size, vpMatrix);
    final lFo = _project(pose.leftFoot, size, vpMatrix);
    final rHi = _project(pose.rightHip, size, vpMatrix);
    final rKn = _project(pose.rightKnee, size, vpMatrix);
    final rFo = _project(pose.rightFoot, size, vpMatrix);

    if (!pelvis.isVisible || !head.isVisible) return;

    final scale = (1.0 / (pelvis.depthW * 0.08 + 1.0)).clamp(0.18, 1.35);
    final limbW = (4.2 * scale).clamp(1.2, 6.0);
    final frameW = (3.4 * scale).clamp(1.0, 5.0);
    final wheelR = (26.0 * scale).clamp(4.0, 32.0);

    // 1. Nogi kolarza
    final legPaint = Paint()
      ..color = const Color(0xFF1F2937)
      ..strokeWidth = limbW
      ..strokeCap = StrokeCap.round;
    if (lHi.isVisible && lKn.isVisible && lFo.isVisible) {
      canvas.drawLine(lHi.offset, lKn.offset, legPaint);
      canvas.drawLine(lKn.offset, lFo.offset, legPaint);
    }
    if (rHi.isVisible && rKn.isVisible && rFo.isVisible) {
      canvas.drawLine(rHi.offset, rKn.offset, legPaint);
      canvas.drawLine(rKn.offset, rFo.offset, legPaint);
    }

    // 2. Tułów i głowa
    canvas.drawLine(
      pelvis.offset,
      chest.offset,
      Paint()
        ..color = rider.jerseyColor
        ..strokeWidth = limbW * 1.45
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      head.offset,
      (7.5 * scale).clamp(2.2, 10.0),
      Paint()..color = rider.helmetColor,
    );

    // 3. Rower (na prawym ramieniu w trybie dismountAndRun, pod kolarzem w jeździe/bunnyHop)
    if (rearAxle.isVisible &&
        frontAxle.isVisible &&
        bb.isVisible &&
        seat.isVisible &&
        headTube.isVisible) {
      final tirePaint = Paint()
        ..color = const Color(0xFF111827)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (3.2 * scale).clamp(1.0, 4.2);
      final rimPaint = Paint()
        ..color = const Color(0xFFD1D5DB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.3 * scale).clamp(0.6, 2.0);

      canvas.drawCircle(rearAxle.offset, wheelR, tirePaint);
      canvas.drawCircle(rearAxle.offset, wheelR * 0.88, rimPaint);
      canvas.drawCircle(frontAxle.offset, wheelR, tirePaint);
      canvas.drawCircle(frontAxle.offset, wheelR * 0.88, rimPaint);

      final bikePaint = Paint()
        ..color = rider.bikeFrameColor
        ..strokeWidth = frameW
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(rearAxle.offset, bb.offset, bikePaint);
      canvas.drawLine(rearAxle.offset, seat.offset, bikePaint);
      canvas.drawLine(bb.offset, seat.offset, bikePaint);
      canvas.drawLine(seat.offset, headTube.offset, bikePaint);
      canvas.drawLine(bb.offset, headTube.offset, bikePaint);
      canvas.drawLine(headTube.offset, frontAxle.offset, bikePaint);

      if (barR.isVisible && barL.isVisible) {
        canvas.drawLine(
          barL.offset,
          barR.offset,
          Paint()
            ..color = const Color(0xFF374151)
            ..strokeWidth = frameW * 0.85,
        );
      }
    }

    // 4. Ramiona (prawa ręka trzymająca rower na prawym ramieniu / lewa w przeciwfazie)
    final armPaint = Paint()
      ..color = rider.jerseyColor
      ..strokeWidth = limbW * 0.9
      ..strokeCap = StrokeCap.round;
    if (lSh.isVisible && lEl.isVisible && lHa.isVisible) {
      canvas.drawLine(lSh.offset, lEl.offset, armPaint);
      canvas.drawLine(lEl.offset, lHa.offset, armPaint);
    }
    if (rSh.isVisible && rEl.isVisible && rHa.isVisible) {
      canvas.drawLine(rSh.offset, rEl.offset, armPaint);
      canvas.drawLine(rEl.offset, rHa.offset, armPaint);
    }

    // 5. Etykieta zawodnika nad kaskiem
    if (pelvis.depthW < 55.0) {
      final badgeText = rider.traversalMode == CyclocrossTraversalMode.dismountAndRun
          ? '${rider.shortName} • RUN'
          : (rider.traversalMode == CyclocrossTraversalMode.bunnyHop
              ? '${rider.shortName} • HOP'
              : rider.shortName);
      final tp = TextPainter(
        text: TextSpan(
          text: badgeText,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            backgroundColor: AppColors.background.withValues(alpha: 0.78),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        head.offset - Offset(tp.width * 0.5, tp.height + 10.0 * scale),
      );
    }
  }
}

class _CyclocrossSceneObjects {
  final List<CyclocrossCourseSample3D> samples;
  final List<CourseTapePost3D> posts;
  final List<CyclocrossWoodenPlankBarrier3D> planks;
  final List<CyclocrossStaircaseRunUp3D> staircases;
  final List<CyclocrossCoastalSandPit3D> sandPits;
  final List<CyclocrossFritesTentAndSpectators3D> tents;
  final List<CyclocrossPitBoxAndMechanics3D> pitBoxes;

  const _CyclocrossSceneObjects({
    required this.samples,
    required this.posts,
    required this.planks,
    required this.staircases,
    required this.sandPits,
    required this.tents,
    required this.pitBoxes,
  });
}

// =============================================================================
// 5. PAINTER I RESPONSYWNY WIDGET PANELU ARENY PRZEŁAJOWEJ 3D
// =============================================================================

/// Painter Fluttera renderujący klatkę areny przełajowej CX na `CustomPaint`.
class Cyclocross3dArenaPainter extends CustomPainter {
  final Cyclocross3dArenaAndBarriersRenderer renderer;
  final double cameraDistanceMeters;
  final double cameraYawOffsetRadians;
  final double cameraPitchDegrees;
  final double timeSeconds;
  final List<CyclocrossRider3DActor> riders;
  final ValueChanged<Cyclocross3dArenaTelemetry>? onTelemetryUpdated;

  const Cyclocross3dArenaPainter({
    required this.renderer,
    required this.cameraDistanceMeters,
    required this.cameraYawOffsetRadians,
    required this.cameraPitchDegrees,
    required this.timeSeconds,
    required this.riders,
    this.onTelemetryUpdated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final telemetry = renderer.renderFrame(
      canvas: canvas,
      size: size,
      cameraDistanceMeters: cameraDistanceMeters,
      cameraYawOffsetRadians: cameraYawOffsetRadians,
      cameraPitchDegrees: cameraPitchDegrees,
      timeSeconds: timeSeconds,
      riders: riders,
    );
    onTelemetryUpdated?.call(telemetry);
  }

  @override
  bool shouldRepaint(covariant Cyclocross3dArenaPainter oldDelegate) {
    return oldDelegate.cameraDistanceMeters != cameraDistanceMeters ||
        oldDelegate.cameraYawOffsetRadians != cameraYawOffsetRadians ||
        oldDelegate.cameraPitchDegrees != cameraPitchDegrees ||
        oldDelegate.timeSeconds != timeSeconds ||
        oldDelegate.renderer.config.stylePreset !=
            renderer.config.stylePreset ||
        oldDelegate.renderer.config.showCoastalSandAndSea !=
            renderer.config.showCoastalSandAndSea ||
        oldDelegate.renderer.config.showFritesTentsAndSpectators !=
            renderer.config.showFritesTentsAndSpectators ||
        oldDelegate.renderer.config.showDoublePitBox !=
            renderer.config.showDoublePitBox ||
        oldDelegate.riders != riders;
  }
}

/// Pełny, responsywny widget podglądu i sterowania areną 3D kolarstwa przełajowego
/// (LayoutBuilder 390x844 / 1024x768 / 1600x900, paleta AppColors, czcionka Inter).
class Cyclocross3dArenaViewportWidget extends StatefulWidget {
  final CyclocrossCourseAndMudModel? courseModel;
  final Cyclocross3dArenaConfig initialConfig;
  final bool autoAnimate;

  const Cyclocross3dArenaViewportWidget({
    super.key,
    this.courseModel,
    this.initialConfig = const Cyclocross3dArenaConfig(),
    this.autoAnimate = true,
  });

  @override
  State<Cyclocross3dArenaViewportWidget> createState() =>
      _Cyclocross3dArenaViewportWidgetState();
}

class _Cyclocross3dArenaViewportWidgetState
    extends State<Cyclocross3dArenaViewportWidget>
    with SingleTickerProviderStateMixin {
  late Cyclocross3dArenaConfig _config;
  late AnimationController _animController;
  double _cameraDistanceMeters = 48.0;
  final double _cameraYawOffset = 0.12;
  CyclocrossTraversalMode _heroRiderMode =
      CyclocrossTraversalMode.dismountAndRun;
  bool _isPaused = false;
  Cyclocross3dArenaTelemetry _telemetry = Cyclocross3dArenaTelemetry.empty;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
    if (widget.autoAnimate) {
      _animController.repeat();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _animController.stop();
      } else {
        _animController.repeat();
      }
    });
  }

  List<CyclocrossRider3DActor> _buildDemoRiders(double t) {
    final baseDist = _cameraDistanceMeters + 11.5;
    return [
      CyclocrossRider3DActor(
        riderId: 'mvdp',
        shortName: 'VAN DER POEL',
        jerseyColor: const Color(0xFFF3F4F6),
        helmetColor: const Color(0xFF181B22),
        bikeFrameColor: AppColors.primaryAccent,
        distanceMeters: baseDist + 4.0,
        lateralOffsetMeters: -0.35,
        speedMps: 4.3,
        traversalMode: _heroRiderMode,
        animationTimeSeconds: t,
      ),
      CyclocrossRider3DActor(
        riderId: 'wva',
        shortName: 'VAN AERT',
        jerseyColor: AppColors.goldAccent,
        helmetColor: AppColors.crimsonAlert,
        bikeFrameColor: const Color(0xFF38BDF8),
        distanceMeters: baseDist + 1.2,
        lateralOffsetMeters: 0.55,
        speedMps: 4.1,
        traversalMode: CyclocrossTraversalMode.dismountAndRun,
        animationTimeSeconds: t + 0.45,
      ),
      CyclocrossRider3DActor(
        riderId: 'iserbyt',
        shortName: 'ISERBYT',
        jerseyColor: AppColors.crimsonAlert,
        helmetColor: AppColors.textPrimary,
        bikeFrameColor: const Color(0xFF10B981),
        distanceMeters: baseDist - 2.4,
        lateralOffsetMeters: -0.75,
        speedMps: 5.2,
        traversalMode: CyclocrossTraversalMode.rideInSaddle,
        animationTimeSeconds: t + 0.9,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final renderer = Cyclocross3dArenaAndBarriersRenderer(
      config: _config,
      courseModel: widget.courseModel,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720.0;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: isCompact
              ? Column(
                  children: [
                    Expanded(flex: 3, child: _buildViewportCanvas(renderer)),
                    Flexible(
                      flex: 2,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: _buildControlPanelContent(isCompact: true),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 7, child: _buildViewportCanvas(renderer)),
                    Container(
                      width: 320,
                      color: AppColors.surface,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildControlPanelContent(isCompact: false),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildViewportCanvas(Cyclocross3dArenaAndBarriersRenderer renderer) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final t = _animController.value * 24.0;
        final riders = _buildDemoRiders(t);
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: Cyclocross3dArenaPainter(
                renderer: renderer,
                cameraDistanceMeters: _cameraDistanceMeters,
                cameraYawOffsetRadians: _cameraYawOffset,
                cameraPitchDegrees: 14.0,
                timeSeconds: t,
                riders: riders,
                onTelemetryUpdated: (tel) {
                  _telemetry = tel;
                },
              ),
            ),
            if (_config.showTelemetryOverlay)
              Positioned(
                top: 12,
                left: 12,
                child: _ArenaHudBadge(
                  preset: _config.stylePreset,
                  telemetry: _telemetry,
                  heroMode: _heroRiderMode,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildControlPanelContent({required bool isCompact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.terrain_rounded,
              color: AppColors.goldAccent,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Arena Przełajowa CX 3D',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 14 : 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _CxActionButton(
              label: _isPaused ? 'Wznów' : 'Pauza',
              icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              isActive: !_isPaused,
              onPressed: _togglePlayPause,
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Styl Areny',
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
          children: CyclocrossArenaStylePreset.values.map((preset) {
            return _CxActionButton(
              label: preset.shortTag,
              isActive: _config.stylePreset == preset,
              onPressed: () {
                setState(() {
                  _config = _config.copyWith(stylePreset: preset);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        const Text(
          'Animacja Kolarza (Prawa Strona)',
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
          children: [
            _CxActionButton(
              label: 'Bieg z rowerem',
              isActive:
                  _heroRiderMode == CyclocrossTraversalMode.dismountAndRun,
              onPressed: () => setState(
                () => _heroRiderMode = CyclocrossTraversalMode.dismountAndRun,
              ),
            ),
            _CxActionButton(
              label: 'Bunny-Hop',
              isActive: _heroRiderMode == CyclocrossTraversalMode.bunnyHop,
              onPressed: () => setState(
                () => _heroRiderMode = CyclocrossTraversalMode.bunnyHop,
              ),
            ),
            _CxActionButton(
              label: 'Jazda',
              isActive: _heroRiderMode == CyclocrossTraversalMode.rideInSaddle,
              onPressed: () => setState(
                () => _heroRiderMode = CyclocrossTraversalMode.rideInSaddle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Pozycja Kamery na Rundzie: ${_cameraDistanceMeters.toStringAsFixed(0)} m',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Slider(
          value: _cameraDistanceMeters,
          min: 0.0,
          max: 220.0,
          activeColor: AppColors.goldAccent,
          inactiveColor: AppColors.surfaceLight,
          onChanged: (v) => setState(() => _cameraDistanceMeters = v),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _CxActionButton(
              label: 'Frytki & Kibice',
              isActive: _config.showFritesTentsAndSpectators,
              onPressed: () => setState(() {
                _config = _config.copyWith(
                  showFritesTentsAndSpectators:
                      !_config.showFritesTentsAndSpectators,
                );
              }),
            ),
            _CxActionButton(
              label: 'Boks Pit-Lane',
              isActive: _config.showDoublePitBox,
              onPressed: () => setState(() {
                _config = _config.copyWith(
                  showDoublePitBox: !_config.showDoublePitBox,
                );
              }),
            ),
            _CxActionButton(
              label: 'Wydmy & Morze',
              isActive: _config.showCoastalSandAndSea,
              isDisabled: !_config.stylePreset.hasCoastalSea,
              onPressed: () => setState(() {
                _config = _config.copyWith(
                  showCoastalSandAndSea: !_config.showCoastalSandAndSea,
                );
              }),
            ),
          ],
        ),
      ],
    );
  }
}

class _ArenaHudBadge extends StatelessWidget {
  final CyclocrossArenaStylePreset preset;
  final Cyclocross3dArenaTelemetry telemetry;
  final CyclocrossTraversalMode heroMode;

  const _ArenaHudBadge({
    required this.preset,
    required this.telemetry,
    required this.heroMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            preset.labelPl,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tryb: ${heroMode.labelPl} • Słupki: ${telemetry.tapePostsRendered} • Mechanicy: ${telemetry.pitMechanicsRendered}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Przycisk kontrolny z pełnymi stanami hover / active / disabled / focus.
class _CxActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _CxActionButton({
    required this.label,
    required this.isActive,
    required this.onPressed,
    this.icon,
    this.isDisabled = false,
  });

  @override
  State<_CxActionButton> createState() => _CxActionButtonState();
}

class _CxActionButtonState extends State<_CxActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : widget.isActive
            ? AppColors.primaryAccent
            : (_isHovered ? AppColors.surfaceLight : AppColors.background);

    final borderColor = widget.isDisabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : _isFocused
            ? AppColors.goldAccent
            : (widget.isActive
                ? AppColors.goldAccent.withValues(alpha: 0.85)
                : AppColors.cardBorder);

    final textColor = widget.isDisabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: textColor),
                const SizedBox(width: 4),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
