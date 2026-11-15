// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

/// Warianty chwytu kierownicy obsługiwane przez solver kinematyki odwrotnej kończyn górnych.
enum IkGripType {
  /// Górny chwyt na poprzeczce kierownicy (Tops) — wyprostowana pozycja na podjazdach i w spokojnym tempie.
  tops(
    label: 'Górny chwyt (Tops)',
    torsoInclineDegrees: 48.0,
    handX: 0.14,
    handY: 0.68,
    handZ: 0.44,
    elbowOutwardFlare: 0.28,
  ),

  /// Chwyt na klamkomanetkach (Hoods) — standardowa pozycja wyścigowa w peletonie.
  hoods(
    label: 'Klamkomanetki (Hoods)',
    torsoInclineDegrees: 36.0,
    handX: 0.19,
    handY: 0.64,
    handZ: 0.55,
    elbowOutwardFlare: 0.22,
  ),

  /// Dolny chwyt w łukach kierownicy (Drops) — wysokie tempo, pościg, zjazdy i sprint.
  drops(
    label: 'Dolny chwyt (Drops)',
    torsoInclineDegrees: 24.0,
    handX: 0.21,
    handY: 0.52,
    handZ: 0.51,
    elbowOutwardFlare: 0.18,
  ),

  /// Pozycja aerodynamiczna z ugiętymi przedramionami (AeroTuck) — samotna ucieczka lub zjazd aero.
  aeroTuck(
    label: 'Pozycja Aero (AeroTuck)',
    torsoInclineDegrees: 14.0,
    handX: 0.08,
    handY: 0.60,
    handZ: 0.62,
    elbowOutwardFlare: -0.08,
  );

  final String label;

  /// Kąt pochylenia tułowia od poziomu w stopniach (mniejszy kąt = niższa sylwetka aero).
  final double torsoInclineDegrees;

  /// Połowiczny rozstaw dłoni w osi X [m].
  final double handX;

  /// Wysokość dłoni względem środka suportu w osi Y [m].
  final double handY;

  /// Wysunięcie dłoni do przodu względem środka suportu w osi Z [m].
  final double handZ;

  /// Składowa boczna wektora bieguna (pole vector) kierująca łokieć na zewnątrz lub do wewnątrz.
  final double elbowOutwardFlare;

  const IkGripType({
    required this.label,
    required this.torsoInclineDegrees,
    required this.handX,
    required this.handY,
    required this.handZ,
    required this.elbowOutwardFlare,
  });
}

/// Konfiguracja antropometryczna kolarza oraz geometrii korby do obliczeń IK 3D.
class LimbIkGeometryConfig {
  /// Minimalna wspierana długość ramienia korby [mm].
  static const double minCrankLengthMm = 165.0;

  /// Maksymalna wspierana długość ramienia korby [mm].
  static const double maxCrankLengthMm = 175.0;

  /// Długość ramienia korby w milimetrach (zakres 165–175 mm).
  final double crankLengthMm;

  /// Rozstaw pedałów (Q-Factor) w milimetrach (domyślnie 176 mm).
  final double qFactorMm;

  /// Długość kości udowej (biodro -> kolano) [m].
  final double thighLengthMeters;

  /// Długość podudzia (kolano -> kostka) [m].
  final double calfLengthMeters;

  /// Odległość od osi pedału (bloku buta) do stawu skokowego (kostki) [m].
  final double footCleatToAnkleMeters;

  /// Długość ramienia (bark -> łokieć) [m].
  final double upperArmLengthMeters;

  /// Długość przedramienia (łokieć -> nadgarstek/dłoń) [m].
  final double forearmLengthMeters;

  /// Szerokość barków (rozstaw stawów barkowych) [m].
  final double shoulderWidthMeters;

  /// Długość odcinka tułowia (biodro -> bark) [m].
  final double spineLengthMeters;

  /// Wysokość bioder nad środkiem suportu w siodle [m].
  final double saddleHipHeightMeters;

  /// Cofnięcie bioder za środek suportu w siodle [m].
  final double saddleHipSetbackMeters;

  const LimbIkGeometryConfig({
    this.crankLengthMm = 172.5,
    this.qFactorMm = 176.0,
    this.thighLengthMeters = 0.44,
    this.calfLengthMeters = 0.42,
    this.footCleatToAnkleMeters = 0.13,
    this.upperArmLengthMeters = 0.32,
    this.forearmLengthMeters = 0.28,
    this.shoulderWidthMeters = 0.40,
    this.spineLengthMeters = 0.48,
    this.saddleHipHeightMeters = 0.66,
    this.saddleHipSetbackMeters = 0.16,
  });

  /// Długość korby przycięta do regulaminowego przedziału [165.0, 175.0] mm.
  double get clampedCrankLengthMm =>
      crankLengthMm.clamp(minCrankLengthMm, maxCrankLengthMm);

  /// Długość korby w metrach.
  double get crankLengthMeters => clampedCrankLengthMm / 1000.0;

  /// Połowa rozstawu pedałów (Q-Factor / 2) w metrach.
  double get qFactorHalfMeters => (qFactorMm.clamp(140.0, 210.0) / 1000.0) * 0.5;

  /// Połowa szerokości barków w metrach.
  double get shoulderHalfWidthMeters => shoulderWidthMeters * 0.5;

  LimbIkGeometryConfig copyWith({
    double? crankLengthMm,
    double? qFactorMm,
    double? thighLengthMeters,
    double? calfLengthMeters,
    double? footCleatToAnkleMeters,
    double? upperArmLengthMeters,
    double? forearmLengthMeters,
    double? shoulderWidthMeters,
    double? spineLengthMeters,
    double? saddleHipHeightMeters,
    double? saddleHipSetbackMeters,
  }) {
    return LimbIkGeometryConfig(
      crankLengthMm: crankLengthMm ?? this.crankLengthMm,
      qFactorMm: qFactorMm ?? this.qFactorMm,
      thighLengthMeters: thighLengthMeters ?? this.thighLengthMeters,
      calfLengthMeters: calfLengthMeters ?? this.calfLengthMeters,
      footCleatToAnkleMeters:
          footCleatToAnkleMeters ?? this.footCleatToAnkleMeters,
      upperArmLengthMeters: upperArmLengthMeters ?? this.upperArmLengthMeters,
      forearmLengthMeters: forearmLengthMeters ?? this.forearmLengthMeters,
      shoulderWidthMeters: shoulderWidthMeters ?? this.shoulderWidthMeters,
      spineLengthMeters: spineLengthMeters ?? this.spineLengthMeters,
      saddleHipHeightMeters:
          saddleHipHeightMeters ?? this.saddleHipHeightMeters,
      saddleHipSetbackMeters:
          saddleHipSetbackMeters ?? this.saddleHipSetbackMeters,
    );
  }
}

/// Dane wejściowe dla pojedynczej klatki solvera kinematyki odwrotnej 3D.
class LimbIkFrameInput {
  /// Kąt obrotu prawej korby w radianach ($\theta \in [0, 2\pi)$, gdzie $0$ to godzina 12:00).
  final double crankAngleRadians;

  /// Opcjonalne nadpisanie długości korby w milimetrach (165–175 mm).
  final double? crankLengthMm;

  /// Aktualny chwyt kierownicy wpływający na pochylenie tułowia i ugięcie łokci.
  final IkGripType grip;

  /// Współczynnik jazdy na stojąco $[0.0, 1.0]$ ($0$ = w siodle, $1$ = taniec na pedałach).
  final double standingProgress;

  /// Aktualna kadencja w obrotach na minutę [RPM] (wpływa na dynamiczne ugięcie kostki).
  final double cadenceRpm;

  /// Kąt kołysania ramy na boki podczas jazdy na stojąco [stopnie].
  final double bikeSwayDegrees;

  const LimbIkFrameInput({
    required this.crankAngleRadians,
    this.crankLengthMm,
    this.grip = IkGripType.hoods,
    this.standingProgress = 0.0,
    this.cadenceRpm = 90.0,
    this.bikeSwayDegrees = 0.0,
  });
}

/// Wynik dwustawowego rozwiązania IK dla pojedynczej kończyny w przestrzeni 3D.
class SolvedTwoBoneLimb {
  /// Pozycja stawu początkowego (biodro lub bark) [m].
  final Vector3 rootPosition;

  /// Pozycja stawu pośredniego (kolano lub łokieć) [m].
  final Vector3 midJointPosition;

  /// Pozycja punktu końcowego (kostka lub dłoń) [m].
  final Vector3 targetPosition;

  /// Kąt zgięcia w stawie pośrednim w stopniach ($0^\circ$ = pełny wyprost, $90^\circ$ = kąt prosty).
  final double flexionDegrees;

  const SolvedTwoBoneLimb({
    required this.rootPosition,
    required this.midJointPosition,
    required this.targetPosition,
    required this.flexionDegrees,
  });
}

/// Kompletny zestaw pozycji stawów kończyn dolnych i górnych wyliczony w danej klatce.
class LimbIkFrameResult {
  /// Znormalizowany kąt prawej korby $\theta \in [0, 2\pi)$ [rad].
  final double normalizedCrankAngleRadians;

  /// Znormalizowany kąt lewej korby $(\theta + \pi) \bmod 2\pi$ [rad].
  final double leftCrankAngleRadians;

  /// Zastosowana długość korby po przycięciu do zakresu 165–175 mm [mm].
  final double crankLengthMm;

  /// Aktywny chwyt kierownicy.
  final IkGripType grip;

  /// Kąt pochylenia tułowia od poziomu [stopnie].
  final double torsoInclineDegrees;

  /// Centralna pozycja miednicy [m].
  final Vector3 pelvisCenterPosition;

  /// Pozycje stawów biodrowych [m].
  final Vector3 rightHipPosition;
  final Vector3 leftHipPosition;

  /// Pozycje osi pedałów [m].
  final Vector3 rightPedalPosition;
  final Vector3 leftPedalPosition;

  /// Pozycje stawów skokowych (kostek) [m].
  final Vector3 rightAnklePosition;
  final Vector3 leftAnklePosition;

  /// Pozycje kolan wyliczone przez 2-stawowy solver IK [m].
  final Vector3 rightKneePosition;
  final Vector3 leftKneePosition;

  /// Kąt ugięcia prawego i lewego kolana [stopnie].
  final double rightKneeFlexionDegrees;
  final double leftKneeFlexionDegrees;

  /// Pozycje stawów barkowych [m].
  final Vector3 rightShoulderPosition;
  final Vector3 leftShoulderPosition;

  /// Pozycje łokci wyliczone przez 2-stawowy solver IK [m].
  final Vector3 rightElbowPosition;
  final Vector3 leftElbowPosition;

  /// Pozycje dłoni na kierownicy [m].
  final Vector3 rightHandPosition;
  final Vector3 leftHandPosition;

  /// Kąt ugięcia prawego i lewego łokcia w zadanym chwycie [stopnie].
  final double rightElbowFlexionDegrees;
  final double leftElbowFlexionDegrees;

  const LimbIkFrameResult({
    required this.normalizedCrankAngleRadians,
    required this.leftCrankAngleRadians,
    required this.crankLengthMm,
    required this.grip,
    required this.torsoInclineDegrees,
    required this.pelvisCenterPosition,
    required this.rightHipPosition,
    required this.leftHipPosition,
    required this.rightPedalPosition,
    required this.leftPedalPosition,
    required this.rightAnklePosition,
    required this.leftAnklePosition,
    required this.rightKneePosition,
    required this.leftKneePosition,
    required this.rightKneeFlexionDegrees,
    required this.leftKneeFlexionDegrees,
    required this.rightShoulderPosition,
    required this.leftShoulderPosition,
    required this.rightElbowPosition,
    required this.leftElbowPosition,
    required this.rightHandPosition,
    required this.leftHandPosition,
    required this.rightElbowFlexionDegrees,
    required this.leftElbowFlexionDegrees,
  });
}

/// Dwustawowy analityczny solver kinematyki odwrotnej 3D (Analytical 2-Bone IK)
/// dla kończyn dolnych i górnych kolarza.
///
/// Układ współrzędnych (lokalny układ roweru ze środkiem w osi suportu `[0, 0, 0]` w metrach):
/// - `X`: oś poprzeczna (+X = prawa strona, -X = lewa strona)
/// - `Y`: oś pionowa (+Y = góra)
/// - `Z`: oś wzdłużna (+Z = kierunek jazdy do przodu)
class InverseKinematicsLimbSolver {
  static const double _twoPi = 2.0 * math.pi;
  static const double _radToDeg = 180.0 / math.pi;
  static const double _degToRad = math.pi / 180.0;

  /// Domyślna konfiguracja geometrii i antropometrii kolarza.
  final LimbIkGeometryConfig defaultConfig;

  const InverseKinematicsLimbSolver({
    this.defaultConfig = const LimbIkGeometryConfig(),
  });

  /// Normalizuje dowolny kąt w radianach do przedziału $[0, 2\pi)$.
  static double normalizeAngleRadians(double angleRadians) {
    if (!angleRadians.isFinite) {
      return 0.0;
    }
    final double wrapped = angleRadians % _twoPi;
    return wrapped < 0.0 ? wrapped + _twoPi : wrapped;
  }

  /// Wylicza kompletny stan stawów nóg (kolana, kostki) i rąk (łokcie, barki, dłonie)
  /// dla pojedynczej klatki animacji 3D.
  LimbIkFrameResult solveFrame(LimbIkFrameInput input) {
    final LimbIkGeometryConfig config = input.crankLengthMm != null
        ? defaultConfig.copyWith(crankLengthMm: input.crankLengthMm)
        : defaultConfig;

    final double thetaRight = normalizeAngleRadians(input.crankAngleRadians);
    final double thetaLeft = normalizeAngleRadians(thetaRight + math.pi);
    final double standing = input.standingProgress.clamp(0.0, 1.0);
    final double cadence = input.cadenceRpm.isFinite
        ? input.cadenceRpm.clamp(0.0, 180.0)
        : 90.0;

    // 1. Pozycje pedałów dla korby o długości 165-175 mm
    final double crankLen = config.crankLengthMeters;
    final double qHalf = config.qFactorHalfMeters;

    final Vector3 rightPedal = Vector3(
      qHalf,
      crankLen * math.cos(thetaRight),
      crankLen * math.sin(thetaRight),
    );
    final Vector3 leftPedal = Vector3(
      -qHalf,
      crankLen * math.cos(thetaLeft),
      crankLen * math.sin(thetaLeft),
    );

    // 2. Pozycje kostek z uwzględnieniem naturalnej pracy stawu skokowego (ankling)
    final Vector3 rightAnkle = computeAnklePosition(
      pedalPosition: rightPedal,
      crankAngleRadians: thetaRight,
      standingProgress: standing,
      cadenceRpm: cadence,
      footCleatToAnkleMeters: config.footCleatToAnkleMeters,
    );
    final Vector3 leftAnkle = computeAnklePosition(
      pedalPosition: leftPedal,
      crankAngleRadians: thetaLeft,
      standingProgress: standing,
      cadenceRpm: cadence,
      footCleatToAnkleMeters: config.footCleatToAnkleMeters,
    );

    // 3. Pozycja miednicy i stawów biodrowych
    final double hipY = config.saddleHipHeightMeters + (standing * 0.10);
    final double hipZ = -config.saddleHipSetbackMeters + (standing * 0.14);
    final double hipLateralShift =
        -math.sin(thetaRight) * 0.025 * standing;
    final Vector3 pelvisCenter = Vector3(hipLateralShift, hipY, hipZ);

    final double hipHalfSpan = qHalf * 0.85;
    final Vector3 rightHip = pelvisCenter + Vector3(hipHalfSpan, 0.0, 0.0);
    final Vector3 leftHip = pelvisCenter - Vector3(hipHalfSpan, 0.0, 0.0);

    // 4. Dwustawowe IK 3D nóg (biodro -> kolano -> kostka)
    final SolvedTwoBoneLimb rightLeg = solveLeg2BoneIk(
      hipPosition: rightHip,
      anklePosition: rightAnkle,
      thighLengthMeters: config.thighLengthMeters,
      calfLengthMeters: config.calfLengthMeters,
      isRight: true,
    );
    final SolvedTwoBoneLimb leftLeg = solveLeg2BoneIk(
      hipPosition: leftHip,
      anklePosition: leftAnkle,
      thighLengthMeters: config.thighLengthMeters,
      calfLengthMeters: config.calfLengthMeters,
      isRight: false,
    );

    // 5. Pozycje barków i dłoni oraz dwustawowe IK 3D rąk (bark -> łokieć -> dłoń)
    // Podczas jazdy na stojąco tułów lekko się prostuje dla stabilizacji chwytu.
    final double effectiveTorsoInclineDeg =
        input.grip.torsoInclineDegrees + (standing * 6.0);
    final double torsoRad = effectiveTorsoInclineDeg * _degToRad;
    final double swayLateral =
        math.sin(input.bikeSwayDegrees * _degToRad) * 0.04;

    final Vector3 shoulderCenter = Vector3(
      pelvisCenter.x + swayLateral,
      pelvisCenter.y + (config.spineLengthMeters * math.sin(torsoRad)),
      pelvisCenter.z + (config.spineLengthMeters * math.cos(torsoRad)),
    );

    final double shoulderHalf = config.shoulderHalfWidthMeters;
    final Vector3 rightShoulder =
        shoulderCenter + Vector3(shoulderHalf, 0.0, 0.0);
    final Vector3 leftShoulder =
        shoulderCenter - Vector3(shoulderHalf, 0.0, 0.0);

    final Vector3 rightHand = Vector3(
      input.grip.handX,
      input.grip.handY,
      input.grip.handZ,
    );
    final Vector3 leftHand = Vector3(
      -input.grip.handX,
      input.grip.handY,
      input.grip.handZ,
    );

    final SolvedTwoBoneLimb rightArm = solveArm2BoneIk(
      shoulderPosition: rightShoulder,
      handPosition: rightHand,
      grip: input.grip,
      upperArmLengthMeters: config.upperArmLengthMeters,
      forearmLengthMeters: config.forearmLengthMeters,
      isRight: true,
    );
    final SolvedTwoBoneLimb leftArm = solveArm2BoneIk(
      shoulderPosition: leftShoulder,
      handPosition: leftHand,
      grip: input.grip,
      upperArmLengthMeters: config.upperArmLengthMeters,
      forearmLengthMeters: config.forearmLengthMeters,
      isRight: false,
    );

    return LimbIkFrameResult(
      normalizedCrankAngleRadians: thetaRight,
      leftCrankAngleRadians: thetaLeft,
      crankLengthMm: config.clampedCrankLengthMm,
      grip: input.grip,
      torsoInclineDegrees: effectiveTorsoInclineDeg,
      pelvisCenterPosition: pelvisCenter,
      rightHipPosition: rightHip,
      leftHipPosition: leftHip,
      rightPedalPosition: rightPedal,
      leftPedalPosition: leftPedal,
      rightAnklePosition: rightAnkle,
      leftAnklePosition: leftAnkle,
      rightKneePosition: rightLeg.midJointPosition,
      leftKneePosition: leftLeg.midJointPosition,
      rightKneeFlexionDegrees: rightLeg.flexionDegrees,
      leftKneeFlexionDegrees: leftLeg.flexionDegrees,
      rightShoulderPosition: rightShoulder,
      leftShoulderPosition: leftShoulder,
      rightElbowPosition: rightArm.midJointPosition,
      leftElbowPosition: leftArm.midJointPosition,
      rightHandPosition: rightHand,
      leftHandPosition: leftHand,
      rightElbowFlexionDegrees: rightArm.flexionDegrees,
      leftElbowFlexionDegrees: leftArm.flexionDegrees,
    );
  }

  /// Wylicza pozycję stawu skokowego (kostki) względem osi pedału z uwzględnieniem
  /// biomechaniki pracy stopy (ankling) w funkcji kąta korby $\theta \in [0, 2\pi)$.
  static Vector3 computeAnklePosition({
    required Vector3 pedalPosition,
    required double crankAngleRadians,
    double standingProgress = 0.0,
    double cadenceRpm = 90.0,
    double footCleatToAnkleMeters = 0.13,
  }) {
    final double theta = normalizeAngleRadians(crankAngleRadians);
    final double standing = standingProgress.clamp(0.0, 1.0);
    final double cadenceFactor = (cadenceRpm.clamp(40.0, 140.0) - 40.0) / 100.0;

    // Kąt pochylenia stopy względem poziomu (dodatni = pięta uniesiona nad osią pedału).
    // W okolicach godziny 3:00 (pi/2) pięta lekko opada, w fazie ciągnięcia (3*pi/2) unosi się.
    final double basePitchRad = (24.0 + standing * 8.0) * _degToRad;
    final double dynamicSweepRad =
        (9.0 + cadenceFactor * 4.0) * _degToRad * (-math.sin(theta - 0.35));
    final double footPitchRad =
        (basePitchRad + dynamicSweepRad).clamp(5.0 * _degToRad, 55.0 * _degToRad);

    // Kostka znajduje się za blokiem buta (-Z) oraz ponad osią pedału (+Y).
    final double ankleY =
        pedalPosition.y + (footCleatToAnkleMeters * math.sin(footPitchRad));
    final double ankleZ =
        pedalPosition.z - (footCleatToAnkleMeters * math.cos(footPitchRad));

    return Vector3(pedalPosition.x, ankleY, ankleZ);
  }

  /// Rozwiązuje dwustawową kinematykę odwrotną 3D nogi (biodro -> kolano -> kostka).
  ///
  /// Kieruje staw kolanowy do przodu (`+Z`) z naturalnym lekkim odwiedzeniem bocznym (Q-Angle).
  static SolvedTwoBoneLimb solveLeg2BoneIk({
    required Vector3 hipPosition,
    required Vector3 anklePosition,
    double thighLengthMeters = 0.44,
    double calfLengthMeters = 0.42,
    required bool isRight,
  }) {
    // Wektor bieguna kieruje kolano w przód (+Z) i lekko na zewnątrz (±X)
    final Vector3 poleHint = Vector3(isRight ? 0.14 : -0.14, 0.12, 1.0);
    return _solveTwoBoneAnalytic3D(
      root: hipPosition,
      target: anklePosition,
      length1: thighLengthMeters,
      length2: calfLengthMeters,
      poleHint: poleHint,
    );
  }

  /// Rozwiązuje dwustawową kinematykę odwrotną 3D ręki (bark -> łokieć -> dłoń)
  /// dla zadanego chwytu (`Tops`, `Hoods`, `Drops`, `AeroTuck`).
  static SolvedTwoBoneLimb solveArm2BoneIk({
    required Vector3 shoulderPosition,
    required Vector3 handPosition,
    required IkGripType grip,
    double upperArmLengthMeters = 0.32,
    double forearmLengthMeters = 0.28,
    required bool isRight,
  }) {
    final double sideSign = isRight ? 1.0 : -1.0;

    // Wektor bieguna kieruje łokieć w tył (-Z), w dół (-Y) oraz bocznie zgodnie z chwytem.
    final Vector3 poleHint = switch (grip) {
      IkGripType.tops =>
        Vector3(sideSign * grip.elbowOutwardFlare, -0.45, -0.85),
      IkGripType.hoods =>
        Vector3(sideSign * grip.elbowOutwardFlare, -0.60, -0.80),
      IkGripType.drops =>
        Vector3(sideSign * grip.elbowOutwardFlare, -0.75, -0.65),
      IkGripType.aeroTuck =>
        Vector3(sideSign * grip.elbowOutwardFlare, -0.95, -0.35),
    };

    return _solveTwoBoneAnalytic3D(
      root: shoulderPosition,
      target: handPosition,
      length1: upperArmLengthMeters,
      length2: forearmLengthMeters,
      poleHint: poleHint,
    );
  }

  /// Analityczny solver 2-stawowy w pełnym 3D wykorzystujący twierdzenie cosinusów
  /// oraz ortogonalizację Grama-Schmidta wektora bieguna.
  static SolvedTwoBoneLimb _solveTwoBoneAnalytic3D({
    required Vector3 root,
    required Vector3 target,
    required double length1,
    required double length2,
    required Vector3 poleHint,
  }) {
    final double l1 = math.max(0.01, length1);
    final double l2 = math.max(0.01, length2);

    final Vector3 toTarget = target - root;
    final double rawDistance = toTarget.length;

    // Bezpieczny przedział osiągalności ramienia dwuczłonowego
    final double minReach = (l1 - l2).abs() + 0.002;
    final double maxReach = (l1 + l2) - 0.002;
    final double d = rawDistance.clamp(minReach, maxReach);

    final Vector3 dir = rawDistance > 1e-6
        ? toTarget / rawDistance
        : Vector3(0.0, -1.0, 0.0);

    // Ortogonalizacja wektora bieguna względem osi root -> target
    Vector3 bendNormal = poleHint - (dir * poleHint.dot(dir));
    if (bendNormal.length2 < 1e-8) {
      // Awaryjny wektor prostopadły w razie kolinearności
      final Vector3 fallback =
          dir.z.abs() < 0.9 ? Vector3(0.0, 0.0, 1.0) : Vector3(1.0, 0.0, 0.0);
      bendNormal = fallback - (dir * fallback.dot(dir));
    }
    bendNormal.normalize();

    // Twierdzenie cosinusów dla kąta przy stawie początkowym (alpha)
    final double cosAlpha =
        ((l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d)).clamp(-1.0, 1.0);
    final double sinAlpha = math.sqrt(math.max(0.0, 1.0 - cosAlpha * cosAlpha));

    final Vector3 midJoint =
        root + (dir * (l1 * cosAlpha)) + (bendNormal * (l1 * sinAlpha));

    // Twierdzenie cosinusów dla kąta wewnętrznego stawu pośredniego (beta)
    final double cosBeta =
        ((l1 * l1 + l2 * l2 - d * d) / (2.0 * l1 * l2)).clamp(-1.0, 1.0);
    final double interiorAngleDeg = math.acos(cosBeta) * _radToDeg;
    final double flexionDegrees = (180.0 - interiorAngleDeg).clamp(0.0, 180.0);

    return SolvedTwoBoneLimb(
      rootPosition: root,
      midJointPosition: midJoint,
      targetPosition: target,
      flexionDegrees: flexionDegrees,
    );
  }
}
