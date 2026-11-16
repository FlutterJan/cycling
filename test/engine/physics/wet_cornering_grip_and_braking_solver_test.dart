import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/constants/physics_constants.dart';
import 'package:pro_peloton_manager/engine/physics/wet_cornering_grip_and_braking_solver.dart';
import 'package:pro_peloton_manager/models/equipment/tire_model.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

void main() {
  group('WetCorneringGripAndBrakingSolver', () {
    test('bazowe współczynniki tarcia odpowiadają dry ~0.85, wet ~0.55, wet cobble ~0.40', () {
      final dryAsphalt = WetCorneringGripAndBrakingSolver.calculateBaseSurfaceFriction(
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        surfaceWetness: 0.0,
      );
      final wetAsphalt = WetCorneringGripAndBrakingSolver.calculateBaseSurfaceFriction(
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        surfaceWetness: 1.0,
      );
      final wetCobble = WetCorneringGripAndBrakingSolver.calculateBaseSurfaceFriction(
        surfaceType: SegmentSurfaceType.cobblestonesSector3,
        surfaceWetness: 1.0,
      );

      expect(dryAsphalt, closeTo(0.85, 0.001));
      expect(wetAsphalt, closeTo(0.55, 0.001));
      expect(wetCobble, closeTo(0.40, 0.001));
    });

    test('maksymalna prędkość w zakręcie spełnia v_max = sqrt(mu * g * R)', () {
      const double mu = 0.55;
      const double radius = 30.0;
      final expected = math.sqrt(mu * PhysicsConstants.gravity * radius);

      final actual = WetCorneringGripAndBrakingSolver.calculateMaxCorneringSpeedMs(
        frictionMu: mu,
        cornerRadiusMeters: radius,
      );

      expect(actual, closeTo(expected, 1e-6));

      final banked = WetCorneringGripAndBrakingSolver.calculateMaxCorneringSpeedMs(
        frictionMu: mu,
        cornerRadiusMeters: radius,
        roadCamberDegrees: 8.0,
      );
      expect(banked, greaterThan(actual));
    });

    test('mieszanka opony i wetGripIndex wpływają na przyczepność w deszczu', () {
      const wetTire = TireModel(
        id: 't1',
        brandId: 'b1',
        name: 'All Season Wet Pro',
        widthMm: 30,
        weightGrams: 265,
        rollingResistanceCrr: 0.0038,
        punctureResistanceIndex: 4.0,
        wetGripIndex: 4.8,
        isTubeless: true,
        priceEur: 85,
      );
      const ttTire = TireModel(
        id: 't2',
        brandId: 'b1',
        name: 'Aero TT Slick',
        widthMm: 25,
        weightGrams: 205,
        rollingResistanceCrr: 0.0029,
        punctureResistanceIndex: 1.5,
        wetGripIndex: 1.5,
        isTubeless: true,
        priceEur: 95,
      );

      final muWetCompound = WetCorneringGripAndBrakingSolver.calculateEffectiveFrictionMu(
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        surfaceWetness: 1.0,
        tireCompound: TireCompoundType.allSeasonWet,
        tirePressureBar: 5.0,
        tireModel: wetTire,
      );
      final muHardTt = WetCorneringGripAndBrakingSolver.calculateEffectiveFrictionMu(
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        surfaceWetness: 1.0,
        tireCompound: TireCompoundType.hardTimeTrial,
        tirePressureBar: 5.0,
        tireModel: ttTire,
      );

      expect(muWetCompound, greaterThan(muHardTt));
    });

    test('przepompowana opona obniża przyczepność szczególnie na mokrym bruku', () {
      final optimalBar = WetCorneringGripAndBrakingSolver.estimateOptimalPressureBar(
        tireWidthMm: 30,
        surfaceType: SegmentSurfaceType.cobblestonesSector3,
        surfaceWetness: 1.0,
      );

      final muOptimal = WetCorneringGripAndBrakingSolver.calculateEffectiveFrictionMu(
        surfaceType: SegmentSurfaceType.cobblestonesSector3,
        surfaceWetness: 1.0,
        tireCompound: TireCompoundType.cobbleReinforced,
        tirePressureBar: optimalBar,
        optimalPressureBar: optimalBar,
      );
      final muOverinflated = WetCorneringGripAndBrakingSolver.calculateEffectiveFrictionMu(
        surfaceType: SegmentSurfaceType.cobblestonesSector3,
        surfaceWetness: 1.0,
        tireCompound: TireCompoundType.cobbleReinforced,
        tirePressureBar: 7.5,
        optimalPressureBar: optimalBar,
      );

      expect(muOptimal, greaterThan(muOverinflated));
    });

    test('nadmierny kąt pochylenia w deszczu obniża efektywne tarcie', () {
      final muModerateLean = WetCorneringGripAndBrakingSolver.calculateEffectiveFrictionMu(
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        surfaceWetness: 0.9,
        tireCompound: TireCompoundType.standardRace,
        tirePressureBar: 5.2,
        leanAngleDegrees: 18.0,
      );
      final muExcessiveLean = WetCorneringGripAndBrakingSolver.calculateEffectiveFrictionMu(
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        surfaceWetness: 0.9,
        tireCompound: TireCompoundType.standardRace,
        tirePressureBar: 5.2,
        leanAngleDegrees: 48.0,
      );

      expect(muModerateLean, greaterThan(muExcessiveLean));
    });

    test('hamowanie przed ciasnym mokrym nawrotem i wykrywanie poślizgu przy zbyt dużej prędkości', () {
      final resultTooFast = WetCorneringGripAndBrakingSolver.solve(
        const WetCorneringInput(
          cornerRadiusMeters: 14.0,
          currentSpeedMs: 18.5, // ~66.6 km/h
          distanceToCornerMeters: 15.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          surfaceWetness: 1.0,
          tirePressureBar: 6.5,
          roadGradientPercent: -8.0,
          descendingSkill: 60,
          bikeHandlingSkill: 60,
        ),
      );

      expect(resultTooFast.needsBraking, isTrue);
      expect(resultTooFast.canBrakeInTime, isFalse);
      expect(resultTooFast.riskLevel, CorneringRiskLevel.criticalSlip);
      expect(resultTooFast.slipProbability, greaterThan(0.0));
      expect(resultTooFast.brakingDistanceMeters, greaterThan(15.0));

      final resultSafe = WetCorneringGripAndBrakingSolver.solve(
        const WetCorneringInput(
          cornerRadiusMeters: 45.0,
          currentSpeedMs: 12.0, // ~43.2 km/h
          distanceToCornerMeters: 80.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          surfaceWetness: 0.0,
          tirePressureBar: 5.6,
          descendingSkill: 85,
        ),
      );

      expect(resultSafe.needsBraking, isFalse);
      expect(resultSafe.canBrakeInTime, isTrue);
      expect(resultSafe.riskLevel, CorneringRiskLevel.safe);
      expect(resultSafe.slipProbability, 0.0);
    });

    test('hamulce tarczowe hydrauliczne mają większe opóźnienie w deszczu niż karbonowe szczękowe', () {
      final disc = WetCorneringGripAndBrakingSolver.solve(
        const WetCorneringInput(
          cornerRadiusMeters: 25.0,
          currentSpeedMs: 16.0,
          distanceToCornerMeters: 40.0,
          surfaceWetness: 1.0,
          brakeSystem: BrakeSystemType.hydraulicDisc,
        ),
      );
      final carbonRim = WetCorneringGripAndBrakingSolver.solve(
        const WetCorneringInput(
          cornerRadiusMeters: 25.0,
          currentSpeedMs: 16.0,
          distanceToCornerMeters: 40.0,
          surfaceWetness: 1.0,
          brakeSystem: BrakeSystemType.carbonRim,
        ),
      );

      expect(disc.maxBrakingDecelerationMs2, greaterThan(carbonRim.maxBrakingDecelerationMs2));
      expect(disc.brakingDistanceMeters, lessThan(carbonRim.brakingDistanceMeters));
    });

    test('obsługuje wartości brzegowe bez NaN lub dzielenia przez zero', () {
      final edge = WetCorneringGripAndBrakingSolver.solve(
        const WetCorneringInput(
          cornerRadiusMeters: -5.0,
          currentSpeedMs: 0.0,
          distanceToCornerMeters: 0.0,
          surfaceWetness: 2.0,
          tirePressureBar: 0.5,
        ),
      );

      expect(edge.maxCorneringSpeedMs.isFinite, isTrue);
      expect(edge.effectiveFrictionMu.isFinite, isTrue);
      expect(edge.gripUtilization.isFinite, isTrue);
      expect(edge.needsBraking, isFalse);
    });
  });
}
