import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/services/career/altitude_camp_acclimatization_curve.dart';

void main() {
  const curve = AltitudeCampAcclimatizationCurve();

  group('AltitudeCampAcclimatizationCurve', () {
    test('days 1-5 after descent model post-descent adaptation with light leg heaviness', () {
      for (final site in AltitudeCampSite.values) {
        for (int day = 1; day <= 5; day++) {
          final point = curve.evaluateDay(
            campSite: site,
            daysSinceDescent: day,
          );
          expect(point.phase, AltitudeAcclimatizationPhase.postDescentAdaptation);
          expect(point.hasPostDescentLegHeaviness, isTrue);
          expect(point.legHeavinessPenalty, greaterThan(0.0));
          expect(point.vo2maxBoostPercent, 0.0);
          expect(point.wPrimeRecoveryBoostPercent, 0.0);
        }
      }
    });

    test('days 7-24 after camp deliver +3.5% VO2max and W-prime recovery supercompensation', () {
      for (final site in AltitudeCampSite.values) {
        for (int day = 7; day <= 24; day++) {
          final point = curve.evaluateDay(
            campSite: site,
            daysSinceDescent: day,
            campDurationDays: 21,
          );
          expect(
            point.phase,
            AltitudeAcclimatizationPhase.hematocritSupercompensation,
          );
          expect(point.isInSupercompensationWindow, isTrue);
          expect(point.hasPostDescentLegHeaviness, isFalse);
          expect(point.legHeavinessPenalty, 0.0);
          expect(point.vo2maxBoostPercent, closeTo(3.5, 0.01));
          expect(point.vo2maxMultiplier, closeTo(1.035, 0.0001));
          expect(point.wPrimeRecoveryBoostPercent, closeTo(3.5, 0.01));
          expect(point.wPrimeRecoveryMultiplier, closeTo(1.035, 0.0001));
          expect(point.hematocritDeltaPercentagePoints, greaterThan(1.5));
          expect(point.hemoglobinMassBoostPercent, greaterThan(4.0));
        }
      }
    });

    test('day 6 transitions smoothly and days > 32 return to baseline', () {
      final day6 = curve.evaluateDay(
        campSite: AltitudeCampSite.sierraNevada,
        daysSinceDescent: 6,
      );
      expect(day6.phase, AltitudeAcclimatizationPhase.transitionStabilization);
      expect(day6.legHeavinessPenalty, 0.0);
      expect(day6.vo2maxBoostPercent, greaterThan(0.0));
      expect(day6.vo2maxBoostPercent, lessThan(3.5));

      final day28 = curve.evaluateDay(
        campSite: AltitudeCampSite.teide,
        daysSinceDescent: 28,
      );
      expect(day28.phase, AltitudeAcclimatizationPhase.decayAndWashout);
      expect(day28.vo2maxBoostPercent, greaterThan(0.0));
      expect(day28.vo2maxBoostPercent, lessThan(3.5));

      final day35 = curve.evaluateDay(
        campSite: AltitudeCampSite.livigno,
        daysSinceDescent: 35,
      );
      expect(day35.phase, AltitudeAcclimatizationPhase.baseline);
      expect(day35.vo2maxMultiplier, 1.0);
      expect(day35.wPrimeRecoveryMultiplier, 1.0);
      expect(day35.hematocritDeltaPercentagePoints, 0.0);
    });

    test('applyToPhysiology updates vo2Max, recoveryRate and fatigue accurately', () {
      const basePhysiology = RiderPhysiology(
        heightCm: 178.0,
        weightKg: 64.0,
        bodyFatPercentage: 5.5,
        ftpWatts: 410,
        wPrimeJoules: 22000,
        vo2Max: 80.0,
        maxHr: 192,
        restingHr: 38,
        lactateThresholdHr: 174,
        recoveryRate: 1.0,
        glycogenCapacityGrams: 550.0,
        fatigue: 20.0,
      );

      final adapted = curve.applyToPhysiology(
        basePhysiology,
        campSite: AltitudeCampSite.sierraNevada,
        daysSinceDescent: 2,
      );
      expect(adapted.fatigue, greaterThan(basePhysiology.fatigue));
      expect(adapted.vo2Max, 80.0);

      final supercompensated = curve.applyToPhysiology(
        basePhysiology,
        campSite: AltitudeCampSite.teide,
        daysSinceDescent: 14,
      );
      expect(supercompensated.vo2Max, closeTo(82.8, 0.05));
      expect(supercompensated.recoveryRate, closeTo(1.035, 0.001));
      expect(supercompensated.fatigue, 20.0);
    });

    test('generateCurve, recommendPeakWindow and JSON round-trip work', () {
      final points = curve.generateCurve(
        campSite: AltitudeCampSite.livigno,
        fromDay: 0,
        toDay: 32,
      );
      expect(points.length, 33);

      final jsonRoundTrip =
          AltitudeCampAcclimatizationPoint.fromJson(points[14].toJson());
      expect(jsonRoundTrip.campSite, AltitudeCampSite.livigno);
      expect(jsonRoundTrip.daysSinceDescent, 14);
      expect(jsonRoundTrip.vo2maxBoostPercent, points[14].vo2maxBoostPercent);

      final rec = curve.recommendPeakWindow(
        campSite: AltitudeCampSite.sierraNevada,
      );
      expect(rec.supercompensationStartDay, 7);
      expect(rec.supercompensationEndDay, 24);
      expect(rec.peakVo2maxBoostPercent, closeTo(3.5, 0.01));
    });
  });
}
