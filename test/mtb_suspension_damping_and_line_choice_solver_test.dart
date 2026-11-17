import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/mtb_suspension_damping_and_line_choice_solver.dart';
import 'package:pro_peloton_manager/models/race/mtb_xco_course_and_suspension_model.dart';

void main() {
  group('MtbSuspensionDampingAndLineChoiceSolver', () {
    test('open lockout absorbs more rock garden chatter than locked mode', () {
      final course = MtbXcoCourseAndSuspensionModel.noveMestoWorldCup();
      final rockGarden = course.segments.firstWhere(
        (s) => s.featureType == MtbXcoFeatureType.rockGarden,
      );

      const bikeOpen = MtbXcoBikeConfiguration(
        bikeId: 'fs_120',
        modelName: 'Factory XC 120',
        suspension: MtbForkAndShockSetup(
          architecture: MtbSuspensionArchitecture.fullSuspensionDowncountry120,
          forkTravelMm: 120,
          rearShockTravelMm: 120,
          remoteLockoutMode: SuspensionLockoutMode.open,
        ),
      );

      final bikeLocked = bikeOpen.copyWith(
        suspension: bikeOpen.suspension.copyWith(
          remoteLockoutMode: SuspensionLockoutMode.locked,
          hasElectronicFlightAttendant: false,
        ),
      );

      final resOpen = MtbSuspensionDampingAndLineChoiceSolver.solveSegment(
        MtbSuspensionAndLineInput(
          segment: rockGarden,
          bikeConfig: bikeOpen,
          soilCondition: MtbTrailSoilCondition.tackyLoam,
          approachSpeedMps: 8.5,
          deterministicRoll: 0.99,
        ),
      );

      final resLocked = MtbSuspensionDampingAndLineChoiceSolver.solveSegment(
        MtbSuspensionAndLineInput(
          segment: rockGarden,
          bikeConfig: bikeLocked,
          soilCondition: MtbTrailSoilCondition.tackyLoam,
          approachSpeedMps: 8.5,
          deterministicRoll: 0.99,
        ),
      );

      expect(
        resOpen.dampingMetrics.dampingAbsorptionRatio,
        greaterThan(resLocked.dampingMetrics.dampingAbsorptionRatio),
      );
      expect(
        resOpen.dampingMetrics.unabsorbedChatterWatts,
        lessThan(resLocked.dampingMetrics.unabsorbedChatterWatts),
      );
      expect(
        resOpen.dampingMetrics.vibrationFatigueIndex,
        lessThan(resLocked.dampingMetrics.vibrationFatigueIndex),
      );
    });

    test('locked mode eliminates pedal bob on steep smooth climbs', () {
      const smoothClimb = MtbXcoCourseSegment(
        index: 0,
        name: 'Smooth Steep Climb',
        startMeter: 0.0,
        lengthMeters: 450.0,
        featureType: MtbXcoFeatureType.punchyClimb,
        gradientPercent: 14.0,
        roughnessIndex: 0.12,
      );

      const bikeOpen = MtbXcoBikeConfiguration(
        bikeId: 'fs_120',
        modelName: 'Factory XC 120',
        suspension: MtbForkAndShockSetup(
          remoteLockoutMode: SuspensionLockoutMode.open,
          hasElectronicFlightAttendant: false,
        ),
      );

      final bikeLocked = bikeOpen.copyWith(
        suspension: bikeOpen.suspension.copyWith(
          remoteLockoutMode: SuspensionLockoutMode.locked,
        ),
      );

      final resOpen = MtbSuspensionDampingAndLineChoiceSolver.solveSegment(
        const MtbSuspensionAndLineInput(
          segment: smoothClimb,
          bikeConfig: bikeOpen,
          powerWatts: 420.0,
          isOutOfSaddle: true,
          deterministicRoll: 0.99,
        ),
      );

      final resLocked = MtbSuspensionDampingAndLineChoiceSolver.solveSegment(
        MtbSuspensionAndLineInput(
          segment: smoothClimb,
          bikeConfig: bikeLocked,
          powerWatts: 420.0,
          isOutOfSaddle: true,
          deterministicRoll: 0.99,
        ),
      );

      expect(
        resLocked.dampingMetrics.pedalBobLossWatts,
        lessThan(resOpen.dampingMetrics.pedalBobLossWatts),
      );
      expect(
        resLocked.netEffectivePowerWatts,
        greaterThan(resOpen.netEffectivePowerWatts),
      );
    });

    test('A-Line vs B-Line selection responds to rider skill, policy, and conditions', () {
      final course = MtbXcoCourseAndSuspensionModel.noveMestoWorldCup();
      final dropSegment = course.segments.firstWhere(
        (s) => s.featureType == MtbXcoFeatureType.dropOff,
      );

      const proBike = MtbXcoBikeConfiguration(
        bikeId: 'pro_120',
        modelName: 'Pro XCO 120',
        suspension: MtbForkAndShockSetup(
          forkTravelMm: 120,
          rearShockTravelMm: 120,
          hasElectronicFlightAttendant: true,
        ),
        dropperPost: DropperPostSpec(
          travelMm: 125,
          isWirelessElectronic: true,
        ),
      );

      final aggressiveRes = MtbSuspensionDampingAndLineChoiceSolver.solveSegment(
        MtbSuspensionAndLineInput(
          segment: dropSegment,
          bikeConfig: proBike,
          soilCondition: MtbTrailSoilCondition.tackyLoam,
          bikeHandling: 94.0,
          descendingSkill: 92.0,
          linePolicy: MtbLineTacticalPolicy.aggressiveALine,
          deterministicRoll: 0.99,
        ),
      );

      final conservativeRes =
          MtbSuspensionDampingAndLineChoiceSolver.solveSegment(
        MtbSuspensionAndLineInput(
          segment: dropSegment,
          bikeConfig: proBike,
          soilCondition: MtbTrailSoilCondition.wetRootsAndRock,
          bikeHandling: 62.0,
          descendingSkill: 60.0,
          wPrimeRemainingRatio: 0.15,
          linePolicy: MtbLineTacticalPolicy.conservativeBLine,
          deterministicRoll: 0.99,
        ),
      );

      expect(aggressiveRes.chosenLine, MtbTrailLineChoice.aLine);
      expect(aggressiveRes.outcome, MtbSegmentOutcome.cleanFastALine);
      expect(aggressiveRes.timeAdvantageOverBLineSeconds, greaterThan(0.0));

      expect(conservativeRes.chosenLine, MtbTrailLineChoice.bLine);
      expect(conservativeRes.outcome, MtbSegmentOutcome.cleanSafeBLine);
      expect(
        conservativeRes.bLineEvaluation!.adjustedCrashRisk,
        lessThan(conservativeRes.aLineEvaluation!.adjustedCrashRisk),
      );
    });

    test('2.4 inch tire tread and pressure affect grip on muddy and wet trails', () {
      const rootSegment = MtbXcoCourseSegment(
        index: 1,
        name: 'Wet Roots',
        startMeter: 100.0,
        lengthMeters: 300.0,
        featureType: MtbXcoFeatureType.rootSection,
        gradientPercent: 12.0,
        roughnessIndex: 0.75,
        rootDensityPerMeter: 2.5,
      );

      const mudTireBike = MtbXcoBikeConfiguration(
        bikeId: 'mud_bike',
        modelName: 'Mud XCO',
        tireSetup: MtbTire24Setup(
          widthInches: 2.4,
          treadPattern: MtbTireTreadPattern.aggressiveMudSpike,
          frontPressureBar: 1.25,
          rearPressureBar: 1.32,
          hasRimInsert: true,
        ),
      );

      const slickTireBike = MtbXcoBikeConfiguration(
        bikeId: 'slick_bike',
        modelName: 'Dry XCO',
        tireSetup: MtbTire24Setup(
          widthInches: 2.4,
          treadPattern: MtbTireTreadPattern.fastSemiSlick,
          frontPressureBar: 1.75,
          rearPressureBar: 1.80,
          hasRimInsert: false,
        ),
      );

      final mudRes = MtbSuspensionDampingAndLineChoiceSolver.solveSegment(
        const MtbSuspensionAndLineInput(
          segment: rootSegment,
          bikeConfig: mudTireBike,
          soilCondition: MtbTrailSoilCondition.muddyRut,
          powerWatts: 400.0,
          deterministicRoll: 0.99,
        ),
      );

      final slickRes = MtbSuspensionDampingAndLineChoiceSolver.solveSegment(
        const MtbSuspensionAndLineInput(
          segment: rootSegment,
          bikeConfig: slickTireBike,
          soilCondition: MtbTrailSoilCondition.muddyRut,
          powerWatts: 400.0,
          deterministicRoll: 0.99,
        ),
      );

      expect(
        mudRes.dampingMetrics.tire24GripMu,
        greaterThan(slickRes.dampingMetrics.tire24GripMu),
      );
      expect(
        mudRes.dampingMetrics.maxCorneringSpeedMps,
        greaterThan(slickRes.dampingMetrics.maxCorneringSpeedMps),
      );
    });

    test('deterministicRoll triggers incident when below crash risk threshold', () {
      final course = MtbXcoCourseAndSuspensionModel.noveMestoWorldCup();
      final dropSegment = course.segments.firstWhere(
        (s) => s.featureType == MtbXcoFeatureType.dropOff,
      );

      const bike = MtbXcoBikeConfiguration(
        bikeId: 'test_bike',
        modelName: 'Test XC',
      );

      final crashResult = MtbSuspensionDampingAndLineChoiceSolver.solveSegment(
        MtbSuspensionAndLineInput(
          segment: dropSegment,
          bikeConfig: bike,
          soilCondition: MtbTrailSoilCondition.wetRootsAndRock,
          linePolicy: MtbLineTacticalPolicy.forcedALine,
          deterministicRoll: 0.001,
        ),
      );

      expect(crashResult.outcome, MtbSegmentOutcome.lineCrash);
      expect(crashResult.incidentTimePenaltySeconds, greaterThan(5.0));
    });

    test('simulateLap computes complete lap telemetry for World Cup and Olympic courses', () {
      final noveMesto = MtbXcoCourseAndSuspensionModel.noveMestoWorldCup();
      const bike = MtbXcoBikeConfiguration(
        bikeId: 'wc_bike',
        modelName: 'World Cup 120',
        suspension: MtbForkAndShockSetup(
          hasElectronicFlightAttendant: true,
        ),
      );

      final summary = MtbSuspensionDampingAndLineChoiceSolver.simulateLap(
        course: noveMesto,
        bikeConfig: bike,
        riderMassKg: 66.0,
        basePowerWatts: 360.0,
        bikeHandling: 90.0,
        descendingSkill: 88.0,
        deterministicRoll: 0.99,
      );

      expect(summary.segmentResults.length, noveMesto.segments.length);
      expect(summary.totalLapTimeSeconds, greaterThan(300.0));
      expect(summary.totalDistanceMeters, closeTo(4200.0, 1.0));
      expect(summary.aLinesTaken + summary.bLinesTaken, greaterThan(0));
      expect(summary.averageDampingAbsorption, inInclusiveRange(0.5, 1.0));
    });

    test('recommendOptimalSetup provides sensible values for course and mass', () {
      final olympic = MtbXcoCourseAndSuspensionModel.olympicXcoDefault();
      final rec = MtbSuspensionDampingAndLineChoiceSolver.recommendOptimalSetup(
        course: olympic,
        riderMassKg: 68.0,
      );

      expect(rec.recommendedForkPsi, inInclusiveRange(70.0, 110.0));
      expect(rec.recommendedRearShockPsi, inInclusiveRange(130.0, 200.0));
      expect(rec.recommendedFrontTireBar, inInclusiveRange(1.05, 1.85));
      expect(rec.recommendedRearTireBar, greaterThan(rec.recommendedFrontTireBar));
      expect(rec.recommendedTravelMm, 120);
    });
  });
}
