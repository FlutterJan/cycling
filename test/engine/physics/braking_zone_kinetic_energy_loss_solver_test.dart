import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/braking_zone_kinetic_energy_loss_solver.dart';
import 'package:pro_peloton_manager/engine/physics/wet_cornering_grip_and_braking_solver.dart';
import 'package:pro_peloton_manager/models/equipment/wheelset_model.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

void main() {
  group('BrakingZoneKineticEnergyLossSolver', () {
    const lightClimbingWheelset = WheelsetModel(
      id: 'ws_light_33',
      brandId: 'b1',
      name: 'FeatherLite 33mm',
      rimDepthMm: 33,
      weightGrams: 1180,
      aeroCdaModifier: -0.002,
      crosswindStabilityPenalty: 0.05,
      momentOfInertia: 0.088,
      hubEngagementDragWatts: 1.2,
      priceEur: 2800,
    );

    const deepAeroWheelset = WheelsetModel(
      id: 'ws_aero_65',
      brandId: 'b1',
      name: 'AeroBlade 65mm',
      rimDepthMm: 65,
      weightGrams: 1620,
      aeroCdaModifier: -0.015,
      crosswindStabilityPenalty: 0.65,
      momentOfInertia: 0.148,
      hubEngagementDragWatts: 1.4,
      priceEur: 3100,
    );

    test('computes translational and rotational energy loss for 180 hairpin', () {
      const corner = BrakingCornerSpec(
        id: 'hp1',
        name: 'Station Hairpin',
        geometryType: CornerGeometryType.hairpin180,
        radiusMeters: 6.5,
        arcAngleDegrees: 180.0,
        entrySpeedMs: 14.0,
      );
      const config = BrakingZoneRiderConfig(
        riderMassKg: 70.0,
        bikeMassKg: 7.2,
        wheelset: lightClimbingWheelset,
        pelotonPositionFactor: 0.0,
      );

      final result = BrakingZoneKineticEnergyLossSolver.evaluateCornerBrakingZone(
        corner: corner,
        config: config,
      );

      expect(result.severity, isNot(BrakingZoneSeverity.noBrakingNeeded));
      expect(result.apexSpeedMs, lessThan(result.entrySpeedMs));
      expect(result.translationalEnergyLossJoules, greaterThan(3000.0));
      expect(result.rotationalEnergyLossJoules, greaterThan(30.0));
      expect(
        result.totalKineticEnergyLossJoules,
        closeTo(
          result.translationalEnergyLossJoules + result.rotationalEnergyLossJoules,
          1e-6,
        ),
      );
      expect(result.brakingDistanceMeters, greaterThan(4.0));
      expect(result.timeLostSeconds, greaterThan(0.5));
      expect(result.reaccelerationPeakPowerWatts, greaterThan(config.riderFtpWatts));
      expect(result.wPrimeDepletedJoules, greaterThan(0.0));
    });

    test('returns noBrakingNeeded when entry speed is below apex limit', () {
      const sweeper = BrakingCornerSpec(
        id: 'sw1',
        name: 'Fast Sweeper',
        geometryType: CornerGeometryType.sweeper,
        radiusMeters: 45.0,
        arcAngleDegrees: 40.0,
        entrySpeedMs: 11.0,
      );
      const config = BrakingZoneRiderConfig(pelotonPositionFactor: 0.0);

      final result = BrakingZoneKineticEnergyLossSolver.evaluateCornerBrakingZone(
        corner: sweeper,
        config: config,
      );

      expect(result.severity, BrakingZoneSeverity.noBrakingNeeded);
      expect(result.totalKineticEnergyLossJoules, 0.0);
      expect(result.brakingDistanceMeters, 0.0);
      expect(result.timeLostSeconds, 0.0);
    });

    test('wet surface and carbon rim brakes increase braking distance and loss', () {
      const corner = BrakingCornerSpec(
        id: 'c_wet',
        name: 'Cobble Chicane',
        geometryType: CornerGeometryType.chicane,
        radiusMeters: 9.0,
        arcAngleDegrees: 110.0,
        entrySpeedMs: 13.5,
        surfaceType: SegmentSurfaceType.cobblestonesSector2,
      );

      const dryDisc = BrakingZoneRiderConfig(
        surfaceWetness: 0.0,
        brakeSystem: BrakeSystemType.hydraulicDisc,
        pelotonPositionFactor: 0.0,
      );
      const wetRim = BrakingZoneRiderConfig(
        surfaceWetness: 1.0,
        brakeSystem: BrakeSystemType.carbonRim,
        pelotonPositionFactor: 0.0,
      );

      final dryRes = BrakingZoneKineticEnergyLossSolver.evaluateCornerBrakingZone(
        corner: corner,
        config: dryDisc,
      );
      final wetRes = BrakingZoneKineticEnergyLossSolver.evaluateCornerBrakingZone(
        corner: corner,
        config: wetRim,
      );

      expect(wetRes.apexSpeedMs, lessThan(dryRes.apexSpeedMs));
      expect(
        wetRes.totalKineticEnergyLossJoules,
        greaterThan(dryRes.totalKineticEnergyLossJoules),
      );
      expect(wetRes.brakingDistanceMeters, greaterThan(dryRes.brakingDistanceMeters));
      expect(wetRes.timeLostSeconds, greaterThan(dryRes.timeLostSeconds));
    });

    test('peloton accordion effect increases energy loss at the back of the pack', () {
      const corner = BrakingCornerSpec(
        id: 'c90',
        name: 'Urban 90',
        geometryType: CornerGeometryType.ninetyDegreeTurn,
        radiusMeters: 11.0,
        arcAngleDegrees: 90.0,
        entrySpeedMs: 13.8,
      );

      const frontConfig = BrakingZoneRiderConfig(pelotonPositionFactor: 0.0);
      const tailConfig = BrakingZoneRiderConfig(pelotonPositionFactor: 1.0);

      final frontRes = BrakingZoneKineticEnergyLossSolver.evaluateCornerBrakingZone(
        corner: corner,
        config: frontConfig,
      );
      final tailRes = BrakingZoneKineticEnergyLossSolver.evaluateCornerBrakingZone(
        corner: corner,
        config: tailConfig,
      );

      expect(tailRes.accordionExtraLossJoules, greaterThan(0.0));
      expect(
        tailRes.totalKineticEnergyLossJoules,
        greaterThan(frontRes.totalKineticEnergyLossJoules),
      );
      expect(tailRes.timeLostSeconds, greaterThan(frontRes.timeLostSeconds));
    });

    test('evaluates full 40-lap urban criterium with VI inflation and brake heating', () {
      final corners = BrakingZoneKineticEnergyLossSolver.urbanFourCornerCriterium();
      const config = BrakingZoneRiderConfig(
        wheelset: lightClimbingWheelset,
        pelotonPositionFactor: 0.65,
      );

      final profile =
          BrakingZoneKineticEnergyLossSolver.evaluateCourseBrakingProfile(
        discipline: BrakingCourseDiscipline.urbanCriterium,
        lapCorners: corners,
        config: config,
        laps: 40,
      );

      expect(profile.laps, 40);
      expect(profile.totalBrakingEvents, 120);
      expect(profile.totalKineticEnergyLossKj, greaterThan(400.0));
      expect(profile.totalRotationalLossKj, greaterThan(4.0));
      expect(profile.variabilityIndex, greaterThan(1.05));
      expect(profile.peakBrakeTempCelsius, greaterThan(22.0));
      expect(profile.cornerResults.length, corners.length);
    });

    test('compares lightweight vs deep aero wheelsets on technical criterium', () {
      final techCorners =
          BrakingZoneKineticEnergyLossSolver.technicalEightCornerCriterium();
      const baseConfig = BrakingZoneRiderConfig(
        riderMassKg: 68.0,
        pelotonPositionFactor: 0.45,
      );

      final comparison =
          BrakingZoneKineticEnergyLossSolver.compareWheelsetsOnCourse(
        discipline: BrakingCourseDiscipline.urbanCriterium,
        lapCorners: techCorners,
        baseConfig: baseConfig,
        wheelsetA: deepAeroWheelset,
        wheelsetB: lightClimbingWheelset,
        laps: 30,
      );

      expect(comparison.rotationalEnergySavedKj, greaterThan(0.0));
      expect(comparison.kineticEnergySavedKj, greaterThan(0.0));
      expect(
        comparison.netTimeDeltaSeconds,
        closeTo(
          comparison.aeroStraightTimeDeltaSeconds +
              comparison.cornerReaccelTimeDeltaSeconds,
          1e-6,
        ),
      );
      expect(comparison.summaryReasonPl, isNotEmpty);
      expect(comparison.summaryReasonEn, isNotEmpty);
    });

    test('handles empty corner list safely without NaN', () {
      final profile =
          BrakingZoneKineticEnergyLossSolver.evaluateCourseBrakingProfile(
        discipline: BrakingCourseDiscipline.twistyTimeTrial,
        lapCorners: const [],
        config: const BrakingZoneRiderConfig(),
        laps: 0,
      );

      expect(profile.laps, 1);
      expect(profile.totalBrakingEvents, 0);
      expect(profile.totalKineticEnergyLossKj, 0.0);
      expect(profile.variabilityIndex, 1.0);
    });
  });
}
