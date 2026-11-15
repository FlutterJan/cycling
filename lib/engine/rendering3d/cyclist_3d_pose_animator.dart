// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

/// Dostępne warianty chwytu kierownicy szosowej lub czasowej.
enum HandlebarGrip {
  /// Górny chwyt na klamkomanetkach (Hoods) – standardowa jazda w peletonie, dobra widoczność i kontrola.
  hoods(
    label: 'Klamkomanetki (Hoods)',
    torsoInclineDegrees: 36.0,
    headPitchDegrees: 12.0,
  ),

  /// Dolny chwyt w łukach kierownicy (Drops) – wysokie tempo, pościgi, zjazdy i sprint z pełną sztywnością.
  drops(
    label: 'Dolny Chwyt (Drops)',
    torsoInclineDegrees: 24.0,
    headPitchDegrees: 18.0,
  ),

  /// Chwyt aerodynamiczny z przedramionami opartymi na kierownicy (Aero "Puppy Paws") – samotna ucieczka.
  aeroPuppyPaws(
    label: 'Aero Przedramiona (Puppy Paws)',
    torsoInclineDegrees: 16.0,
    headPitchDegrees: 22.0,
  ),

  /// Lemondka czasowa (TT Extensions) – jazda na czas, wyprostowane przedramiona na wysięgnikach, kask łezka.
  ttExtensions(
    label: 'Lemondka Czasowa (TT Extensions)',
    torsoInclineDegrees: 9.0,
    headPitchDegrees: 24.0,
  );

  final String label;

  /// Kąt pochylenia tułowia od poziomu w stopniach (mniejszy kąt = bardziej płaska sylwetka aero).
  final double torsoInclineDegrees;

  /// Kąt uniesienia głowy w stopniach pozwalający obserwować szosę przy pochylonym tułowiu.
  final double headPitchDegrees;

  const HandlebarGrip({
    required this.label,
    required this.torsoInclineDegrees,
    required this.headPitchDegrees,
  });
}

/// Dostępne postawy ciała kolarza na rowerze.
enum RidingPosture {
  /// Spokojna lub szybka jazda w siodle (Seated pedalling).
  seated('W siodle'),

  /// Taniec na pedałach na podjeździe (Standing climb out of saddle).
  standingClimb('Taniec na pedałach'),

  /// Agresywny sprint z maksymalną mocą beztlenową (>800W) (Full-gas sprint).
  standingSprint('Sprint na stojąco'),

  /// Aerodynamiczny zjazd na górnej rurze (Aero descent tuck).
  superTuck('Zjazd aero'),

  /// Sięganie ręką po bidon do koszyka w ramie (Drinking bidon).
  drinkingBidon('Picie z bidonu'),

  /// Podniesienie rąk w geście zwycięstwa na linii mety (Victory salute).
  victorySalute('Triumf na mecie');

  final String label;

  const RidingPosture(this.label);
}

/// Dane telemetryczne kolarza przekazywane z silnika fizyki do animatora w każdej klatce.
class CyclistTelemetryInput {
  /// Unikalny identyfikator zawodnika.
  final String riderId;

  /// Aktualna prędkość w m/s (np. 12.5 m/s = 45 km/h).
  final double speedMs;

  /// Aktualna generowana moc w watach [W].
  final int powerWatts;

  /// Kadencja pedałowania w obrotach na minutę [RPM] (np. 85-110 RPM).
  final int cadenceRpm;

  /// Nachylenie drogi w procentach [%] (dodatnie = podjazd, ujemne = zjazd).
  final double gradientPercent;

  /// Promień skrętu drogi w metrach [m] (dodatni = w prawo, ujemny = w lewo, inf = prosta).
  final double turningRadiusMeters;

  /// Czy kolarz jedzie na stojąco poza siodłem (jeśli null, wyliczane automatycznie z mocy i nachylenia).
  final bool? isStanding;

  /// Czy kolarz wykonuje maksymalny sprint finiszowy.
  final bool isSprinting;

  /// Czy kolarz jedzie agresywnym atakiem z ucieczki.
  final bool isAttacking;

  /// Czy etap jest jazdą indywidualną na czas (użycie lemondki TT).
  final bool isTimeTrial;

  /// Czy kolarz wykonuje animację sięgania po bidon.
  final bool isDrinking;

  /// Czy kolarz właśnie wygrał etap i unosi ręce na kresce.
  final bool hasWonStage;

  /// Wymuszony chwyt kierownicy (jeśli null, dobierany automatycznie z kontekstu taktycznego).
  final HandlebarGrip? overrideGrip;

  const CyclistTelemetryInput({
    required this.riderId,
    required this.speedMs,
    required this.powerWatts,
    required this.cadenceRpm,
    this.gradientPercent = 0.0,
    this.turningRadiusMeters = double.infinity,
    this.isStanding,
    this.isSprinting = false,
    this.isAttacking = false,
    this.isTimeTrial = false,
    this.isDrinking = false,
    this.hasWonStage = false,
    this.overrideGrip,
  });

  /// Prędkość w kilometrach na godzinę [km/h].
  double get speedKmh => speedMs * 3.6;
}

/// Pełna, wyliczona w danej klatce animacji (60/120 FPS) postawa kolarza i geometria roweru.
class AnimatedCyclistPose3D {
  /// Identyfikator animowanego kolarza.
  final String riderId;

  /// Kąt obrotu korby i prawego pedału w radianach $[0, 2\pi)$ (0 = godzina 12:00, $\pi/2$ = 3:00 dół napędowy).
  final double crankAngleRadians;

  /// Kąt lewego pedału w radianach (przesunięty o $\pi$ względem prawego).
  final double leftCrankAngleRadians;

  /// Prędkość kątowa obrotu korby w radianach na sekundę [rad/s].
  final double crankAngularVelocity;

  /// Kąt obrotu kół roweru w radianach (wynikający z przebytej drogi $v \cdot dt / R_{koła}$).
  final double wheelRotationAngleRadians;

  /// Kąt pochylenia roweru w zakręcie w stopniach [stopnie] (z prawa fizyki $\arctan(v^2 / (R \cdot g))$).
  final double bikeLeanAngleDegrees;

  /// Kąt kołysania roweru na boki podczas jazdy na stojąco w stopniach [stopnie] (Bike Sway).
  final double bikeSwayAngleDegrees;

  /// Kąt przeciw-pochylenia tułowia kolarza równoważący środek ciężkości [stopnie].
  final double riderCounterLeanAngleDegrees;

  /// Całkowity kąt przechyłu bocznego ramy roweru (Roll = Lean + Sway) [stopnie].
  final double totalBikeRollDegrees;

  /// Kąt pochylenia tułowia od poziomu szosy [stopnie] (Torso Incline).
  final double torsoInclineDegrees;

  /// Kąt uniesienia głowy w osi pionowej [stopnie] (Head Pitch).
  final double headPitchDegrees;

  /// Aktualny wariant chwytu kierownicy.
  final HandlebarGrip grip;

  /// Aktualna postawa ciała kolarza.
  final RidingPosture posture;

  /// Współczynnik stania w pedałach $[0.0, 1.0]$ (płynna interpolacja siodło <-> stojąco).
  final double standingProgress;

  // Koordynaty stawów ciała kolarza w układzie lokalnym roweru (względem środka suportu [0, 0, 0] w metrach)
  /// Pozycja prawego pedału / bloku buta $(X, Y, Z)$ [m].
  final Vector3 rightPedalPosition;

  /// Pozycja lewego pedału / bloku buta $(X, Y, Z)$ [m].
  final Vector3 leftPedalPosition;

  /// Pozycja prawego kolana wyliczona z kinematyki odwrotnej (IK) $(X, Y, Z)$ [m].
  final Vector3 rightKneePosition;

  /// Pozycja lewego kolana wyliczona z kinematyki odwrotnej (IK) $(X, Y, Z)$ [m].
  final Vector3 leftKneePosition;

  /// Pozycja miednicy / bioder kolarza $(X, Y, Z)$ [m].
  final Vector3 hipPosition;

  /// Pozycja klatki piersiowej $(X, Y, Z)$ [m].
  final Vector3 chestPosition;

  /// Pozycja głowy / kasku kolarza $(X, Y, Z)$ [m].
  final Vector3 headPosition;

  /// Pozycja prawej dłoni na kierownicy $(X, Y, Z)$ [m].
  final Vector3 rightHandPosition;

  /// Pozycja lewej dłoni na kierownicy $(X, Y, Z)$ [m].
  final Vector3 leftHandPosition;

  /// Pełna macierz transformacji obrotowej ramy roweru w przestrzeni 3D.
  final Matrix4 bikeRotationMatrix;

  const AnimatedCyclistPose3D({
    required this.riderId,
    required this.crankAngleRadians,
    required this.leftCrankAngleRadians,
    required this.crankAngularVelocity,
    required this.wheelRotationAngleRadians,
    required this.bikeLeanAngleDegrees,
    required this.bikeSwayAngleDegrees,
    required this.riderCounterLeanAngleDegrees,
    required this.totalBikeRollDegrees,
    required this.torsoInclineDegrees,
    required this.headPitchDegrees,
    required this.grip,
    required this.posture,
    required this.standingProgress,
    required this.rightPedalPosition,
    required this.leftPedalPosition,
    required this.rightKneePosition,
    required this.leftKneePosition,
    required this.hipPosition,
    required this.chestPosition,
    required this.headPosition,
    required this.rightHandPosition,
    required this.leftHandPosition,
    required this.bikeRotationMatrix,
  });
}

/// Klasa wyliczająca w każdej klatce (60/120 FPS) dokładną pozę kolarza i roweru na podstawie telemetrii.
///
/// Implementuje:
/// 1. Płynne całkowanie obrotu korby na podstawie bieżącej kadencji ($\theta(t) = \int \omega dt$).
/// 2. Fizyczny kąt pochylenia roweru w zakrętach: $\phi = \arctan(v^2 / (r \cdot g))$.
/// 3. Kołysanie roweru na boki (Bike Sway) w tańcu na pedałach i sprincie (>800W) w fazie z ruchem nóg.
/// 4. Zmienną aerodynamikę tułowia i rąk w zależności od chwytu (klamkomanetki, dolny chwyt, puppy paws, lemondka).
/// 5. Kinematykę odwrotną 2-stawową (Analytical IK) dla ugięcia i pracy kolan kolarza.
class Cyclist3DPoseAnimator {
  // Stałe wymiarowe roweru i anatomii kolarza World Tour
  static const double _crankLengthMeters = 0.1725; // Korba 172.5 mm
  static const double _pedalQFactorHalfMeters = 0.088; // Połowa rozstawu pedałów (Q-Factor ~176 mm)
  static const double _thighLengthMeters = 0.44; // Długość uda kolarza [m]
  static const double _calfLengthMeters = 0.42; // Długość podudzia z butem [m]
  static const double _wheelRadiusMeters = 0.334; // Koło 700c z oponą 28mm (~668 mm średnicy)

  // Bieżące stany fazowe podtrzymywane między klatkami
  double _crankAngleRadians = 0.0;
  double _wheelRotationRadians = 0.0;
  double _smoothedLeanAngleDegrees = 0.0;
  double _standingProgress = 0.0; // 0.0 = w siodle, 1.0 = pełny taniec na stojąco
  double _gripProgress = 1.0;

  HandlebarGrip _currentGrip = HandlebarGrip.hoods;
  HandlebarGrip _targetGrip = HandlebarGrip.hoods;

  Cyclist3DPoseAnimator({
    double initialCrankAngle = 0.0,
    HandlebarGrip initialGrip = HandlebarGrip.hoods,
  })  : _crankAngleRadians = initialCrankAngle,
        _currentGrip = initialGrip,
        _targetGrip = initialGrip;

  // ===========================================================================
  // GŁÓWNA METODA AKTUALIZACJI POZY (UPDATE FRAME 60/120 FPS)
  // ===========================================================================

  /// Oblicza i generuje pełną trójwymiarową pozę kolarza dla kroku czasowego [dtSeconds].
  AnimatedCyclistPose3D update(double dtSeconds, CyclistTelemetryInput telemetry) {
    final double safeDt = dtSeconds.clamp(0.001, 0.1);

    // 1. OBRÓT KORBY I PEDAŁÓW (Crank Angle Integration)
    // Kadencja w RPM przeliczana na prędkość kątową omega: w = (cadence * 2pi) / 60
    final double cadence = (telemetry.cadenceRpm > 5)
        ? telemetry.cadenceRpm.toDouble()
        : (telemetry.speedMs > 2.0 ? 82.0 : 0.0);

    final double crankAngularVel = (cadence * 2.0 * math.pi) / 60.0;
    _crankAngleRadians = (_crankAngleRadians + (crankAngularVel * safeDt)) % (2.0 * math.pi);
    final double leftCrankAngle = (_crankAngleRadians + math.pi) % (2.0 * math.pi);

    // Obrót kół roweru wynikający z prędkości postępowej: delta_angle = (v * dt) / r_wheel
    final double wheelAngularVel = telemetry.speedMs / _wheelRadiusMeters;
    _wheelRotationRadians = (_wheelRotationRadians + (wheelAngularVel * safeDt)) % (2.0 * math.pi);

    // 2. KĄT POCHYLENIA ROWERU W ZAKRĘCIE (Centripetal Cornering Lean)
    final double targetLeanDegrees = calculateCorneringLeanAngleDegrees(
      speedMs: telemetry.speedMs,
      turningRadiusMeters: telemetry.turningRadiusMeters,
    );
    // Wygładzanie przechyłu w łuku (filtr inercyjny zawieszenia i masy kolarza)
    final double leanLerp = (safeDt * 6.5).clamp(0.0, 1.0);
    _smoothedLeanAngleDegrees += (targetLeanDegrees - _smoothedLeanAngleDegrees) * leanLerp;

    // 3. POSTAWA I CHWYT KIEROWNICY (Posture & Grip Evaluation)
    final resolvedGrip = telemetry.overrideGrip ?? _resolveHandlebarGrip(telemetry);
    if (resolvedGrip != _targetGrip) {
      _targetGrip = resolvedGrip;
      _gripProgress = 0.0;
    }
    _gripProgress = (_gripProgress + (safeDt * 3.5)).clamp(0.0, 1.0);
    if (_gripProgress >= 1.0) {
      _currentGrip = _targetGrip;
    }

    final posture = _resolveRidingPosture(telemetry);
    final bool targetStanding = (posture == RidingPosture.standingClimb || posture == RidingPosture.standingSprint);
    final double targetStandingVal = targetStanding ? 1.0 : 0.0;
    final double standingLerp = (safeDt * 5.0).clamp(0.0, 1.0);
    _standingProgress += (targetStandingVal - _standingProgress) * standingLerp;

    // 4. KOŁYSANIE ROWERU NA BOKI (Bike Sway w tańcu na pedałach i sprincie >800W)
    final double bikeSwayDegrees = calculateBikeSwayAngleDegrees(
      crankAngleRadians: _crankAngleRadians,
      powerWatts: telemetry.powerWatts,
      standingProgress: _standingProgress,
      isSprinting: telemetry.isSprinting || telemetry.powerWatts >= 800,
    );

    // Przeciw-pochylenie tułowia kolarza (Rider Counter-Lean)
    // Gdy rower przechyla się w lewo, kolarz odchyla tułów w prawo, utrzymując środek ciężkości nad oponami
    final double riderCounterLean = -bikeSwayDegrees * 0.72;

    // Łączny kąt przechyłu ramy (Roll)
    final double totalBikeRoll = _smoothedLeanAngleDegrees + bikeSwayDegrees;

    // 5. KĄTY TUŁOWIA I GŁOWY (Torso & Head Pitch)
    final double baseTorsoIncline = _interpolateGripTorsoIncline(_currentGrip, _targetGrip, _gripProgress);
    final double baseHeadPitch = _interpolateGripHeadPitch(_currentGrip, _targetGrip, _gripProgress);

    // Modyfikacja kąta tułowia przy jeździe na stojąco
    final double effectiveTorsoIncline = baseTorsoIncline + (_standingProgress * 12.0);

    // 6. GEOMETRIA STAWÓW I KINEMATYKA ODWROTNA (IK) NÓG I TUŁOWIA
    final positions = _calculateSkeletonPositions(
      crankAngle: _crankAngleRadians,
      leftCrankAngle: leftCrankAngle,
      standingProgress: _standingProgress,
      torsoInclineDegrees: effectiveTorsoIncline,
      headPitchDegrees: baseHeadPitch,
      grip: _targetGrip,
      posture: posture,
      bikeSwayDegrees: bikeSwayDegrees,
    );

    // 7. MACIERZ TRANSFORMACJI RAMY ROWERU (World / Local Model Matrix)
    final bikeRollRad = totalBikeRoll * math.pi / 180.0;
    final bikeRotationMatrix = Matrix4.identity()..setRotationZ(bikeRollRad);

    return AnimatedCyclistPose3D(
      riderId: telemetry.riderId,
      crankAngleRadians: _crankAngleRadians,
      leftCrankAngleRadians: leftCrankAngle,
      crankAngularVelocity: crankAngularVel,
      wheelRotationAngleRadians: _wheelRotationRadians,
      bikeLeanAngleDegrees: _smoothedLeanAngleDegrees,
      bikeSwayAngleDegrees: bikeSwayDegrees,
      riderCounterLeanAngleDegrees: riderCounterLean,
      totalBikeRollDegrees: totalBikeRoll,
      torsoInclineDegrees: effectiveTorsoIncline,
      headPitchDegrees: baseHeadPitch,
      grip: _targetGrip,
      posture: posture,
      standingProgress: _standingProgress,
      rightPedalPosition: positions.rightPedal,
      leftPedalPosition: positions.leftPedal,
      rightKneePosition: positions.rightKnee,
      leftKneePosition: positions.leftKnee,
      hipPosition: positions.hip,
      chestPosition: positions.chest,
      headPosition: positions.head,
      rightHandPosition: positions.rightHand,
      leftHandPosition: positions.leftHand,
      bikeRotationMatrix: bikeRotationMatrix,
    );
  }

  /// Resetuje stan kątowy animatora do wartości początkowych.
  void reset({double initialCrankAngle = 0.0, HandlebarGrip initialGrip = HandlebarGrip.hoods}) {
    _crankAngleRadians = initialCrankAngle;
    _wheelRotationRadians = 0.0;
    _smoothedLeanAngleDegrees = 0.0;
    _standingProgress = 0.0;
    _gripProgress = 1.0;
    _currentGrip = initialGrip;
    _targetGrip = initialGrip;
  }

  // ===========================================================================
  // STATYCZNE FORMULARZE FIZYCZNE I KINEMATYCZNE
  // ===========================================================================

  /// Wylicza fizyczny kąt pochylenia roweru w łuku na podstawie przyspieszenia dośrodkowego:
  ///
  /// $$\phi = \arctan\left(\frac{v^2}{R \cdot g}\right)$$
  ///
  /// Zwraca kąt w stopniach $[-45^\circ, +45^\circ]$ (dodatni = w prawo, ujemny = w lewo).
  static double calculateCorneringLeanAngleDegrees({
    required double speedMs,
    required double turningRadiusMeters,
    double maxLeanDegrees = 44.0,
  }) {
    if (turningRadiusMeters.isInfinite || turningRadiusMeters.abs() >= 100000.0 || speedMs < 0.5) {
      return 0.0;
    }

    const double g = 9.80665; // Przyspieszenie ziemskie [m/s^2]
    final double safeR = (turningRadiusMeters.abs() < 1.0)
        ? (turningRadiusMeters >= 0 ? 1.0 : -1.0)
        : turningRadiusMeters;

    final double speedSq = speedMs * speedMs;
    final double tanPhi = speedSq / (safeR.abs() * g);
    final double angleDeg = (math.atan(tanPhi) * 180.0 / math.pi).clamp(0.0, maxLeanDegrees);

    return (safeR >= 0) ? angleDeg : -angleDeg;
  }

  /// Wylicza kąt kołysania roweru na boki (Bike Sway) podczas jazdy na stojąco w górach i w sprincie.
  ///
  /// Kolarz pedałujący na stojąco naciska pedał w dół (np. prawy przy kącie $\pi/2$), przechylając
  /// rower w stronę przeciwną (w lewo). Kołysanie jest zsynchronizowane z obrotem korby:
  ///
  /// $$\phi_{\text{sway}} = A \cdot \sin(\theta - \frac{\pi}{2})$$
  ///
  /// Amplituda $A$ rośnie proporcjonalnie do generowanej mocy:
  /// - Spokojna wspinaczka: $\sim 4^\circ - 6^\circ$,
  /// - Agresywny sprint ($>800\,\text{W}$): $\sim 9^\circ - 13.5^\circ$.
  static double calculateBikeSwayAngleDegrees({
    required double crankAngleRadians,
    required int powerWatts,
    required double standingProgress,
    required bool isSprinting,
  }) {
    if (standingProgress <= 0.01) {
      // W siodle występuje jedynie minimalne naturalne mikrodociążenie (~0.6 stopnia)
      final double microAmp = (powerWatts > 450) ? 0.8 : 0.4;
      return math.sin(crankAngleRadians * 2.0) * microAmp;
    }

    // Wyznaczenie amplitudy kołysania w oparciu o waty i sprint
    double baseAmplitude;
    if (isSprinting || powerWatts >= 800) {
      final double sprintFactor = ((powerWatts - 800) / 600.0).clamp(0.0, 1.0);
      baseAmplitude = 9.0 + (sprintFactor * 4.5); // 9.0° do 13.5°
    } else {
      final double climbFactor = ((powerWatts - 300) / 400.0).clamp(0.0, 1.0);
      baseAmplitude = 4.2 + (climbFactor * 3.3); // 4.2° do 7.5°
    }

    // Faza kołysania: maksymalny przechył następuje w fazie nacisku pionowego na pedał
    final double swayPhase = crankAngleRadians - (math.pi * 0.5);
    final double rawSway = math.sin(swayPhase) * baseAmplitude;

    return rawSway * standingProgress;
  }

  // ===========================================================================
  // DOBÓR CHWYTU I POSTAWY CIAŁA NA BAZIE TELEMETRII
  // ===========================================================================

  HandlebarGrip _resolveHandlebarGrip(CyclistTelemetryInput telemetry) {
    if (telemetry.isTimeTrial) {
      return HandlebarGrip.ttExtensions;
    }
    if (telemetry.isSprinting || telemetry.speedMs > 16.5) { // > 60 km/h lub sprint
      return HandlebarGrip.drops;
    }
    if (telemetry.isAttacking && telemetry.speedMs > 13.0) {
      return HandlebarGrip.aeroPuppyPaws;
    }
    if (telemetry.gradientPercent < -3.0 && telemetry.speedMs > 14.0) { // Szybki zjazd
      return HandlebarGrip.drops;
    }
    return HandlebarGrip.hoods;
  }

  RidingPosture _resolveRidingPosture(CyclistTelemetryInput telemetry) {
    if (telemetry.hasWonStage) {
      return RidingPosture.victorySalute;
    }
    if (telemetry.isDrinking) {
      return RidingPosture.drinkingBidon;
    }
    if (telemetry.isSprinting || telemetry.powerWatts >= 850) {
      return RidingPosture.standingSprint;
    }
    // Wykrywanie tańca na pedałach na podjazdach
    final bool explicitStanding = telemetry.isStanding ?? false;
    final bool autoStandingClimb = (telemetry.gradientPercent >= 7.5 && telemetry.powerWatts >= 420 && telemetry.speedMs < 6.5);

    if (explicitStanding || autoStandingClimb) {
      return RidingPosture.standingClimb;
    }

    // Super tuck na stromym zjeździe
    if (telemetry.gradientPercent <= -6.5 && telemetry.speedMs >= 19.5 && telemetry.powerWatts < 100) {
      return RidingPosture.superTuck;
    }

    return RidingPosture.seated;
  }

  double _interpolateGripTorsoIncline(HandlebarGrip current, HandlebarGrip target, double progress) {
    final double a = current.torsoInclineDegrees;
    final double b = target.torsoInclineDegrees;
    return a + (b - a) * progress;
  }

  double _interpolateGripHeadPitch(HandlebarGrip current, HandlebarGrip target, double progress) {
    final double a = current.headPitchDegrees;
    final double b = target.headPitchDegrees;
    return a + (b - a) * progress;
  }

  // ===========================================================================
  // KINEMATYKA ODWROTNA NÓG (IK) I LOKALNE POŁOŻENIE STAWÓW
  // ===========================================================================

  _JointPositions _calculateSkeletonPositions({
    required double crankAngle,
    required double leftCrankAngle,
    required double standingProgress,
    required double torsoInclineDegrees,
    required double headPitchDegrees,
    required HandlebarGrip grip,
    required RidingPosture posture,
    required double bikeSwayDegrees,
  }) {
    // 1. POZYCJE PEDAŁÓW (Wokół suportu [0, 0, 0])
    // Kąt 0 = góra (godz. 12:00), pi/2 = przód (godz. 3:00 dół napędowy)
    final double rPedalY = -_crankLengthMeters * math.cos(crankAngle);
    final double rPedalZ = _crankLengthMeters * math.sin(crankAngle);
    final rightPedal = Vector3(_pedalQFactorHalfMeters, rPedalY, rPedalZ);

    final double lPedalY = -_crankLengthMeters * math.cos(leftCrankAngle);
    final double lPedalZ = _crankLengthMeters * math.sin(leftCrankAngle);
    final leftPedal = Vector3(-_pedalQFactorHalfMeters, lPedalY, lPedalZ);

    // 2. POZYCJA MIEDNICY / BIODER (Hip Joint)
    // W siodle: wysokość ~0.66m nad suportem, cofnięcie do tyłu -0.16m
    // Na stojąco: miednica unosi się o +0.10m i przesuwa w przód o +0.12m nad suport
    final double hipY = 0.66 + (standingProgress * 0.10);
    final double hipZ = -0.16 + (standingProgress * 0.14);
    // Lekkie kołysanie bioder w poprzek
    final double hipLateralShift = -math.sin(crankAngle) * 0.025 * standingProgress;
    final hip = Vector3(hipLateralShift, hipY, hipZ);

    // 3. KINEMATYKA ODWROTNA KOLAN (Analytical 2-Bone Planar IK)
    final rightHip = hip + Vector3(_pedalQFactorHalfMeters * 0.85, 0.0, 0.0);
    final leftHip = hip - Vector3(_pedalQFactorHalfMeters * 0.85, 0.0, 0.0);

    final rightKnee = _solveLegIk(hip: rightHip, pedal: rightPedal, isRight: true);
    final leftKnee = _solveLegIk(hip: leftHip, pedal: leftPedal, isRight: false);

    // 4. POZYCJA DŁONI NA KIEROWNICY W ZALEŻNOŚCI OD CHWYTU
    final hands = _calculateHandPositions(grip: grip, posture: posture);

    // 5. POZYCJA KLATKI PIERSIOWEJ I GŁOWY
    final double torsoAngleRad = torsoInclineDegrees * math.pi / 180.0;
    const double spineLength = 0.48; // Długość tułowia od bioder do barków [m]

    final double chestY = hip.y + (spineLength * math.sin(torsoAngleRad));
    final double chestZ = hip.z + (spineLength * math.cos(torsoAngleRad));
    final chest = Vector3(0.0, chestY, chestZ);

    const double neckLength = 0.18; // Długość szyi i głowy [m]
    final double headPitchRad = headPitchDegrees * math.pi / 180.0;
    final double headY = chest.y + (neckLength * math.sin(torsoAngleRad + headPitchRad));
    final double headZ = chest.z + (neckLength * math.cos(torsoAngleRad + headPitchRad));
    final head = Vector3(0.0, headY, headZ);

    return _JointPositions(
      rightPedal: rightPedal,
      leftPedal: leftPedal,
      rightKnee: rightKnee,
      leftKnee: leftKnee,
      hip: hip,
      chest: chest,
      head: head,
      rightHand: hands.rightHand,
      leftHand: hands.leftHand,
    );
  }

  /// Rozwiązuje dwustawową kinematykę odwrotną nogi (Analytical 2-Bone IK) dla uda i podudzia.
  ///
  /// Kolano zgina się w płaszczyźnie strzałkowej do przodu z lekkim naturalnym odchyleniem na zewnątrz.
  static Vector3 _solveLegIk({
    required Vector3 hip,
    required Vector3 pedal,
    required bool isRight,
  }) {
    final Vector3 toPedal = pedal - hip;
    final double dist = toPedal.length.clamp(0.20, _thighLengthMeters + _calfLengthMeters - 0.005);

    // Twierdzenie cosinusów dla trójkąta biodro-kolano-pedał
    final double cosKnee = (_thighLengthMeters * _thighLengthMeters +
            _calfLengthMeters * _calfLengthMeters -
            dist * dist) /
        (2.0 * _thighLengthMeters * _calfLengthMeters);
    final double clampedCosKnee = cosKnee.clamp(-1.0, 1.0);

    final double cosHip = (_thighLengthMeters * _thighLengthMeters +
            dist * dist -
            _calfLengthMeters * _calfLengthMeters) /
        (2.0 * _thighLengthMeters * dist);
    final double clampedCosHip = cosHip.clamp(-1.0, 1.0);
    final double hipAngleOffset = math.acos(clampedCosHip);

    // Kierunek do pedału w płaszczyźnie Y-Z
    final double baseAngle = math.atan2(toPedal.y, toPedal.z);
    final double thighAngle = baseAngle + hipAngleOffset;

    final double kneeY = hip.y + (_thighLengthMeters * math.sin(thighAngle));
    final double kneeZ = hip.z + (_thighLengthMeters * math.cos(thighAngle));

    // Lekkie naturalne odwiedzenie kolana na zewnątrz przy zgięciu (Q-Angle)
    final double kneeOutward = (isRight ? 0.028 : -0.028) * (1.0 - clampedCosKnee);
    final double kneeX = (isRight ? _pedalQFactorHalfMeters : -_pedalQFactorHalfMeters) + kneeOutward;

    return Vector3(kneeX, kneeY, kneeZ);
  }

  _HandPositions _calculateHandPositions({
    required HandlebarGrip grip,
    required RidingPosture posture,
  }) {
    if (posture == RidingPosture.victorySalute) {
      // Obie ręce uniesione w górę w geście triumfu
      return _HandPositions(
        rightHand: Vector3(0.26, 1.35, 0.05),
        leftHand: Vector3(-0.26, 1.35, 0.05),
      );
    }

    if (posture == RidingPosture.drinkingBidon) {
      // Lewa ręka na klamce, prawa sięga po bidon przy koszyku
      return _HandPositions(
        rightHand: Vector3(0.12, 0.38, 0.10), // Ręka przy ramie
        leftHand: Vector3(-0.20, 0.64, 0.54), // Lewa na klamkomanetce
      );
    }

    switch (grip) {
      case HandlebarGrip.hoods:
        return _HandPositions(
          rightHand: Vector3(0.19, 0.64, 0.55),
          leftHand: Vector3(-0.19, 0.64, 0.55),
        );

      case HandlebarGrip.drops:
        return _HandPositions(
          rightHand: Vector3(0.21, 0.52, 0.51),
          leftHand: Vector3(-0.21, 0.52, 0.51),
        );

      case HandlebarGrip.aeroPuppyPaws:
        return _HandPositions(
          rightHand: Vector3(0.08, 0.62, 0.60),
          leftHand: Vector3(-0.08, 0.62, 0.60),
        );

      case HandlebarGrip.ttExtensions:
        return _HandPositions(
          rightHand: Vector3(0.065, 0.66, 0.68),
          leftHand: Vector3(-0.065, 0.66, 0.68),
        );
    }
  }
}

class _JointPositions {
  final Vector3 rightPedal;
  final Vector3 leftPedal;
  final Vector3 rightKnee;
  final Vector3 leftKnee;
  final Vector3 hip;
  final Vector3 chest;
  final Vector3 head;
  final Vector3 rightHand;
  final Vector3 leftHand;

  const _JointPositions({
    required this.rightPedal,
    required this.leftPedal,
    required this.rightKnee,
    required this.leftKnee,
    required this.hip,
    required this.chest,
    required this.head,
    required this.rightHand,
    required this.leftHand,
  });
}

class _HandPositions {
  final Vector3 rightHand;
  final Vector3 leftHand;

  const _HandPositions({
    required this.rightHand,
    required this.leftHand,
  });
}
