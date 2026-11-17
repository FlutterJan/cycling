// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Strona kontuzji kolana wpływająca na rozkład siły i asymetrię L/R.
enum KneeInjurySide {
  none('Brak kontuzji', 'Healthy'),
  left('Lewe kolano', 'Left Knee'),
  right('Prawe kolano', 'Right Knee');

  final String labelPl;
  final String labelEn;

  const KneeInjurySide(this.labelPl, this.labelEn);
}

/// Pozycja kolarza na rowerze determinująca kształt krzywej momentu obrotowego.
enum PedalingPosture {
  seatedAero('Pozycja Aero / TT', 'Seated Aero / TT'),
  seatedNormal('Siedząca szosowa', 'Seated Road'),
  seatedClimbing('Siedząca podjazdowa', 'Seated Climbing'),
  standingOutOfSaddle('Na stojąco (En Danseuse)', 'Standing');

  final String labelPl;
  final String labelEn;

  const PedalingPosture(this.labelPl, this.labelEn);
}

/// Klasyfikacja stanu pracy biomechanicznej korby.
enum PedalStrokeStatus {
  coasting('Swobodne toczenie', 'Coasting'),
  balanced('Symetryczny obrót', 'Balanced'),
  mildAsymmetry('Lekka asymetria', 'Mild Asymmetry'),
  injuryCompensation('Kompensacja kontuzji', 'Injury Compensation');

  final String labelPl;
  final String labelEn;

  const PedalStrokeStatus(this.labelPl, this.labelEn);
}

/// Dane wejściowe do analizy biomechaniki pełnego obrotu korby $360^\circ$.
class PedalStrokeAnalysisInput {
  /// Docelowa moc całkowita na korbie [W].
  final double targetPowerWatts;

  /// Aktualna kadencja [RPM].
  final double cadenceRpm;

  /// Długość ramienia korby [mm] (standardowo 165.0–175.0 mm).
  final double crankLengthMm;

  /// Pozycja kolarza na rowerze.
  final PedalingPosture posture;

  /// Poziom zmęczenia mięśniowego (0.0 = wypoczęty, 1.0 = skrajne wyczerpanie).
  final double fatigueLevel;

  /// Technika pedałowania (0.0 = amator, 1.0 = elita WorldTour).
  final double techniqueSkill;

  /// Strona przebytej/aktywnej kontuzji kolana.
  final KneeInjurySide kneeInjurySide;

  /// Nasilenie kontuzji kolana (0.0 = brak, 1.0 = pełna kompensacja ~44%/56%).
  final double kneeInjurySeverity;

  /// Bazowa naturalna dominacja prawej nogi (domyślnie +0.8%, daje ~49.2% / 50.8%).
  final double naturalRightDominanceBias;

  const PedalStrokeAnalysisInput({
    required this.targetPowerWatts,
    required this.cadenceRpm,
    this.crankLengthMm = 172.5,
    this.posture = PedalingPosture.seatedNormal,
    this.fatigueLevel = 0.15,
    this.techniqueSkill = 0.78,
    this.kneeInjurySide = KneeInjurySide.none,
    this.kneeInjurySeverity = 0.0,
    this.naturalRightDominanceBias = 0.008,
  });

  PedalStrokeAnalysisInput copyWith({
    double? targetPowerWatts,
    double? cadenceRpm,
    double? crankLengthMm,
    PedalingPosture? posture,
    double? fatigueLevel,
    double? techniqueSkill,
    KneeInjurySide? kneeInjurySide,
    double? kneeInjurySeverity,
    double? naturalRightDominanceBias,
  }) {
    return PedalStrokeAnalysisInput(
      targetPowerWatts: targetPowerWatts ?? this.targetPowerWatts,
      cadenceRpm: cadenceRpm ?? this.cadenceRpm,
      crankLengthMm: crankLengthMm ?? this.crankLengthMm,
      posture: posture ?? this.posture,
      fatigueLevel: fatigueLevel ?? this.fatigueLevel,
      techniqueSkill: techniqueSkill ?? this.techniqueSkill,
      kneeInjurySide: kneeInjurySide ?? this.kneeInjurySide,
      kneeInjurySeverity: kneeInjurySeverity ?? this.kneeInjurySeverity,
      naturalRightDominanceBias:
          naturalRightDominanceBias ?? this.naturalRightDominanceBias,
    );
  }
}

/// Pojedyncza próbka kątowa ($\theta \in [0^\circ, 359^\circ]$) siły stycznej i momentu.
class CrankAngleForceSample {
  /// Kąt korby [stopnie], gdzie $0^\circ$ = górny martwy punkt (TDC) lewej korby.
  final int angleDeg;

  /// Kąt korby [radiany].
  final double angleRad;

  /// Siła styczna lewej nogi $F_{t,L}(\theta)$ [N] w jej lokalnym cyklu (TDC = $0^\circ$).
  final double leftTangentialForceN;

  /// Siła styczna prawej nogi $F_{t,R}(\theta)$ [N] w jej lokalnym cyklu (TDC = $0^\circ$).
  final double rightTangentialForceN;

  /// Moment obrotowy lewej nogi [Nm] w jej lokalnym cyklu.
  final double leftTorqueNm;

  /// Moment obrotowy prawej nogi [Nm] w jej lokalnym cyklu.
  final double rightTorqueNm;

  /// Chwilowa suma mocy obu nóg przy globalnym kącie $\theta$ [W] (lewa na $\theta$, prawa na $\theta + 180^\circ$).
  final double combinedInstantPowerW;

  const CrankAngleForceSample({
    required this.angleDeg,
    required this.angleRad,
    required this.leftTangentialForceN,
    required this.rightTangentialForceN,
    required this.leftTorqueNm,
    required this.rightTorqueNm,
    required this.combinedInstantPowerW,
  });
}

/// Kompletny wynik analizy biomechanicznej z metrykami miernika mocy dual-sided.
class PedalStrokeAnalysisResult {
  /// Próbki co $1^\circ$ w pełnym cyklu $360^\circ$.
  final List<CrankAngleForceSample> samples;

  /// Średnia moc całkowita wyliczona z całki momentu obrotowego [W].
  final double totalPowerWatts;

  /// Średnia moc lewej nogi [W].
  final double leftPowerWatts;

  /// Średnia moc prawej nogi [W].
  final double rightPowerWatts;

  /// Udział procentowy lewej nogi (np. 49.2%).
  final double leftBalancePercent;

  /// Udział procentowy prawej nogi (np. 50.8%).
  final double rightBalancePercent;

  /// Torque Effectiveness (TE %) lewej nogi: $\frac{P_+}{P_+ + |P_-|} \times 100$.
  final double leftTorqueEffectivenessPercent;

  /// Torque Effectiveness (TE %) prawej nogi.
  final double rightTorqueEffectivenessPercent;

  /// Łączny Torque Effectiveness (TE %) obu nóg.
  final double combinedTorqueEffectivenessPercent;

  /// Pedal Smoothness (PS %) lewej nogi: $\frac{P_{avg}}{P_{max}} \times 100$.
  final double leftPedalSmoothnessPercent;

  /// Pedal Smoothness (PS %) prawej nogi.
  final double rightPedalSmoothnessPercent;

  /// Łączny Pedal Smoothness (PS %) obu nóg.
  final double combinedPedalSmoothnessPercent;

  /// Szczytowa siła styczna lewej nogi [N].
  final double leftPeakForceN;

  /// Szczytowa siła styczna prawej nogi [N].
  final double rightPeakForceN;

  /// Kąt szczytowego momentu lewej nogi [stopnie ATDC].
  final double leftPeakAngleDeg;

  /// Kąt szczytowego momentu prawej nogi [stopnie ATDC].
  final double rightPeakAngleDeg;

  /// Minimalna siła w fazie powrotu (ujemna = opór ciężaru nogi) [N].
  final double leftMinForceN;

  /// Minimalna siła w fazie powrotu dla prawej nogi [N].
  final double rightMinForceN;

  /// Klasyfikacja stanu asymetrii.
  final PedalStrokeStatus status;

  /// Tekstowy komunikat diagnostyczny dla dyrektora sportowego / biomechanika.
  final String diagnosticSummary;

  const PedalStrokeAnalysisResult({
    required this.samples,
    required this.totalPowerWatts,
    required this.leftPowerWatts,
    required this.rightPowerWatts,
    required this.leftBalancePercent,
    required this.rightBalancePercent,
    required this.leftTorqueEffectivenessPercent,
    required this.rightTorqueEffectivenessPercent,
    required this.combinedTorqueEffectivenessPercent,
    required this.leftPedalSmoothnessPercent,
    required this.rightPedalSmoothnessPercent,
    required this.combinedPedalSmoothnessPercent,
    required this.leftPeakForceN,
    required this.rightPeakForceN,
    required this.leftPeakAngleDeg,
    required this.rightPeakAngleDeg,
    required this.leftMinForceN,
    required this.rightMinForceN,
    required this.status,
    required this.diagnosticSummary,
  });

  /// Bezwzględna różnica balansu L/R w punktach procentowych.
  double get asymmetryDeltaPercent =>
      (leftBalancePercent - rightBalancePercent).abs();
}

/// Zaawansowany analizator biomechaniki obrotu korby (dual-sided power meter).
///
/// Symuluje rozkład siły stycznej $F_t(\theta)$ w pełnym cyklu $360^\circ$
/// dla lewej i prawej nogi, obliczając:
/// - **L/R Balance** (domyślnie ~49.2% / 50.8%, pogłębienie do ~44% / 56% po kontuzji kolana),
/// - **Torque Effectiveness (TE %)** — stosunek pracy napędowej do całkowitej pracy korby,
/// - **Pedal Smoothness (PS %)** — stosunek średniej mocy cyklu do mocy szczytowej.
class PedalStrokeBiomechanicsAnalyzer {
  const PedalStrokeBiomechanicsAnalyzer();

  /// Liczba próbek kątowych w pełnym obrocie korby.
  static const int cycleDegrees = 360;

  /// Analizuje pojedynczy pełny obrót korby $360^\circ$.
  PedalStrokeAnalysisResult analyze(PedalStrokeAnalysisInput input) {
    final double targetPower = math.max(0.0, input.targetPowerWatts);
    final double cadence = math.max(0.0, input.cadenceRpm);
    final double crankLengthM =
        (input.crankLengthMm.clamp(150.0, 185.0)) / 1000.0;
    final double fatigue = input.fatigueLevel.clamp(0.0, 1.0);
    final double skill = input.techniqueSkill.clamp(0.0, 1.0);
    final double injurySeverity = input.kneeInjurySide == KneeInjurySide.none
        ? 0.0
        : input.kneeInjurySeverity.clamp(0.0, 1.0);

    // Brak pedałowania (swobodne toczenie / zjazd).
    if (targetPower <= 0.5 || cadence <= 1.0) {
      return _buildCoastingResult();
    }

    // Prędkość kątowa korby [rad/s].
    final double omegaRadS = (2.0 * math.pi * cadence) / 60.0;

    // 1. Wyznaczenie docelowego balansu L/R.
    // Naturalna asymetria: ~49.2% L / 50.8% R (naturalRightDominanceBias = 0.008).
    // Kontuzja kolana przy severity=1.0 pogłębia asymetrię do 44.0% / 56.0% (przesunięcie o 0.06 od 0.5).
    final double baseRightShare =
        (0.5 + input.naturalRightDominanceBias).clamp(0.45, 0.55);
    double targetLeftShare = 1.0 - baseRightShare;
    double targetRightShare = baseRightShare;

    if (input.kneeInjurySide == KneeInjurySide.left && injurySeverity > 0.0) {
      // Przy severity = 1.0 lewa spada do 44.0%, prawa rośnie do 56.0%.
      const double injuredLeftTarget = 0.44;
      targetLeftShare =
          targetLeftShare + (injuredLeftTarget - targetLeftShare) * injurySeverity;
      targetRightShare = 1.0 - targetLeftShare;
    } else if (input.kneeInjurySide == KneeInjurySide.right &&
        injurySeverity > 0.0) {
      // Przy severity = 1.0 prawa spada do 44.0%, lewa rośnie do 56.0%.
      const double injuredRightTarget = 0.44;
      targetRightShare = targetRightShare +
          (injuredRightTarget - targetRightShare) * injurySeverity;
      targetLeftShare = 1.0 - targetRightShare;
    }

    final double targetLeftPowerW = targetPower * targetLeftShare;
    final double targetRightPowerW = targetPower * targetRightShare;

    // 2. Parametry kształtu krzywej dla lewej i prawej nogi.
    final double leftInjuryFactor =
        input.kneeInjurySide == KneeInjurySide.left ? injurySeverity : 0.0;
    final double rightInjuryFactor =
        input.kneeInjurySide == KneeInjurySide.right ? injurySeverity : 0.0;

    // Generacja bezwymiarowego kształtu F_t(theta) dla każdej nogi.
    final List<double> leftRaw = List<double>.filled(cycleDegrees, 0.0);
    final List<double> rightRaw = List<double>.filled(cycleDegrees, 0.0);

    for (int deg = 0; deg < cycleDegrees; deg++) {
      leftRaw[deg] = _computeNormalizedShape(
        angleDeg: deg.toDouble(),
        posture: input.posture,
        cadenceRpm: cadence,
        fatigue: fatigue,
        skill: skill,
        injuryFactor: leftInjuryFactor,
        compensationLoad: rightInjuryFactor,
      );
      rightRaw[deg] = _computeNormalizedShape(
        angleDeg: deg.toDouble(),
        posture: input.posture,
        cadenceRpm: cadence,
        fatigue: fatigue,
        skill: skill,
        injuryFactor: rightInjuryFactor,
        compensationLoad: leftInjuryFactor,
      );
    }

    // 3. Skalowanie tak, aby średnia moc w cyklu dokładnie odpowiadała targetLeftPowerW i targetRightPowerW.
    final double leftMeanRaw = _mean(leftRaw);
    final double rightMeanRaw = _mean(rightRaw);

    final double targetLeftTorqueNm = targetLeftPowerW / omegaRadS;
    final double targetRightTorqueNm = targetRightPowerW / omegaRadS;

    final double targetLeftForceN = targetLeftTorqueNm / crankLengthM;
    final double targetRightForceN = targetRightTorqueNm / crankLengthM;

    final double leftScale =
        leftMeanRaw > 1e-6 ? targetLeftForceN / leftMeanRaw : 0.0;
    final double rightScale =
        rightMeanRaw > 1e-6 ? targetRightForceN / rightMeanRaw : 0.0;

    final List<double> leftForcesN =
        List<double>.generate(cycleDegrees, (i) => leftRaw[i] * leftScale);
    final List<double> rightForcesN =
        List<double>.generate(cycleDegrees, (i) => rightRaw[i] * rightScale);

    // 4. Konstrukcja próbek $360^\circ$ (globalnie prawa korba jest przesunięta o $180^\circ$).
    final List<CrankAngleForceSample> samples = List<CrankAngleForceSample>.generate(
      cycleDegrees,
      (deg) {
        final double fL = leftForcesN[deg];
        final double fR = rightForcesN[deg];
        final double tL = fL * crankLengthM;
        final double tR = fR * crankLengthM;
        final int rightAtGlobalAngleIdx = (deg + 180) % cycleDegrees;
        final double combinedInstantPower =
            (fL + rightForcesN[rightAtGlobalAngleIdx]) * crankLengthM * omegaRadS;

        return CrankAngleForceSample(
          angleDeg: deg,
          angleRad: deg * (math.pi / 180.0),
          leftTangentialForceN: fL,
          rightTangentialForceN: fR,
          leftTorqueNm: tL,
          rightTorqueNm: tR,
          combinedInstantPowerW: combinedInstantPower,
        );
      },
      growable: false,
    );

    // 5. Wyliczanie metryk dual-sided power meter.
    final _LegMetrics leftMetrics = _computeLegMetrics(
      forcesN: leftForcesN,
      crankLengthM: crankLengthM,
      omegaRadS: omegaRadS,
    );
    final _LegMetrics rightMetrics = _computeLegMetrics(
      forcesN: rightForcesN,
      crankLengthM: crankLengthM,
      omegaRadS: omegaRadS,
    );

    final double actualTotalPower =
        leftMetrics.averagePowerW + rightMetrics.averagePowerW;
    final double leftBalance = actualTotalPower > 0
        ? (leftMetrics.averagePowerW / actualTotalPower) * 100.0
        : 50.0;
    final double rightBalance = 100.0 - leftBalance;

    final double totalPositiveWork =
        leftMetrics.positiveForceSum + rightMetrics.positiveForceSum;
    final double totalNegativeAbsWork =
        leftMetrics.negativeForceAbsSum + rightMetrics.negativeForceAbsSum;
    final double combinedTe = (totalPositiveWork + totalNegativeAbsWork) > 1e-6
        ? (totalPositiveWork / (totalPositiveWork + totalNegativeAbsWork)) * 100.0
        : 0.0;

    final double combinedPs = (leftMetrics.pedalSmoothnessPercent +
            rightMetrics.pedalSmoothnessPercent) /
        2.0;

    final double asymmetry = (leftBalance - rightBalance).abs();
    final PedalStrokeStatus status;
    if (injurySeverity >= 0.35 || asymmetry >= 6.0) {
      status = PedalStrokeStatus.injuryCompensation;
    } else if (asymmetry >= 2.5) {
      status = PedalStrokeStatus.mildAsymmetry;
    } else {
      status = PedalStrokeStatus.balanced;
    }

    final String summary = _buildDiagnosticSummary(
      status: status,
      leftBalance: leftBalance,
      rightBalance: rightBalance,
      combinedTe: combinedTe,
      combinedPs: combinedPs,
      injurySide: input.kneeInjurySide,
    );

    return PedalStrokeAnalysisResult(
      samples: samples,
      totalPowerWatts: actualTotalPower,
      leftPowerWatts: leftMetrics.averagePowerW,
      rightPowerWatts: rightMetrics.averagePowerW,
      leftBalancePercent: leftBalance,
      rightBalancePercent: rightBalance,
      leftTorqueEffectivenessPercent: leftMetrics.torqueEffectivenessPercent,
      rightTorqueEffectivenessPercent: rightMetrics.torqueEffectivenessPercent,
      combinedTorqueEffectivenessPercent: combinedTe,
      leftPedalSmoothnessPercent: leftMetrics.pedalSmoothnessPercent,
      rightPedalSmoothnessPercent: rightMetrics.pedalSmoothnessPercent,
      combinedPedalSmoothnessPercent: combinedPs,
      leftPeakForceN: leftMetrics.peakForceN,
      rightPeakForceN: rightMetrics.peakForceN,
      leftPeakAngleDeg: leftMetrics.peakAngleDeg,
      rightPeakAngleDeg: rightMetrics.peakAngleDeg,
      leftMinForceN: leftMetrics.minForceN,
      rightMinForceN: rightMetrics.minForceN,
      status: status,
      diagnosticSummary: summary,
    );
  }

  /// Oblicza znormalizowaną krzywą siły stycznej $F_t(\theta)$ w zakresie $0^\circ \dots 359^\circ$.
  double _computeNormalizedShape({
    required double angleDeg,
    required PedalingPosture posture,
    required double cadenceRpm,
    required double fatigue,
    required double skill,
    required double injuryFactor,
    required double compensationLoad,
  }) {
    // Kąt szczytu pchnięcia (ATDC): zależny od pozycji i kadencji.
    double peakCenterDeg = switch (posture) {
      PedalingPosture.seatedAero => 98.0,
      PedalingPosture.seatedNormal => 96.0,
      PedalingPosture.seatedClimbing => 92.0,
      PedalingPosture.standingOutOfSaddle => 88.0,
    };

    // Wyższa kadencja lekko przesuwa szczyt później, kontuzja skraca wczesną fazę.
    peakCenterDeg += ((cadenceRpm - 90.0) * 0.12).clamp(-6.0, 8.0);
    peakCenterDeg += injuryFactor * 7.0;

    // Szerokość impulsu napędowego (sigma Gaussa w stopniach).
    double downstrokeSigma = switch (posture) {
      PedalingPosture.seatedAero => 43.0,
      PedalingPosture.seatedNormal => 40.0,
      PedalingPosture.seatedClimbing => 38.0,
      PedalingPosture.standingOutOfSaddle => 33.0,
    };
    downstrokeSigma += skill * 5.0 - fatigue * 4.5 - injuryFactor * 6.5;
    downstrokeSigma = downstrokeSigma.clamp(24.0, 52.0);

    // Główny impuls fazy pchnięcia (power stroke: ~15°..170°).
    final double distFromPeak = _shortestAngularDistance(angleDeg, peakCenterDeg);
    final double downstrokePulse =
        math.exp(-0.5 * math.pow(distFromPeak / downstrokeSigma, 2));

    // Pociągnięcie dolne ("scraping mud off shoe" wokół 165°–215°) poprawia PS% i TE%.
    final double bdcDist = _shortestAngularDistance(angleDeg, 175.0);
    final double bdcTransition = (0.14 + 0.12 * skill - 0.08 * injuryFactor) *
        math.exp(-0.5 * math.pow(bdcDist / 26.0, 2));

    // Górne przejście przez TDC (345°..25°) — wyższa technika wygładza martwy punkt.
    final double tdcDist = _shortestAngularDistance(angleDeg, 5.0);
    final double tdcTransition = (0.10 + 0.11 * skill - 0.07 * injuryFactor) *
        math.exp(-0.5 * math.pow(tdcDist / 22.0, 2));

    // Faza powrotu (upstroke: 205°..335°) — bez aktywnego odciążania ciężar nogi daje ujemną siłę.
    final double upstrokeDist = _shortestAngularDistance(angleDeg, 270.0);
    final double upstrokeEnvelope =
        math.exp(-0.5 * math.pow(upstrokeDist / 42.0, 2));

    // Siła oporu fazy powrotu rośnie ze zmęczeniem, na stojąco oraz przy kontuzji kolana.
    double negativeTroughAmplitude = 0.24 - 0.15 * skill + 0.11 * fatigue;
    if (posture == PedalingPosture.standingOutOfSaddle) {
      negativeTroughAmplitude += 0.06;
    } else if (posture == PedalingPosture.seatedAero) {
      negativeTroughAmplitude -= 0.03;
    }
    negativeTroughAmplitude += injuryFactor * 0.14 + compensationLoad * 0.03;
    negativeTroughAmplitude = negativeTroughAmplitude.clamp(0.03, 0.42);

    return downstrokePulse +
        bdcTransition +
        tdcTransition -
        negativeTroughAmplitude * upstrokeEnvelope;
  }

  double _shortestAngularDistance(double a, double b) {
    double diff = (a - b) % 360.0;
    if (diff > 180.0) diff -= 360.0;
    if (diff < -180.0) diff += 360.0;
    return diff;
  }

  double _mean(List<double> values) {
    if (values.isEmpty) return 0.0;
    double sum = 0.0;
    for (final v in values) {
      sum += v;
    }
    return sum / values.length;
  }

  _LegMetrics _computeLegMetrics({
    required List<double> forcesN,
    required double crankLengthM,
    required double omegaRadS,
  }) {
    double sumForce = 0.0;
    double positiveSum = 0.0;
    double negativeAbsSum = 0.0;
    double peakForce = double.negativeInfinity;
    double minForce = double.infinity;
    int peakAngle = 0;

    for (int i = 0; i < forcesN.length; i++) {
      final double f = forcesN[i];
      sumForce += f;
      if (f >= 0.0) {
        positiveSum += f;
      } else {
        negativeAbsSum += f.abs();
      }
      if (f > peakForce) {
        peakForce = f;
        peakAngle = i;
      }
      if (f < minForce) {
        minForce = f;
      }
    }

    final double avgForce = sumForce / forcesN.length;
    final double avgPowerW = avgForce * crankLengthM * omegaRadS;
    final double peakPowerW = peakForce * crankLengthM * omegaRadS;

    final double te = (positiveSum + negativeAbsSum) > 1e-6
        ? (positiveSum / (positiveSum + negativeAbsSum)) * 100.0
        : 0.0;
    final double ps =
        peakPowerW > 1e-6 ? (avgPowerW / peakPowerW) * 100.0 : 0.0;

    return _LegMetrics(
      averagePowerW: avgPowerW,
      torqueEffectivenessPercent: te.clamp(0.0, 100.0),
      pedalSmoothnessPercent: ps.clamp(0.0, 100.0),
      peakForceN: peakForce,
      minForceN: minForce,
      peakAngleDeg: peakAngle.toDouble(),
      positiveForceSum: positiveSum,
      negativeForceAbsSum: negativeAbsSum,
    );
  }

  PedalStrokeAnalysisResult _buildCoastingResult() {
    final List<CrankAngleForceSample> zeroSamples =
        List<CrankAngleForceSample>.generate(
      cycleDegrees,
      (deg) => CrankAngleForceSample(
        angleDeg: deg,
        angleRad: deg * (math.pi / 180.0),
        leftTangentialForceN: 0.0,
        rightTangentialForceN: 0.0,
        leftTorqueNm: 0.0,
        rightTorqueNm: 0.0,
        combinedInstantPowerW: 0.0,
      ),
      growable: false,
    );
    return PedalStrokeAnalysisResult(
      samples: zeroSamples,
      totalPowerWatts: 0.0,
      leftPowerWatts: 0.0,
      rightPowerWatts: 0.0,
      leftBalancePercent: 50.0,
      rightBalancePercent: 50.0,
      leftTorqueEffectivenessPercent: 0.0,
      rightTorqueEffectivenessPercent: 0.0,
      combinedTorqueEffectivenessPercent: 0.0,
      leftPedalSmoothnessPercent: 0.0,
      rightPedalSmoothnessPercent: 0.0,
      combinedPedalSmoothnessPercent: 0.0,
      leftPeakForceN: 0.0,
      rightPeakForceN: 0.0,
      leftPeakAngleDeg: 0.0,
      rightPeakAngleDeg: 0.0,
      leftMinForceN: 0.0,
      rightMinForceN: 0.0,
      status: PedalStrokeStatus.coasting,
      diagnosticSummary: 'Swobodne toczenie (brak momentu na korbie).',
    );
  }

  String _buildDiagnosticSummary({
    required PedalStrokeStatus status,
    required double leftBalance,
    required double rightBalance,
    required double combinedTe,
    required double combinedPs,
    required KneeInjurySide injurySide,
  }) {
    final String lrText =
        '${leftBalance.toStringAsFixed(1)}% / ${rightBalance.toStringAsFixed(1)}%';
    switch (status) {
      case PedalStrokeStatus.coasting:
        return 'Swobodne toczenie (brak momentu na korbie).';
      case PedalStrokeStatus.injuryCompensation:
        final String side = injurySide == KneeInjurySide.left
            ? 'lewego kolana'
            : injurySide == KneeInjurySide.right
                ? 'prawego kolana'
                : 'układu ruchu';
        return 'Kompensacja przeciążenia $side: balans L/R $lrText, TE ${combinedTe.toStringAsFixed(1)}%, PS ${combinedPs.toStringAsFixed(1)}%.';
      case PedalStrokeStatus.mildAsymmetry:
        return 'Lekka asymetria L/R ($lrText). Zalecana praca nad równym przejściem przez martwy punkt (PS ${combinedPs.toStringAsFixed(1)}%).';
      case PedalStrokeStatus.balanced:
        return 'Optymalna symetria L/R ($lrText), efektywność TE ${combinedTe.toStringAsFixed(1)}%, płynność PS ${combinedPs.toStringAsFixed(1)}%.';
    }
  }
}

class _LegMetrics {
  final double averagePowerW;
  final double torqueEffectivenessPercent;
  final double pedalSmoothnessPercent;
  final double peakForceN;
  final double minForceN;
  final double peakAngleDeg;
  final double positiveForceSum;
  final double negativeForceAbsSum;

  const _LegMetrics({
    required this.averagePowerW,
    required this.torqueEffectivenessPercent,
    required this.pedalSmoothnessPercent,
    required this.peakForceN,
    required this.minForceN,
    required this.peakAngleDeg,
    required this.positiveForceSum,
    required this.negativeForceAbsSum,
  });
}

/// Interaktywny panel telemetryczny analizatora biomechaniki obrotu korby $360^\circ$.
///
/// Prezentuje wykres biegunowy siły stycznej $F_t(\theta)$ dla lewej i prawej nogi,
/// pasek L/R Balance, wskaźniki Torque Effectiveness (TE %) oraz Pedal Smoothness (PS %),
/// a także kontrolki symulacji kontuzji kolana, pozycji, mocy i kadencji.
class PedalStrokeBiomechanicsPanel extends StatefulWidget {
  final PedalStrokeAnalysisInput initialInput;
  final ValueChanged<PedalStrokeAnalysisResult>? onAnalysisChanged;

  const PedalStrokeBiomechanicsPanel({
    super.key,
    this.initialInput = const PedalStrokeAnalysisInput(
      targetPowerWatts: 340.0,
      cadenceRpm: 92.0,
    ),
    this.onAnalysisChanged,
  });

  @override
  State<PedalStrokeBiomechanicsPanel> createState() =>
      _PedalStrokeBiomechanicsPanelState();
}

class _PedalStrokeBiomechanicsPanelState
    extends State<PedalStrokeBiomechanicsPanel> {
  static const PedalStrokeBiomechanicsAnalyzer _analyzer =
      PedalStrokeBiomechanicsAnalyzer();

  late PedalStrokeAnalysisInput _input;
  late PedalStrokeAnalysisResult _result;

  @override
  void initState() {
    super.initState();
    _input = widget.initialInput;
    _result = _analyzer.analyze(_input);
  }

  void _updateInput(PedalStrokeAnalysisInput next) {
    setState(() {
      _input = next;
      _result = _analyzer.analyze(_input);
    });
    widget.onAnalysisChanged?.call(_result);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isCompact = constraints.maxWidth < 680;
          final bool isWide = constraints.maxWidth >= 1000;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact),
              const SizedBox(height: 16),
              if (isCompact) ...[
                _buildPolarChartCard(height: 250),
                const SizedBox(height: 12),
                _buildMetricsColumn(),
                const SizedBox(height: 12),
                _buildControlsCard(),
              ] else if (isWide) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildPolarChartCard(height: 300),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: _buildMetricsColumn(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: _buildControlsCard(),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildPolarChartCard(height: 280),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: _buildMetricsColumn(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildControlsCard(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    final Color statusColor = switch (_result.status) {
      PedalStrokeStatus.coasting => AppColors.textSecondary,
      PedalStrokeStatus.balanced => AppColors.statusSuccess,
      PedalStrokeStatus.mildAsymmetry => AppColors.amberWarning,
      PedalStrokeStatus.injuryCompensation => AppColors.crimsonAlert,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.6),
            ),
          ),
          child: const Icon(
            Icons.donut_large_rounded,
            color: AppColors.goldAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  const Text(
                    'Biomechanika Obrotu Korby 360°',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      _result.status.labelPl,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _result.diagnosticSummary,
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
  }

  Widget _buildPolarChartCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Siła styczna Ft(θ)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legendDot(AppColors.accentBlue, 'Lewa (L)'),
                  const SizedBox(width: 10),
                  _legendDot(AppColors.goldAccent, 'Prawa (R)'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              builder: (context, _, __) {
                return CustomPaint(
                  painter: _PedalStrokePolarPainter(result: _result),
                  size: Size.infinite,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsColumn() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Telemetria Dual-Sided Power Meter',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildBalanceBar(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDualMetricTile(
                  title: 'Torque Effectiveness (TE)',
                  leftValue:
                      '${_result.leftTorqueEffectivenessPercent.toStringAsFixed(1)}%',
                  rightValue:
                      '${_result.rightTorqueEffectivenessPercent.toStringAsFixed(1)}%',
                  combinedValue:
                      '${_result.combinedTorqueEffectivenessPercent.toStringAsFixed(1)}%',
                  accent: AppColors.statusSuccess,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDualMetricTile(
                  title: 'Pedal Smoothness (PS)',
                  leftValue:
                      '${_result.leftPedalSmoothnessPercent.toStringAsFixed(1)}%',
                  rightValue:
                      '${_result.rightPedalSmoothnessPercent.toStringAsFixed(1)}%',
                  combinedValue:
                      '${_result.combinedPedalSmoothnessPercent.toStringAsFixed(1)}%',
                  accent: AppColors.cyanAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildCompactStat(
                  'Szczyt L / R',
                  '${_result.leftPeakForceN.toStringAsFixed(0)} / ${_result.rightPeakForceN.toStringAsFixed(0)} N',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCompactStat(
                  'Kąt szczytu',
                  '${_result.leftPeakAngleDeg.toStringAsFixed(0)}° / ${_result.rightPeakAngleDeg.toStringAsFixed(0)}°',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceBar() {
    final double leftRatio =
        (_result.leftBalancePercent / 100.0).clamp(0.1, 0.9);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'L ${_result.leftBalancePercent.toStringAsFixed(1)}% (${_result.leftPowerWatts.toStringAsFixed(0)} W)',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.accentBlue,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                'L / R',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Flexible(
              child: Text(
                '${_result.rightBalancePercent.toStringAsFixed(1)}% R (${_result.rightPowerWatts.toStringAsFixed(0)} W)',
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.goldAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                Expanded(
                  flex: (leftRatio * 1000).round(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    color: AppColors.accentBlue,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: ((1.0 - leftRatio) * 1000).round(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    color: AppColors.goldAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDualMetricTile({
    required String title,
    required String leftValue,
    required String rightValue,
    required String combinedValue,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            combinedValue,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'L $leftValue · R $rightValue',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsCard() {
    final bool injuryEnabled = _input.kneeInjurySide != KneeInjurySide.none;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Parametry Symulacji',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ActionChipButton(
                label: 'Reset',
                onPressed: () => _updateInput(widget.initialInput),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSliderRow(
            label: 'Moc całkowita',
            valueText: '${_input.targetPowerWatts.toStringAsFixed(0)} W',
            value: _input.targetPowerWatts.clamp(0.0, 1200.0),
            min: 0.0,
            max: 1200.0,
            onChanged: (v) =>
                _updateInput(_input.copyWith(targetPowerWatts: v)),
          ),
          _buildSliderRow(
            label: 'Kadencja',
            valueText: '${_input.cadenceRpm.toStringAsFixed(0)} RPM',
            value: _input.cadenceRpm.clamp(0.0, 130.0),
            min: 0.0,
            max: 130.0,
            onChanged: (v) => _updateInput(_input.copyWith(cadenceRpm: v)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pozycja kolarza',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: PedalingPosture.values.map((posture) {
              return _ActionChipButton(
                label: posture.labelPl,
                selected: _input.posture == posture,
                onPressed: () =>
                    _updateInput(_input.copyWith(posture: posture)),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          const Text(
            'Symulacja kontuzji kolana',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: KneeInjurySide.values.map((side) {
              return _ActionChipButton(
                label: side.labelPl,
                selected: _input.kneeInjurySide == side,
                accentColor: side == KneeInjurySide.none
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert,
                onPressed: () => _updateInput(
                  _input.copyWith(
                    kneeInjurySide: side,
                    kneeInjurySeverity: side == KneeInjurySide.none
                        ? 0.0
                        : (_input.kneeInjurySeverity <= 0.0
                            ? 1.0
                            : _input.kneeInjurySeverity),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          _buildSliderRow(
            label: 'Nasilenie kontuzji',
            valueText: injuryEnabled
                ? '${(_input.kneeInjurySeverity * 100).toStringAsFixed(0)}%'
                : 'Wyłączone',
            value: injuryEnabled ? _input.kneeInjurySeverity.clamp(0.0, 1.0) : 0.0,
            min: 0.0,
            max: 1.0,
            enabled: injuryEnabled,
            onChanged: (v) =>
                _updateInput(_input.copyWith(kneeInjurySeverity: v)),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: enabled
                      ? AppColors.textSecondary
                      : AppColors.textSecondary.withValues(alpha: 0.45),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              valueText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor:
                enabled ? AppColors.goldAccent : AppColors.cardBorder,
            inactiveTrackColor: AppColors.surface,
            thumbColor: enabled ? AppColors.goldAccent : AppColors.textSecondary,
            overlayColor: AppColors.goldAccent.withValues(alpha: 0.16),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}

class _ActionChipButton extends StatefulWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onPressed;

  const _ActionChipButton({
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.accentColor = AppColors.goldAccent,
  });

  @override
  State<_ActionChipButton> createState() => _ActionChipButtonState();
}

class _ActionChipButtonState extends State<_ActionChipButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.selected
        ? widget.accentColor
        : _focused
            ? AppColors.accentBlue
            : _hovered
                ? AppColors.textSecondary
                : AppColors.cardBorder;

    final Color bgColor = widget.selected
        ? widget.accentColor.withValues(alpha: _pressed ? 0.28 : 0.18)
        : _pressed
            ? AppColors.surfaceLight
            : _hovered
                ? AppColors.surface.withValues(alpha: 0.9)
                : AppColors.surface;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: widget.selected
                  ? widget.accentColor
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PedalStrokePolarPainter extends CustomPainter {
  final PedalStrokeAnalysisResult result;

  const _PedalStrokePolarPainter({required this.result});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = math.min(size.width, size.height) * 0.42;
    if (maxRadius <= 10) return;

    final Paint gridPaint = Paint()
      ..color = AppColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Pierścienie odniesienia (0 N = 25% promienia, maksimum = 100% promienia).
    final double zeroRadius = maxRadius * 0.25;
    for (final double factor in [0.25, 0.5, 0.75, 1.0]) {
      canvas.drawCircle(center, maxRadius * factor, gridPaint);
    }

    // Osie TDC (0°), 90°, BDC (180°), 270°.
    for (int i = 0; i < 4; i++) {
      final double rad = (i * 90.0 - 90.0) * (math.pi / 180.0);
      canvas.drawLine(
        center,
        Offset(
          center.dx + math.cos(rad) * maxRadius,
          center.dy + math.sin(rad) * maxRadius,
        ),
        gridPaint,
      );
    }

    final double maxForce = math.max(
      50.0,
      math.max(result.leftPeakForceN, result.rightPeakForceN) * 1.08,
    );

    _drawForceCurve(
      canvas: canvas,
      center: center,
      zeroRadius: zeroRadius,
      maxRadius: maxRadius,
      maxForce: maxForce,
      color: AppColors.accentBlue,
      isLeft: true,
    );
    _drawForceCurve(
      canvas: canvas,
      center: center,
      zeroRadius: zeroRadius,
      maxRadius: maxRadius,
      maxForce: maxForce,
      color: AppColors.goldAccent,
      isLeft: false,
    );
  }

  void _drawForceCurve({
    required Canvas canvas,
    required Offset center,
    required double zeroRadius,
    required double maxRadius,
    required double maxForce,
    required Color color,
    required bool isLeft,
  }) {
    final Path path = Path();
    for (int i = 0; i < result.samples.length; i++) {
      final CrankAngleForceSample s = result.samples[i];
      final double force =
          isLeft ? s.leftTangentialForceN : s.rightTangentialForceN;
      final double normalized = (force / maxForce).clamp(-0.22, 1.0);
      final double r = (zeroRadius + normalized * (maxRadius - zeroRadius))
          .clamp(6.0, maxRadius);
      // 0° (TDC) na górze (-pi/2), ruch zgodny z ruchem wskazówek zegara.
      final double canvasAngle = s.angleRad - math.pi / 2;
      final Offset pt = Offset(
        center.dx + math.cos(canvasAngle) * r,
        center.dy + math.sin(canvasAngle) * r,
      );
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();

    final Paint fillPaint = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    final Paint strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _PedalStrokePolarPainter oldDelegate) {
    return oldDelegate.result != result;
  }
}
