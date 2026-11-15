// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/bike_fit_and_wind_tunnel_engine.dart';
import 'package:pro_peloton_manager/models/equipment/bike_fit_configuration.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';

void main() {
  const samplePhysiology = RiderPhysiology(
    heightCm: 178.0,
    weightKg: 68.0,
    bodyFatPercentage: 6.8,
    ftpWatts: 420,
    wPrimeJoules: 24000,
    vo2Max: 84.5,
    maxHr: 198,
    restingHr: 39,
    lactateThresholdHr: 176,
    recoveryRate: 88.0,
    glycogenCapacityGrams: 520.0,
  );

  const flexibleSkills = RiderSkills(
    cobbles: 70,
    descending: 85,
    bikeHandling: 85,
    aeroPositioning: 90, // Wysoka mobilność i gibkość
    draftingEfficiency: 88,
    raceIq: 85,
    rainResistance: 80,
    heatTolerance: 82,
    timeTrialPositioning: 92,
  );

  const stiffSkills = RiderSkills(
    cobbles: 70,
    descending: 70,
    bikeHandling: 72,
    aeroPositioning: 35, // Niska mobilność / sztywny tułów
    draftingEfficiency: 75,
    raceIq: 78,
    rainResistance: 70,
    heatTolerance: 75,
    timeTrialPositioning: 40,
  );

  group('BikeFitAndWindTunnelEngine - Aerodynamika & Darmowe Waty', () {
    test('Slammed stem (0mm), wąski kokpit (360mm) i podgięte klamki redukują CdA', () {
      final baselineFit = BikeFitConfiguration.cobbledEnduranceComfort(); // 420mm, 20mm spacers, 4° hoods
      final aeroFit = BikeFitConfiguration.slammedAeroRoad(); // 360mm, 0mm spacers, 22° hoods

      final aeroReport = BikeFitAndWindTunnelEngine.calculateAerodynamics(
        fit: aeroFit,
        physiology: samplePhysiology,
      );

      final baselineReport = BikeFitAndWindTunnelEngine.calculateAerodynamics(
        fit: baselineFit,
        physiology: samplePhysiology,
      );

      expect(aeroReport.fittedCdA, lessThan(baselineReport.fittedCdA));
      expect(aeroReport.deltaCdA, lessThan(0.0));
      expect(aeroReport.cdaSavingsPercent, greaterThan(3.0));

      // Sprawdzenie poszczególnych komponentów zysku aero
      expect(aeroReport.stemAndSpacersAeroGainM2, lessThan(0.0));
      expect(aeroReport.cockpitWidthAeroGainM2, lessThan(0.0));
      expect(aeroReport.hoodTiltAeroGainM2, lessThan(0.0));
    });

    test('Generuje darmowe waty przy 45 km/h i 50 km/h w pozycji aero', () {
      final aeroFit = BikeFitConfiguration.slammedAeroRoad();
      final aeroReport = BikeFitAndWindTunnelEngine.calculateAerodynamics(
        fit: aeroFit,
        physiology: samplePhysiology,
      );

      expect(aeroReport.wattsSavedAt45Kmh, greaterThanOrEqualTo(15));
      expect(aeroReport.wattsSavedAt50Kmh, greaterThan(aeroReport.wattsSavedAt45Kmh));

      // Zysk czasu na 40 km TT i 200 km płaskiego etapu
      expect(aeroReport.timeSavedSecondsOver40Km, greaterThan(30.0));
      expect(aeroReport.timeSavedSecondsOver200Km, greaterThan(150.0));
    });

    test('Krótsze ramiona korby (165mm vs 175mm) otwierają kąt biodra i dają zysk aero', () {
      final shortCrankFit = BikeFitConfiguration.uciWorldTourBalanced().copyWith(
        crankArmLengthMm: 165.0,
      );
      final longCrankFit = BikeFitConfiguration.uciWorldTourBalanced().copyWith(
        crankArmLengthMm: 175.0,
      );

      final shortReport = BikeFitAndWindTunnelEngine.calculateAerodynamics(
        fit: shortCrankFit,
        physiology: samplePhysiology,
      );
      final longReport = BikeFitAndWindTunnelEngine.calculateAerodynamics(
        fit: longCrankFit,
        physiology: samplePhysiology,
      );

      expect(shortReport.crankLengthAeroGainM2, lessThan(longReport.crankLengthAeroGainM2));

      final bioShort = BikeFitAndWindTunnelEngine.calculateBiomechanicalImpact(
        fit: shortCrankFit,
        physiology: samplePhysiology,
      );
      final bioLong = BikeFitAndWindTunnelEngine.calculateBiomechanicalImpact(
        fit: longCrankFit,
        physiology: samplePhysiology,
      );

      expect(bioShort.hipAngleAtTdcDegrees, greaterThan(bioLong.hipAngleAtTdcDegrees));
    });
  });

  group('BikeFitAndWindTunnelEngine - Wpływ Biomechaniczny i Spadek Mocy w Górach', () {
    test('Kolarz o wysokiej mobilności nie traci mocy na podjazdach w wyważonej pozycji', () {
      final fit = BikeFitConfiguration.uciWorldTourBalanced();
      final impact = BikeFitAndWindTunnelEngine.calculateBiomechanicalImpact(
        fit: fit,
        physiology: samplePhysiology,
        skills: flexibleSkills,
        riderAge: 24,
      );

      expect(impact.mobilityMismatch, equals(0.0));
      expect(impact.climbingPowerPenaltyPercent, equals(0.0));
      expect(impact.climbingPowerPenaltyWatts, equals(0.0));
      expect(impact.isClimbingCompromised, isFalse);
    });

    test('Zbyt agresywny fitting u mało gibkiego kolarza obniża moc na podjazdach o 1-3%', () {
      // Ekstremalny setup slammed 0mm, wąski 360mm na sztywnym kolarzu
      final aggressiveFit = BikeFitConfiguration.slammedAeroRoad();
      final impact = BikeFitAndWindTunnelEngine.calculateBiomechanicalImpact(
        fit: aggressiveFit,
        physiology: samplePhysiology,
        skills: stiffSkills,
        riderAge: 34,
      );

      expect(impact.mobilityMismatch, greaterThan(0.0));
      // DOKŁADNIE w przedziale 1.0% do 3.0%
      expect(impact.climbingPowerPenaltyPercent, greaterThanOrEqualTo(0.010));
      expect(impact.climbingPowerPenaltyPercent, lessThanOrEqualTo(0.030));
      expect(impact.climbingPowerPenaltyWatts, greaterThan(4.0));
      expect(impact.isClimbingCompromised, isTrue);
    });

    test('Zbyt niska pozycja u sztywnego kolarza drastycznie zwiększa ryzyko urazu pleców', () {
      final aggressiveFit = BikeFitConfiguration.slammedAeroRoad();
      final impact = BikeFitAndWindTunnelEngine.calculateBiomechanicalImpact(
        fit: aggressiveFit,
        physiology: samplePhysiology,
        skills: stiffSkills,
        riderAge: 35,
      );

      expect(impact.lowerBackMicrotraumaRiskScore, greaterThan(65.0));
      expect(impact.hasHighInjuryRisk, isTrue);
      expect(impact.enduranceFatigueMultiplier, greaterThan(1.05));
    });

    test('Długa korba 175mm i bloki do przodu zwiększają ryzyko mikrourazu kolan', () {
      final badKneeFit = BikeFitConfiguration.uciWorldTourBalanced().copyWith(
        crankArmLengthMm: 175.0,
        cleatOffsetMm: 6.0,
        spacersStackMm: 0,
      );

      final safeKneeFit = BikeFitConfiguration.uciWorldTourBalanced().copyWith(
        crankArmLengthMm: 165.0,
        cleatOffsetMm: -6.0,
        spacersStackMm: 10,
      );

      final badImpact = BikeFitAndWindTunnelEngine.calculateBiomechanicalImpact(
        fit: badKneeFit,
        physiology: samplePhysiology,
      );

      final safeImpact = BikeFitAndWindTunnelEngine.calculateBiomechanicalImpact(
        fit: safeKneeFit,
        physiology: samplePhysiology,
      );

      expect(badImpact.kneeMicrotraumaRiskScore, greaterThan(safeImpact.kneeMicrotraumaRiskScore));
    });
  });

  group('BikeFitAndWindTunnelEngine - Wirtualny Tunel Aerodynamiczny (Yaw Sweep)', () {
    test('SimulateWindTunnelSweep bada kąty od -20 do +20 stopni i wykazuje efekt żagla', () {
      final fit = BikeFitConfiguration.uciWorldTourBalanced();
      final polar = BikeFitAndWindTunnelEngine.simulateWindTunnelSweep(
        fit: fit,
        physiology: samplePhysiology,
      );

      expect(polar.points.length, equals(11));
      expect(polar.points.first.yawDegrees, equals(-20.0));
      expect(polar.points.last.yawDegrees, equals(20.0));

      // Sprawdzenie czy przy kącie 5-10° występuje efekt żagla (spadek CdA)
      final zeroYaw = polar.points.firstWhere((p) => p.yawDegrees == 0.0);
      final sailingYaw = polar.points.firstWhere((p) => p.yawDegrees == 5.0 || p.yawDegrees == 10.0);

      expect(sailingYaw.cda, lessThanOrEqualTo(zeroYaw.cda));
      expect(polar.minCdA, lessThanOrEqualTo(zeroYaw.cda));
      expect(polar.sailingEffectIndex, greaterThan(0.0));
    });
  });

  group('BikeFitAndWindTunnelEngine - Optymalizacja pod Profil Etapu', () {
    test('Dla etapu górskiego rekomenduje fitting wspinaczkowy bez kary mocy', () {
      final rec = BikeFitAndWindTunnelEngine.optimizeFitForStage(
        stageType: StageType.summitFinish,
        physiology: samplePhysiology,
      );

      expect(rec.stageType, equals(StageType.summitFinish));
      expect(rec.recommendedFit.cockpitWidthMm, equals(400));
      expect(rec.recommendedFit.spacersStackMm, greaterThan(0));

      final bio = BikeFitAndWindTunnelEngine.calculateBiomechanicalImpact(
        fit: rec.recommendedFit,
        physiology: samplePhysiology,
      );
      expect(bio.climbingPowerPenaltyPercent, equals(0.0));
    });

    test('Dla jazdy na czas (TT) rekomenduje aero pursuit z krótkimi korbami', () {
      final rec = BikeFitAndWindTunnelEngine.optimizeFitForStage(
        stageType: StageType.individualTimeTrial,
        physiology: samplePhysiology,
      );

      expect(rec.stageType, equals(StageType.individualTimeTrial));
      expect(rec.recommendedFit.crankArmLengthMm, equals(165.0));
      expect(rec.recommendedFit.isSlammedStem, isTrue);
    });

    test('Dla bruków Roubaix rekomenduje szeroki kokpit i wysoki komfort', () {
      final rec = BikeFitAndWindTunnelEngine.optimizeFitForStage(
        stageType: StageType.cobbleClassic,
        physiology: samplePhysiology,
      );

      expect(rec.recommendedFit.cockpitWidthMm, equals(420));
      expect(rec.recommendedFit.spacersStackMm, equals(20));
    });
  });

  group('BikeFitAndWindTunnelEngine - Pełny Raport Ewaluacji', () {
    test('EvaluateFit zwraca kompletny raport z praktycznymi poradami trenerskimi', () {
      final fit = BikeFitConfiguration.slammedAeroRoad();
      final report = BikeFitAndWindTunnelEngine.evaluateFit(
        fit: fit,
        physiology: samplePhysiology,
        skills: stiffSkills,
        riderAge: 32,
      );

      expect(report.configuration, equals(fit));
      expect(report.aeroReport.wattsSavedAt45Kmh, greaterThan(10));
      expect(report.biomechanicalImpact.isClimbingCompromised, isTrue);
      expect(report.coachingAdvice, isNotEmpty);
      expect(report.coachingAdvice.any((a) => a.contains('Zysk aerodynamiczny')), isTrue);
      expect(report.coachingAdvice.any((a) => a.contains('UWAGA W GÓRACH')), isTrue);
    });
  });
}

