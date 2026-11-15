// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../core/constants/physics_constants.dart';
import '../../models/equipment/bike_fit_configuration.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/race/race_stage.dart';
import '../../models/rider/rider_physiology.dart';
import '../../models/rider/rider_skills.dart';

/// Punkt pomiarowy w wirtualnym tunelu aerodynamicznym dla zadanego kąta wiatru pozornego (Yaw).
class WindTunnelYawPoint {
  /// Kąt pozornego wiatru natarcia [°] (-20° do +20°)
  final double yawDegrees;

  /// Współczynnik oporu aerodynamicznego CdA dla danego kąta [m²]
  final double cda;

  /// Siła oporu wzdłuż osi jazdy przy 45 km/h [N]
  final double dragForceNewtonsAt45Kmh;

  /// Siła boczna spychająca rower przy 45 km/h [N]
  final double sideForceNewtonsAt45Kmh;

  /// Wymagana moc aerodynamiczna do utrzymania 45 km/h [W]
  final double aeroPowerWattsAt45Kmh;

  const WindTunnelYawPoint({
    required this.yawDegrees,
    required this.cda,
    required this.dragForceNewtonsAt45Kmh,
    required this.sideForceNewtonsAt45Kmh,
    required this.aeroPowerWattsAt45Kmh,
  });

  @override
  String toString() =>
      'YawPoint(yaw: $yawDegrees°, CdA: ${cda.toStringAsFixed(4)}m², '
      'P_aero: ${aeroPowerWattsAt45Kmh.toStringAsFixed(1)}W, F_side: ${sideForceNewtonsAt45Kmh.toStringAsFixed(1)}N)';
}

/// Pełny raport z próby w tunelu aerodynamicznym (Wind Tunnel Polar Sweep).
class WindTunnelPolarReport {
  /// Punkty pomiarowe dla kątów yaw od -20° do +20°
  final List<WindTunnelYawPoint> points;

  /// Minimalna wartość CdA w tunelu (sweet spot aero) [m²]
  final double minCdA;

  /// Kąt yaw, przy którym CdA osiąga minimum [°]
  final double optimalYawDegrees;

  /// Średnie ważone CdA w warunkach typowego wiatru szosowego (rozkład Gaussa wokół 0–10°) [m²]
  final double weightedAverageCdA;

  /// Wskaźnik efektu żagla aero (Aero Sailing Effect Index: 0.0 - 1.0)
  final double sailingEffectIndex;

  const WindTunnelPolarReport({
    required this.points,
    required this.minCdA,
    required this.optimalYawDegrees,
    required this.weightedAverageCdA,
    required this.sailingEffectIndex,
  });
}

/// Szczegółowy raport zysków i parametrów aerodynamicznych fittingu kolarza.
class BikeFitAeroReport {
  /// Bazowy współczynnik oporu kolarza w pozycji neutralnej/endurance [m²]
  final double baselineCdA;

  /// Efektywny współczynnik oporu CdA po zastosowaniu Bike Fittingu [m²]
  final double fittedCdA;

  /// Różnica CdA (wartości ujemne = redukcja oporu) [m²]
  final double deltaCdA;

  /// Procentowa redukcja oporu aerodynamicznego [%]
  double get cdaSavingsPercent =>
      baselineCdA > 0 ? ((-deltaCdA) / baselineCdA) * 100.0 : 0.0;

  // Rozbicie zysków aero na poszczególne komponenty pozycji
  final double stemAndSpacersAeroGainM2;
  final double cockpitWidthAeroGainM2;
  final double hoodTiltAeroGainM2;
  final double crankLengthAeroGainM2;
  final double saddlePositionAeroGainM2;

  /// Oszczędność mocy w Watach ("Darmowe Waty") przy prędkości 45 km/h
  final int wattsSavedAt45Kmh;

  /// Oszczędność mocy w Watach przy prędkości 50 km/h (tempo ucieczki / finiszu)
  final int wattsSavedAt50Kmh;

  /// Szacowany zysk czasu na 40-kilometrowej jeździe indywidualnej na czas [sekundy]
  final double timeSavedSecondsOver40Km;

  /// Szacowany zysk czasu na 200-kilometrowym płaskim etapie szosowym [sekundy]
  final double timeSavedSecondsOver200Km;

  const BikeFitAeroReport({
    required this.baselineCdA,
    required this.fittedCdA,
    required this.deltaCdA,
    required this.stemAndSpacersAeroGainM2,
    required this.cockpitWidthAeroGainM2,
    required this.hoodTiltAeroGainM2,
    required this.crankLengthAeroGainM2,
    required this.saddlePositionAeroGainM2,
    required this.wattsSavedAt45Kmh,
    required this.wattsSavedAt50Kmh,
    required this.timeSavedSecondsOver40Km,
    required this.timeSavedSecondsOver200Km,
  });

  /// Szacowana oszczędność mocy w Watach dla dowolnej zadanej prędkości [km/h]
  int calculateWattsSavedAtSpeed(double speedKmh) {
    if (speedKmh <= 0.0 || deltaCdA >= 0.0) return 0;
    final double v = speedKmh / 3.6;
    final double power = 0.5 * PhysicsConstants.seaLevelAirDensity * deltaCdA.abs() * math.pow(v, 3);
    return power.round().clamp(0, 60);
  }
}

/// Analiza biomechaniczna, obciążenia aparatu ruchu i kar wydolnościowych fittingu.
class BiomechanicalFitImpact {
  /// Wskaźnik mobilności i gibkości kolarza (0–100)
  final double riderMobilityScore;

  /// Wskaźnik agresywności i obniżenia pozycji na rowerze (0–100)
  final double positionAggressivenessScore;

  /// Różnica między agresywnością pozycji a możliwościami anatomicznymi kolarza (0–100)
  final double mobilityMismatch;

  /// Spadek mocy progowej (FTP) na długich podjazdach o nachyleniu ≥6% [%] (1.0% do 3.0% przy niedopasowaniu)
  final double climbingPowerPenaltyPercent;

  /// Utracone Waty na długim podjeździe w wyniku ucisku przepony i zamkniętego kąta biodra [W]
  final double climbingPowerPenaltyWatts;

  /// Ryzyko mikrourazu stawu kolanowego / zapalenia ścięgna rzepki (0–100)
  final double kneeMicrotraumaRiskScore;

  /// Ryzyko mikrourazu i przeciążenia odcinka lędźwiowego kręgosłupa (0–100)
  final double lowerBackMicrotraumaRiskScore;

  /// Zmęczenie karku i odcinka szyjnego kręgosłupa na etapach >160 km (0–100)
  final double neckFatigueScore;

  /// Ogólny wskaźnik komfortu jazdy (0–100)
  final double overallComfortIndex;

  /// Wskaźnik stabilności prowadzenia i kontroli na bocznych wiatrach (0–100)
  final double handlingStabilityIndex;

  /// Kąt biodra w Górnym Martwym Punkcie (GMP / TDC) [°]
  final double hipAngleAtTdcDegrees;

  /// Czy pozycja upośledza możliwości wspinaczkowe kolarza na przełęczach górskich
  bool get isClimbingCompromised => climbingPowerPenaltyPercent > 0.0;

  /// Czy pozycja stwarza wysokie ryzyko kontuzji przeciążeniowej (kolano / plecy > 65/100)
  bool get hasHighInjuryRisk =>
      kneeMicrotraumaRiskScore >= 65.0 || lowerBackMicrotraumaRiskScore >= 65.0;

  /// Mnożnik tempa akumulacji zmęczenia na etapach powyżej 160 km (1.00 – 1.25)
  final double enduranceFatigueMultiplier;

  const BiomechanicalFitImpact({
    required this.riderMobilityScore,
    required this.positionAggressivenessScore,
    required this.mobilityMismatch,
    required this.climbingPowerPenaltyPercent,
    required this.climbingPowerPenaltyWatts,
    required this.kneeMicrotraumaRiskScore,
    required this.lowerBackMicrotraumaRiskScore,
    required this.neckFatigueScore,
    required this.overallComfortIndex,
    required this.handlingStabilityIndex,
    required this.hipAngleAtTdcDegrees,
    required this.enduranceFatigueMultiplier,
  });
}

/// Całościowa ewaluacja konfiguracji Bike Fittingu łącząca aerodynamikę, biomechanikę i tunel.
class BikeFitEvaluationReport {
  /// Oceniana konfiguracja fittingu
  final BikeFitConfiguration configuration;

  /// Raport aerodynamiczny (CdA, darmowe waty przy 45 km/h, zysk czasu)
  final BikeFitAeroReport aeroReport;

  /// Wpływ na biomechanikę, ryzyko kontuzji i spadek mocy na podjazdach (1-3%)
  final BiomechanicalFitImpact biomechanicalImpact;

  /// Wyniki próby w wirtualnym tunelu aerodynamicznym dla kątów yaw
  final WindTunnelPolarReport windTunnelReport;

  /// Praktyczne zalecenia sztabu medycznego i inżynierów aerodynamiki
  final List<String> coachingAdvice;

  /// Czy pozycja jest zrównoważona i bezpieczna na cały 3-tygodniowy Grand Tour
  final bool isGrandTourViable;

  const BikeFitEvaluationReport({
    required this.configuration,
    required this.aeroReport,
    required this.biomechanicalImpact,
    required this.windTunnelReport,
    required this.coachingAdvice,
    required this.isGrandTourViable,
  });
}

/// Rekomendacja optymalnego Bike Fittingu pod profil profil danego etapu.
class BikeFitOptimizationRecommendation {
  final StageType stageType;
  final String title;
  final String rationale;
  final BikeFitConfiguration recommendedFit;
  final int estimatedWattsAdvantage;

  const BikeFitOptimizationRecommendation({
    required this.stageType,
    required this.title,
    required this.rationale,
    required this.recommendedFit,
    required this.estimatedWattsAdvantage,
  });
}

/// Zaawansowany silnik fizyki Bike Fittingu i Wirtualnego Tunelu Aerodynamicznego.
///
/// Wylicza:
/// 1. Precyzyjne zyski aerodynamiczne ($CdA$) z usunięcia podkładek (slammed stem), wąskiego kokpitu (360/380mm),
///    rotacji klamek do wewnątrz (0-35°) oraz krótszych korb (165/170mm otwierających kąt biodra).
/// 2. "Darmowe waty" generowane przy 45 km/h i 50 km/h oraz zysk sekundowy na czasówkach i etapach płaskich.
/// 3. Ryzyko mikrourazów kolan (ścięgno rzepki) i pleców (odcinek lędźwiowy) u zawodników o niewystarczającej gibkości.
/// 4. Spadek mocy progowej FTP o 1–3% na długich alpejskich wspinaczkach w przypadku zbyt głębokiej pozycji.
class BikeFitAndWindTunnelEngine {
  BikeFitAndWindTunnelEngine._();

  // ===========================================================================
  // 1. GŁÓWNA METODA EWALUACJI FITTINGU
  // ===========================================================================

  /// Przeprowadza pełną analizę aerodynamiczną, biomechaniczną i tunelową danej konfiguracji fittingu.
  static BikeFitEvaluationReport evaluateFit({
    required BikeFitConfiguration fit,
    required RiderPhysiology physiology,
    RiderSkills? skills,
    CompleteBike? bike,
    int riderAge = 26,
    double testingAirSpeedKmh = 45.0,
  }) {
    // 1. Obliczenia aerodynamiczne
    final aeroReport = calculateAerodynamics(
      fit: fit,
      physiology: physiology,
      bike: bike,
      riderAge: riderAge,
    );

    // 2. Obliczenia biomechaniczne i zdrowotne
    final biomechanics = calculateBiomechanicalImpact(
      fit: fit,
      physiology: physiology,
      skills: skills,
      riderAge: riderAge,
    );

    // 3. Wirtualny tunel aerodynamiczny
    final windTunnelReport = simulateWindTunnelSweep(
      fit: fit,
      physiology: physiology,
      airSpeedKmh: testingAirSpeedKmh,
    );

    // 4. Generowanie zaleceń trenersko-biomechanicznych
    final advice = _generateCoachingAdvice(fit, aeroReport, biomechanics);

    // 5. Zdatność na Grand Tour
    final isViable = !biomechanics.hasHighInjuryRisk &&
        biomechanics.enduranceFatigueMultiplier <= 1.10 &&
        fit.isUciLegal;

    return BikeFitEvaluationReport(
      configuration: fit,
      aeroReport: aeroReport,
      biomechanicalImpact: biomechanics,
      windTunnelReport: windTunnelReport,
      coachingAdvice: advice,
      isGrandTourViable: isViable,
    );
  }

  // ===========================================================================
  // 2. OBLICZENIA AERODYNAMICZNE I DARMOWE WATY
  // ===========================================================================

  /// Wylicza szczegółowe modyfikatory oporu powietrza CdA i zyski watów.
  static BikeFitAeroReport calculateAerodynamics({
    required BikeFitConfiguration fit,
    required RiderPhysiology physiology,
    CompleteBike? bike,
    int riderAge = 26,
  }) {
    // Bazowe CdA kolarza w pozycji chwytów (hoods) z tradycyjnym kokpitem 400mm / 20mm spacerów
    final double baseFrontalArea = physiology.frontalAreaM2 > 0 ? physiology.frontalAreaM2 : 0.498;
    final double baselineCdA = (baseFrontalArea * 0.652) + (bike?.frame.aeroCdaModifier ?? -0.010);

    // A. Usunięcie podkładek spod mostka (slammed stem: 0 mm vs 20 mm)
    // Obniżenie główki i spłaszczenie tułowia: -0.0055 m² przy 0 mm
    final double stemAndSpacersAeroGain =
        ((fit.spacersStackMm - 20) / 20.0) * 0.0055 - ((fit.stemLengthMm - 110) * 0.00008);

    // B. Węższy kokpit (360/380 mm vs standard 400 mm)
    // 360 mm daje -0.0100 m², 380 mm daje -0.0050 m²
    final double cockpitWidthAeroGain = (fit.cockpitWidthMm - 400) * 0.00025;

    // C. Rotacja klamek do wewnątrz (0° - 35° puppy paws)
    // Do 14° (limit UCI) daje -0.0042 m², 20°–35° puppy paws daje do -0.0065 m²
    final double clampedHoodTilt = fit.hoodInwardTiltDegrees.clamp(0.0, 35.0);
    final double hoodTiltAeroGain = clampedHoodTilt <= 14.0
        ? -(clampedHoodTilt / 14.0) * 0.0042
        : -0.0042 - ((clampedHoodTilt - 14.0) / 21.0) * 0.0023;

    // D. Krótsze ramiona korby (165/170 mm otwierające kąt biodra)
    // Krótsza korba unosi kolano niżej w GMP, umożliwiając obniżenie klatki piersiowej i kasku
    // bez uderzania kolanami w klatkę/brzuch: zysk od -0.0015 do -0.0025 m²
    final double crankLengthAeroGain = (fit.crankArmLengthMm - 172.5) * 0.00026;

    // E. Pochylenie siodła i cofnięcie (rotacja miednicy / anterior pelvic tilt)
    final double saddlePositionAeroGain =
        (fit.saddleTiltDegrees.clamp(-4.0, 0.0) / 4.0) * 0.0016;

    // Łączna zmiana CdA
    final double totalDeltaCdA = stemAndSpacersAeroGain +
        cockpitWidthAeroGain +
        hoodTiltAeroGain +
        crankLengthAeroGain +
        saddlePositionAeroGain;

    final double fittedCdA = (baselineCdA + totalDeltaCdA).clamp(0.185, 0.420);

    // Obliczenie darmowych watów przy 45 km/h (12.5 m/s) i 50 km/h (13.89 m/s)
    // P_aero = 0.5 * rho * deltaCdA * v^3
    const double rho = PhysicsConstants.seaLevelAirDensity;
    const double v45 = 45.0 / 3.6;
    const double v50 = 50.0 / 3.6;

    final double watts45 = 0.5 * rho * totalDeltaCdA.abs() * math.pow(v45, 3);
    final double watts50 = 0.5 * rho * totalDeltaCdA.abs() * math.pow(v50, 3);

    // Szacowany zysk czasu:
    // W jeździe na czas (TT 40 km ~ 48 km/h ~ 3000s) zysk czasu proporcjonalny do (CdA_new / CdA_old)^(1/3)
    final double timeRatio = math.pow(fittedCdA / baselineCdA, 0.3333).toDouble();
    final double timeSaved40Km = (1.0 - timeRatio) * 3000.0;
    final double timeSaved200Km = (1.0 - timeRatio) * 16200.0; // ~4.5h etapu

    return BikeFitAeroReport(
      baselineCdA: baselineCdA,
      fittedCdA: fittedCdA,
      deltaCdA: totalDeltaCdA,
      stemAndSpacersAeroGainM2: stemAndSpacersAeroGain,
      cockpitWidthAeroGainM2: cockpitWidthAeroGain,
      hoodTiltAeroGainM2: hoodTiltAeroGain,
      crankLengthAeroGainM2: crankLengthAeroGain,
      saddlePositionAeroGainM2: saddlePositionAeroGain,
      wattsSavedAt45Kmh: watts45.round().clamp(0, 50),
      wattsSavedAt50Kmh: watts50.round().clamp(0, 75),
      timeSavedSecondsOver40Km: math.max(0.0, timeSaved40Km),
      timeSavedSecondsOver200Km: math.max(0.0, timeSaved200Km),
    );
  }

  // ===========================================================================
  // 3. BIOMECHANIKA, MIKROURAZY I SPADEK MOCY NA PODJAZDACH (1-3%)
  // ===========================================================================

  /// Wylicza wskaźniki mobilności, ryzyko kontuzji oraz karę mocy na podjazdach.
  static BiomechanicalFitImpact calculateBiomechanicalImpact({
    required BikeFitConfiguration fit,
    required RiderPhysiology physiology,
    RiderSkills? skills,
    int riderAge = 26,
  }) {
    // 1. Wyznaczenie mobilności / gibkości kolarza (Rider Mobility Score: 0 - 100)
    // Bazujemy na umiejętności aeroPositioning kolarza, modyfikowanej wiekiem
    double baseMobility = (skills?.aeroPositioning ?? 70).toDouble();

    // Wraz z wiekiem powyżej 29 lat elastyczność ścięgien podkolanowych i kręgosłupa naturalnie maleje
    if (riderAge > 29) {
      baseMobility -= (riderAge - 29) * 1.5;
    }
    // Budowa ciała: wyższy wzrost przy dużej masie stawia większe wyzwanie gibkościowe
    if (physiology.heightCm > 186.0) {
      baseMobility -= (physiology.heightCm - 186.0) * 0.8;
    }
    final double riderMobilityScore = baseMobility.clamp(25.0, 98.0);

    // 2. Wyznaczenie agresywności konfiguracji fittingu (0 - 100)
    double agg = 20.0;

    // Slammed stem (0 mm spacers) daje potężny spadek kierownicy
    if (fit.isSlammedStem) {
      agg += 32.0;
    } else {
      agg += math.max(0.0, (20 - fit.spacersStackMm) * 1.3);
    }

    // Wąska kierownica (360mm = +24 pkt, 380mm = +14 pkt)
    agg += math.max(0.0, (400 - fit.cockpitWidthMm) * 0.6);

    // Podgięcie klamek (>14° puppy paws)
    if (fit.hoodInwardTiltDegrees > 14.0) {
      agg += (fit.hoodInwardTiltDegrees - 14.0) * 1.1;
    }

    // Długi mostek (>120 mm)
    if (fit.stemLengthMm > 120) {
      agg += (fit.stemLengthMm - 120) * 0.8;
    }

    // Długa korba przy niskiej pozycji dodatkowo zamyka pozycję
    if (fit.crankArmLengthMm >= 175.0 && fit.isSlammedStem) {
      agg += 8.0;
    }

    final double positionAggressivenessScore = agg.clamp(20.0, 99.0);

    // 3. Niedopasowanie mobilności (Mobility Mismatch)
    final double mobilityMismatch =
        math.max(0.0, positionAggressivenessScore - riderMobilityScore);

    // 4. Kąt biodra w Górnym Martwym Punkcie (GMP / TDC) [°]
    // Krótsza korba (165mm) otwiera kąt biodra o 2.5–3.5°
    double hipAngle = 55.0;
    hipAngle -= (20 - fit.spacersStackMm) * 0.40;
    hipAngle += (172.5 - fit.crankArmLengthMm) * 0.35;
    hipAngle += fit.saddleTiltDegrees.abs() * 0.5;
    final double hipAngleAtTdc = hipAngle.clamp(38.0, 68.0);

    // 5. Spadek mocy na długich podjazdach o 1-3% (Climbing Power Penalty)
    // Zbyt agresywna pozycja (slammed stem + wąski kokpit 360mm) przy niedopasowanej gibkości
    // uciska klatkę piersiową, ogranicza wentylację płuc (VE) oraz przeponę na podjazdach:
    double climbingPenaltyPercent = 0.0;
    if (mobilityMismatch > 0.0) {
      // Skalowanie płynne od 1.0% do 3.0% w zależności od głębokości niedopasowania
      final double mismatchFraction = (mobilityMismatch / 45.0).clamp(0.0, 1.0);
      climbingPenaltyPercent = 0.010 + (mismatchFraction * 0.020); // DOKŁADNIE 1.0% do 3.0%
    }
    final double climbingPenaltyWatts = physiology.ftpWatts * climbingPenaltyPercent;

    // 6. Ryzyko mikrourazu kolan (Knee Microtrauma / Patellar Tendinitis)
    // Spowodowane przez: zbyt długie korby (175mm), zbyt niskie siodło, bloki przesunięte do przodu
    double kneeRisk = 20.0;
    if (fit.crankArmLengthMm >= 175.0) {
      kneeRisk += 25.0; // duży promień obrotu ściska staw rzepkowo-udowy
    } else if (fit.crankArmLengthMm <= 165.0) {
      kneeRisk -= 12.0; // krótka korba chroni rzepkę
    }

    // Przesunięcie bloków do przodu (toe-forward) zwiększa ramię dźwigni ścięgna
    if (fit.cleatOffsetMm > 2.0) {
      kneeRisk += fit.cleatOffsetMm * 2.2;
    } else if (fit.cleatOffsetMm < -3.0) {
      kneeRisk -= fit.cleatOffsetMm.abs() * 1.5; // mid-foot odciąża
    }

    // Zbyt niska pozycja przy zamkniętym kącie biodra
    if (hipAngleAtTdc < 45.0) {
      kneeRisk += (45.0 - hipAngleAtTdc) * 2.0;
    }

    final double kneeMicrotraumaRiskScore = kneeRisk.clamp(10.0, 95.0);

    // 7. Ryzyko mikrourazu i bólu odcinka lędźwiowego (Lower Back Microtrauma)
    // Wynika wprost z niedopasowania głębokości kokpitu (slammed stem) do mobilności kolarza
    double backRisk = 25.0;
    if (mobilityMismatch > 0.0) {
      backRisk += mobilityMismatch * 1.25;
    }
    if (fit.saddleTiltDegrees < -4.0) {
      backRisk += (fit.saddleTiltDegrees.abs() - 4.0) * 4.0; // zsuwanie się z siodła
    }
    if (fit.stemLengthMm >= 130) {
      backRisk += 10.0; // przeprost tułowia
    }
    final double lowerBackMicrotraumaRiskScore = backRisk.clamp(15.0, 98.0);

    // 8. Zmęczenie karku i odcinka szyjnego
    double neckRisk = 20.0;
    if (fit.isSlammedStem) neckRisk += 25.0;
    if (fit.stemLengthMm >= 130) neckRisk += 15.0;
    final double neckFatigueScore = neckRisk.clamp(15.0, 90.0);

    // 9. Ogólny komfort i przyspieszenie zmęczenia na długich etapach
    final double overallComfort = (100.0 - (mobilityMismatch * 0.8) - (kneeRisk * 0.2)).clamp(25.0, 98.0);
    final double fatigueMultiplier = 1.0 + (mobilityMismatch / 200.0).clamp(0.0, 0.22);

    return BiomechanicalFitImpact(
      riderMobilityScore: riderMobilityScore,
      positionAggressivenessScore: positionAggressivenessScore,
      mobilityMismatch: mobilityMismatch,
      climbingPowerPenaltyPercent: climbingPenaltyPercent,
      climbingPowerPenaltyWatts: climbingPenaltyWatts,
      kneeMicrotraumaRiskScore: kneeMicrotraumaRiskScore,
      lowerBackMicrotraumaRiskScore: lowerBackMicrotraumaRiskScore,
      neckFatigueScore: neckFatigueScore,
      overallComfortIndex: overallComfort,
      handlingStabilityIndex: fit.handlingControlScore,
      hipAngleAtTdcDegrees: hipAngleAtTdc,
      enduranceFatigueMultiplier: fatigueMultiplier,
    );
  }

  // ===========================================================================
  // 4. SYMULACJA W WIRTUALNYM TUNELU AERODYNAMICZNYM (YAW SWEEP)
  // ===========================================================================

  /// Przeprowadza symulację w tunelu aerodynamicznym badając opór przy kątach yaw od -20° do +20°.
  static WindTunnelPolarReport simulateWindTunnelSweep({
    required BikeFitConfiguration fit,
    required RiderPhysiology physiology,
    double airSpeedKmh = 45.0,
    double temperatureCelsius = 20.0,
    double altitudeMeters = 50.0,
  }) {
    final aeroReport = calculateAerodynamics(fit: fit, physiology: physiology);
    final double cdaZeroYaw = aeroReport.fittedCdA;
    final double airDensity = PhysicsConstants.getAirDensityAtAltitude(altitudeMeters);
    final double vAir = airSpeedKmh / 3.6;

    final points = <WindTunnelYawPoint>[];
    const yawAngles = [-20.0, -15.0, -10.0, -5.0, -2.5, 0.0, 2.5, 5.0, 10.0, 15.0, 20.0];

    double minCdA = cdaZeroYaw;
    double optimalYaw = 0.0;

    for (final yaw in yawAngles) {
      final double yawAbs = yaw.abs();

      // Nowoczesna aerodynamika: dla kątów yaw 5°–12° profile kół karbonowych i ramy
      // tworzą efekt żagla (sailing effect), obniżając opór o 2–5% przed oderwaniem strugi przy >15°
      double yawMultiplier = 1.0;
      if (yawAbs > 0.0 && yawAbs <= 12.0) {
        // Efekt żagla (Sailing effect)
        yawMultiplier = 1.0 - (math.sin(yawAbs * (math.pi / 18.0)) * 0.045);
      } else if (yawAbs > 12.0) {
        // Oderwanie strugi powietrza (Stall) i wzrost oporu
        yawMultiplier = 0.955 + ((yawAbs - 12.0) / 8.0) * 0.12;
      }

      final double currentCdA = cdaZeroYaw * yawMultiplier;
      if (currentCdA < minCdA) {
        minCdA = currentCdA;
        optimalYaw = yaw;
      }

      // Siła oporu wzdłużna [N]
      final double dragForce = 0.5 * airDensity * currentCdA * math.pow(vAir, 2) * math.cos(yaw * (math.pi / 180.0));

      // Siła boczna znosząca [N] proporcjonalna do kąta natarcia wiatru
      final double sideForce = 0.5 * airDensity * currentCdA * 1.65 * math.pow(vAir, 2) * math.sin(yawAbs * (math.pi / 180.0));

      // Wymagana moc aerodynamiczna [W]
      final double aeroPower = dragForce * vAir;

      points.add(
        WindTunnelYawPoint(
          yawDegrees: yaw,
          cda: currentCdA,
          dragForceNewtonsAt45Kmh: dragForce,
          sideForceNewtonsAt45Kmh: sideForce,
          aeroPowerWattsAt45Kmh: aeroPower,
        ),
      );
    }

    // Obliczenie średniego ważonego CdA (warunki szosowe: 70% czasu kąt 0-8°, 30% kąt 8-15°)
    double weightedSum = 0.0;
    double weightTotal = 0.0;
    for (final p in points) {
      final double w = math.exp(-math.pow(p.yawDegrees / 7.5, 2)); // rozkład Gaussa
      weightedSum += p.cda * w;
      weightTotal += w;
    }
    final double weightedAvgCdA = weightTotal > 0 ? weightedSum / weightTotal : cdaZeroYaw;

    final double sailingIndex = ((cdaZeroYaw - minCdA) / cdaZeroYaw).clamp(0.0, 0.15) * 10.0;

    return WindTunnelPolarReport(
      points: points,
      minCdA: minCdA,
      optimalYawDegrees: optimalYaw,
      weightedAverageCdA: weightedAvgCdA,
      sailingEffectIndex: sailingIndex,
    );
  }

  // ===========================================================================
  // 5. REKOMENDACJA I DOBÓR FITTINGU POD ETAP
  // ===========================================================================

  /// Dobiera optymalną konfigurację Bike Fittingu w zależności od profilu etapu.
  static BikeFitOptimizationRecommendation optimizeFitForStage({
    required StageType stageType,
    required RiderPhysiology physiology,
    RiderSkills? skills,
    int riderAge = 26,
  }) {
    switch (stageType) {
      case StageType.individualTimeTrial:
      case StageType.teamTimeTrial:
        final ttFit = BikeFitConfiguration.timeTrialAeroPursuit(
          saddleHeightMm: (physiology.heightCm * 10 * 0.465 * 0.885).roundToDouble(),
        );
        return BikeFitOptimizationRecommendation(
          stageType: stageType,
          title: 'Pozycja Czasowa TT (Aero Pursuit)',
          rationale: 'Maksymalizacja oszczędności watów na płaskim. Krótka korba 165mm otwiera kąt biodra.',
          recommendedFit: ttFit,
          estimatedWattsAdvantage: 35,
        );

      case StageType.highMountain:
      case StageType.summitFinish:
        // Na etapach górskich kluczowe jest zachowanie 100% mocy FTP bez kary ucisku przepony
        final climberFit = BikeFitConfiguration.climberLightweight(
          saddleHeightMm: (physiology.heightCm * 10 * 0.465 * 0.883).roundToDouble(),
        );
        return BikeFitOptimizationRecommendation(
          stageType: stageType,
          title: 'Pozycja Wspinaczkowa (Otwarta Klatka)',
          rationale: 'Kierownica 400mm i 10mm podkładek zapobiegają 1-3% stracie mocy na podjazdach Alpe d\'Huez / Stelvio.',
          recommendedFit: climberFit,
          estimatedWattsAdvantage: 12,
        );

      case StageType.cobbleClassic:
        final cobbledFit = BikeFitConfiguration.cobbledEnduranceComfort(
          saddleHeightMm: (physiology.heightCm * 10 * 0.465 * 0.880).roundToDouble(),
        );
        return BikeFitOptimizationRecommendation(
          stageType: stageType,
          title: 'Stabilność na Brukach (Roubaix Endurance)',
          rationale: 'Szeroka kierownica 420mm i 20mm spacerów zapewniają maksymalną kontrolę w błocie i na kocich łbach.',
          recommendedFit: cobbledFit,
          estimatedWattsAdvantage: 8,
        );

      case StageType.flat:
      case StageType.hilly:
        // Na płaskich etapach z wiatrem warto zastosować pozycję super-aero, jeśli zawodnik jest gibki
        final isFlexible = (skills?.aeroPositioning ?? 70) >= 68 && riderAge <= 33;
        final roadFit = isFlexible
            ? BikeFitConfiguration.slammedAeroRoad(
                saddleHeightMm: (physiology.heightCm * 10 * 0.465 * 0.883).roundToDouble(),
              )
            : BikeFitConfiguration.uciWorldTourBalanced(
                saddleHeightMm: (physiology.heightCm * 10 * 0.465 * 0.883).roundToDouble(),
              );

        return BikeFitOptimizationRecommendation(
          stageType: stageType,
          title: isFlexible ? 'Super-Aero Slammed Road' : 'WorldTour Zrównoważony',
          rationale: isFlexible
              ? 'Darmowe ~24 Waty przy 45 km/h dzięki węższemu kokpitowi 360mm i brakowi podkładek.'
              : 'Bezpieczny balans aero i sterowności bez ryzyka przeciążenia pleców.',
          recommendedFit: roadFit,
          estimatedWattsAdvantage: isFlexible ? 24 : 14,
        );
    }
  }

  // ===========================================================================
  // 6. GENEROWANIE PORAD SZTABU SZKOLENIOWO-MEDYCZNEGO
  // ===========================================================================

  static List<String> _generateCoachingAdvice(
    BikeFitConfiguration fit,
    BikeFitAeroReport aero,
    BiomechanicalFitImpact bio,
  ) {
    final advice = <String>[];

    // Zyski aero
    advice.add(
      'Zysk aerodynamiczny: CdA ${aero.fittedCdA.toStringAsFixed(3)} m² (-${aero.cdaSavingsPercent.toStringAsFixed(1)}%). '
      'Zyskujesz darmowe +${aero.wattsSavedAt45Kmh} W przy 45 km/h.',
    );

    // Kary na podjazdach
    if (bio.isClimbingCompromised) {
      advice.add(
        'UWAGA W GÓRACH: Zbyt agresywny spadek kierownicy ogranicza wentylację płuc VE kolarza. '
        'Spadek mocy na podjazdach wynosi -${bio.climbingPowerPenaltyPercent.toStringAsFixed(1)}% '
        '(-${bio.climbingPowerPenaltyWatts.round()} W na progu FTP). Rozważ dodanie 5-10 mm podkładek!',
      );
    } else {
      advice.add(
        'Optymalne otwarcie klatki piersiowej: brak strat mocy na wspinaczkach górskich (0.0% kary FTP).',
      );
    }

    // Ryzyko kolan
    if (bio.kneeMicrotraumaRiskScore >= 65.0) {
      advice.add(
        'RYZYKO KONTUZJI KOLANA: Kąt biodra w GMP wynosi ${bio.hipAngleAtTdcDegrees.toStringAsFixed(1)}°. '
        'Zalecane skrócenie korby z ${fit.crankArmLengthMm}mm do 165mm oraz cofnięcie bloków (mid-foot), '
        'aby zredukować nacisk na rzepkę.',
      );
    }

    // Ryzyko pleców
    if (bio.lowerBackMicrotraumaRiskScore >= 65.0) {
      advice.add(
        'OBCIĄŻENIE LĘDŹWI: Pozycja przekracza aktualną gibkość kolarza o ${bio.mobilityMismatch.round()} pkt. '
        'Na etapach powyżej 160 km zmęczenie pleców przyspieszy o ${(bio.enduranceFatigueMultiplier * 100 - 100).round()}%.',
      );
    }

    // Sterowność i klamki UCI
    if (fit.hasExtremeAeroHoods) {
      advice.add(
        'PUNKTY SĘDZIOWSKIE UCI: Podgięcie klamek o ${fit.hoodInwardTiltDegrees.round()}° przekracza limit UCI 14.0°. '
        'Pewność chwytu przy gwałtownym hamowaniu wynosi tylko ${bio.handlingStabilityIndex.round()}/100.',
      );
    }

    return advice;
  }
}

