import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/descender_attack_and_supertuck_physics.dart';

void main() {
  group('DescenderAttackAndSupertuckPhysics', () {
    test('wykrywa kwalifikację do ataku wyłącznie przy descending >= 85 i bikeHandling >= 85', () {
      final eligible = DescenderAttackAndSupertuckPhysics.evaluateSummitAttackEligibility(
        descendingSkill: 85,
        bikeHandlingSkill: 85,
        upcomingGradientPercent: -7.5,
        descentLengthKm: 15.0,
        hairpinCount: 18,
      );
      expect(eligible.canAttack, isTrue);
      expect(eligible.meetsDescendingThreshold, isTrue);
      expect(eligible.meetsBikeHandlingThreshold, isTrue);
      expect(eligible.reasonCode, 'eligible_for_summit_attack');

      final lowDescending =
          DescenderAttackAndSupertuckPhysics.evaluateSummitAttackEligibility(
        descendingSkill: 84,
        bikeHandlingSkill: 92,
        upcomingGradientPercent: -7.5,
        descentLengthKm: 15.0,
        hairpinCount: 18,
      );
      expect(lowDescending.canAttack, isFalse);
      expect(lowDescending.reasonCode, 'descending_below_85');

      final lowHandling =
          DescenderAttackAndSupertuckPhysics.evaluateSummitAttackEligibility(
        descendingSkill: 92,
        bikeHandlingSkill: 84,
        upcomingGradientPercent: -7.5,
        descentLengthKm: 15.0,
        hairpinCount: 18,
      );
      expect(lowHandling.canAttack, isFalse);
      expect(lowHandling.reasonCode, 'bike_handling_below_85');

      final lowWPrime =
          DescenderAttackAndSupertuckPhysics.evaluateSummitAttackEligibility(
        descendingSkill: 90,
        bikeHandlingSkill: 90,
        upcomingGradientPercent: -7.5,
        descentLengthKm: 15.0,
        hairpinCount: 18,
        wPrimeRemainingFraction: 0.05,
      );
      expect(lowWPrime.canAttack, isFalse);
      expect(lowWPrime.reasonCode, 'insufficient_w_prime_reserve');
    });

    test('pozycja Supertuck na ramie istotnie redukuje CdA względem chwytów i dolnego chwytu', () {
      final dropsCda = DescenderAttackAndSupertuckPhysics.computeEffectiveCdA(
        posture: DescenderAeroPosture.drops,
        aeroPositioningSkill: 88,
        descendingSkill: 90,
      );
      final supertuckCda = DescenderAttackAndSupertuckPhysics.computeEffectiveCdA(
        posture: DescenderAeroPosture.supertuckTopTube,
        aeroPositioningSkill: 88,
        descendingSkill: 90,
      );

      expect(supertuckCda, lessThan(dropsCda * 0.80));
      expect(supertuckCda, inInclusiveRange(0.195, 0.240));
    });

    test('późne hamowanie przed serpentynami daje realną przewagę metrów i wyższą prędkość w apexie', () {
      final eliteApex = DescenderAttackAndSupertuckPhysics.computeHairpinApexSpeedMs(
        descendingSkill: 94,
        bikeHandlingSkill: 92,
        hairpinRadiusMeters: 19.0,
        surfaceGripMultiplier: 1.0,
      );
      final pelotonApex = DescenderAttackAndSupertuckPhysics.computeHairpinApexSpeedMs(
        descendingSkill: 72,
        bikeHandlingSkill: 72,
        hairpinRadiusMeters: 19.0,
        surfaceGripMultiplier: 1.0,
      );
      expect(eliteApex, greaterThan(pelotonApex));

      final braking = DescenderAttackAndSupertuckPhysics.computeLateBrakingProfile(
        descendingSkill: 94,
        bikeHandlingSkill: 92,
        entrySpeedMs: 22.0,
        apexSpeedMs: eliteApex,
        surfaceGripMultiplier: 1.0,
      );
      expect(braking.decelerationMs2, greaterThan(6.0));
      expect(braking.lateBrakingMeters, greaterThan(5.0));
    });

    test('elitarny zjazdowiec (85+ / 85+) zyskuje 25-45 s na 15 km technicznego zjazdu', () {
      const baselineProDescender = DescenderAttackInput(
        riderId: 'mohoric_88',
        descendingSkill: 86,
        bikeHandlingSkill: 86,
        aeroPositioningSkill: 82,
        descentLengthKm: 15.0,
        averageGradientPercent: -7.5,
        hairpinCount: 18,
      );
      final summary86 =
          DescenderAttackAndSupertuckPhysics.simulateFullDescent(baselineProDescender);

      expect(summary86.attackExecuted, isTrue);
      expect(summary86.timeGainSeconds, inInclusiveRange(25.0, 45.0));
      expect(summary86.timeSavedFromLateBrakingSeconds, greaterThan(0.0));
      expect(summary86.timeSavedFromSupertuckAeroSeconds, greaterThan(0.0));
      expect(summary86.timeSavedFromSummitAttackSeconds, greaterThan(0.0));
      expect(summary86.supertuckActivePercentage, greaterThan(30.0));
      expect(summary86.peakSpeedKmh, greaterThan(70.0));

      final worldClassDescender = baselineProDescender.copyWith(
        riderId: 'pidcock_96',
        descendingSkill: 96,
        bikeHandlingSkill: 95,
        aeroPositioningSkill: 92,
      );
      final summary96 =
          DescenderAttackAndSupertuckPhysics.simulateFullDescent(worldClassDescender);

      expect(summary96.attackExecuted, isTrue);
      expect(summary96.timeGainSeconds, inInclusiveRange(25.0, 45.0));
      expect(summary96.timeGainSeconds, greaterThan(summary86.timeGainSeconds));
    });

    test('kolarz poniżej progu 85 nie odpala ataku supertuck na szczycie', () {
      const nonDescender = DescenderAttackInput(
        riderId: 'climber_78',
        descendingSkill: 78,
        bikeHandlingSkill: 80,
        descentLengthKm: 15.0,
        averageGradientPercent: -7.5,
        hairpinCount: 18,
      );
      final summary =
          DescenderAttackAndSupertuckPhysics.simulateFullDescent(nonDescender);

      expect(summary.attackExecuted, isFalse);
      expect(summary.supertuckActivePercentage, 0.0);
      expect(summary.timeGainSeconds, lessThan(25.0));
    });

    test('krok symulacji stepDescentPhysics przełącza fazy i pozycję na ramie', () {
      const input = DescenderAttackInput(
        riderId: 'step_rider',
        descendingSkill: 92,
        bikeHandlingSkill: 90,
      );

      final summitStep = DescenderAttackAndSupertuckPhysics.stepDescentPhysics(
        input: input,
        currentSpeedMs: 12.0,
        distanceCoveredMeters: 30.0,
        elapsedTimeSeconds: 3.0,
        distanceToNextHairpinMeters: 600.0,
        baselineSpeedMs: 10.5,
        cumulativeTimeGainSeconds: 0.0,
      );
      expect(summitStep.activePhase, DescenderAttackPhase.summitLaunch);
      expect(summitStep.activePosture, DescenderAeroPosture.drops);

      final supertuckStep = DescenderAttackAndSupertuckPhysics.stepDescentPhysics(
        input: input,
        currentSpeedMs: 21.0,
        distanceCoveredMeters: 1200.0,
        elapsedTimeSeconds: 45.0,
        distanceToNextHairpinMeters: 450.0,
        baselineSpeedMs: 18.5,
        cumulativeTimeGainSeconds: 4.0,
      );
      expect(supertuckStep.activePhase, DescenderAttackPhase.supertuckChute);
      expect(supertuckStep.activePosture, DescenderAeroPosture.supertuckTopTube);

      final brakingStep = DescenderAttackAndSupertuckPhysics.stepDescentPhysics(
        input: input,
        currentSpeedMs: 22.0,
        distanceCoveredMeters: 1500.0,
        elapsedTimeSeconds: 60.0,
        distanceToNextHairpinMeters: 28.0,
        baselineSpeedMs: 18.0,
        cumulativeTimeGainSeconds: 6.0,
      );
      expect(brakingStep.activePhase, DescenderAttackPhase.lateBrakingEntry);
      expect(brakingStep.brakingDecelerationMs2, greaterThan(5.0));
    });
  });
}
