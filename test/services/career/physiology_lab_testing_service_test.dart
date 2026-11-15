// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/services/career/physiology_lab_testing_service.dart';
import 'package:pro_peloton_manager/services/career/training_and_camps_service.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';

void main() {
  group('PhysiologyLabTestingService - Protokół Stopniowany (Ramp Test 100W, +30W / 3 min)', () {
    test('Przeprowadza próbę stopniowaną z ergospirometrią i mikronakłuciami krwi co 3 minuty', () {
      final rider = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.gcClimber,
        targetOverallRating: 88,
      );

      final report = PhysiologyLabTestingService.conductRampTest(
        rider: rider,
        testDate: DateTime(2026, 3, 15),
      );

      expect(report.riderId, rider.id);
      expect(report.riderName, rider.fullName);
      expect(report.steps.isNotEmpty, isTrue);

      // Weryfikacja pierwszego stopnia (100W, 180s)
      final step1 = report.steps.first;
      expect(step1.stepNumber, 1);
      expect(step1.powerWatts, 100);
      expect(step1.elapsedSeconds, 180);
      expect(step1.isBloodSampleTaken, isTrue);
      expect(step1.bloodLactateMmolL, lessThanOrEqualTo(1.8));
      expect(step1.minuteVentilationVE, inInclusiveRange(28.0, 50.0));
      expect(step1.respiratoryExchangeRatioRER, inInclusiveRange(0.70, 0.88));

      // Weryfikacja kolejnych kroków (+30W, +180s na stopień)
      for (int i = 1; i < report.steps.length; i++) {
        final prev = report.steps[i - 1];
        final curr = report.steps[i];

        expect(curr.stepNumber, prev.stepNumber + 1);
        expect(curr.powerWatts, prev.powerWatts + 30);
        expect(curr.elapsedSeconds, prev.elapsedSeconds + 180);
        expect(curr.heartRateBpm, greaterThanOrEqualTo(prev.heartRateBpm));
        expect(curr.minuteVentilationVE, greaterThanOrEqualTo(prev.minuteVentilationVE));
        expect(curr.bloodLactateMmolL, greaterThanOrEqualTo(prev.bloodLactateMmolL - 0.1));
      }

      // Weryfikacja wentylacji płuc na progach LT1 i LT2
      expect(report.measuredLt1Ventilation, inInclusiveRange(50.0, 85.0));
      expect(report.measuredLt2Ventilation, inInclusiveRange(90.0, 140.0));
      expect(report.measuredMaxVentilation, inInclusiveRange(140.0, 220.0));

      // Weryfikacja wyznaczonych progów
      expect(report.measuredLt1Watts, greaterThan(150));
      expect(report.measuredLt2Watts, greaterThan(report.measuredLt1Watts));
      expect(report.measuredMaxAerobicPowerWatts, greaterThan(report.measuredLt2Watts));
      expect(report.measuredVo2MaxMlKgMin, greaterThan(65.0));
    });

    test('Wyznacza kompletne 7 stref treningowych kolarza opartych na LT1 i LT2', () {
      final rider = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.timeTrialist,
        targetOverallRating: 85,
      );

      final report = PhysiologyLabTestingService.conductRampTest(
        rider: rider,
      );

      expect(report.trainingZones.length, 7);
      expect(report.trainingZones[0].code, 'Z1');
      expect(report.trainingZones[1].code, 'Z2');
      expect(report.trainingZones[1].maxWatts, report.measuredLt1Watts);
      expect(report.trainingZones[3].code, 'Z4'); // Threshold LT2
      expect(report.trainingZones[4].code, 'Z5'); // VO2max
      expect(report.trainingZones[6].code, 'Z7'); // Neuromuscular
    });
  });

  group('PhysiologyLabTestingService - Wykrywanie kierunku adaptacji (VLaMax & VO2max)', () {
    test('Wykrywa skuteczne obniżenie VLaMax u górala po treningu bazy tlenowej / progu', () {
      final climber = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.gcClimber,
        targetOverallRating: 88,
      );

      final baselineProfile = climber.labProfile.copyWith(
        vlaMaxMmolLPerSec: 0.44, // Wyższe bazowe tempo glikolizy
        lt1Watts: 280,
        lt2Watts: 385,
        vo2MaxMlKgMin: 82.0,
      );

      // Przeprowadzamy test po bloku budowy bazy tlenowej (baseBuilding)
      final report = PhysiologyLabTestingService.conductRampTest(
        rider: climber,
        previousProfile: baselineProfile,
        previousTestDate: DateTime(2026, 1, 15),
        testDate: DateTime(2026, 3, 1),
        recentFocus: RiderTrainingFocus.baseBuilding,
      );

      expect(report.trendAnalysis.isVlaMaxDecreasedForClimber, isTrue);
      expect(report.trendAnalysis.vlaMaxDeltaMmolLPerSec, lessThan(0.0));
      expect(report.trendAnalysis.isTrainingGoingInRightDirection, isTrue);
      expect(
        report.trendAnalysis.verdict == AdaptationVerdict.glycolysisSuppressed ||
            report.trendAnalysis.verdict == AdaptationVerdict.optimalProgress ||
            report.trendAnalysis.verdict == AdaptationVerdict.thresholdShiftedRight,
        isTrue,
      );
      expect(report.trendAnalysis.adaptationScore, greaterThanOrEqualTo(80));
    });

    test('Wykrywa powiększenie pułapu tlenowego (VO2max) po interwałach Z5', () {
      final puncheur = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.puncher,
        targetOverallRating: 86,
      );

      final baselineProfile = puncheur.labProfile.copyWith(
        vo2MaxMlKgMin: 78.0,
        powerAtVo2MaxWatts: 470,
      );

      final report = PhysiologyLabTestingService.conductRampTest(
        rider: puncheur,
        previousProfile: baselineProfile,
        previousTestDate: DateTime(2026, 2, 1),
        testDate: DateTime(2026, 3, 15),
        recentFocus: RiderTrainingFocus.vo2maxIntervals,
      );

      expect(report.trendAnalysis.isVo2MaxIncreased, isTrue);
      expect(report.trendAnalysis.vo2MaxDeltaMlKgMin, greaterThanOrEqualTo(0.5));
      expect(report.trendAnalysis.isTrainingGoingInRightDirection, isTrue);
      expect(
        report.trendAnalysis.verdict == AdaptationVerdict.aerobicCeilingExpanded ||
            report.trendAnalysis.verdict == AdaptationVerdict.optimalProgress,
        isTrue,
      );
    });

    test('Wykrywa wzmocnienie eksplozywności i podbicie VLaMax u sprintera po treningu sprintu', () {
      final sprinter = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.pureSprinter,
        targetOverallRating: 87,
      );

      final baselineProfile = sprinter.labProfile.copyWith(
        vlaMaxMmolLPerSec: 0.76,
      );

      final report = PhysiologyLabTestingService.conductRampTest(
        rider: sprinter,
        previousProfile: baselineProfile,
        recentFocus: RiderTrainingFocus.sprintNeuromuscular,
      );

      expect(report.trendAnalysis.vlaMaxDeltaMmolLPerSec, greaterThan(0.02));
      expect(
        report.trendAnalysis.verdict,
        AdaptationVerdict.sprinterExplosivenessEnhanced,
      );
      expect(report.trendAnalysis.isTrainingGoingInRightDirection, isTrue);
    });

    test('Wykrywa syndrom przeciążenia / przetrenowania (Overreaching)', () {
      final rider = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.gcClimber,
        targetOverallRating: 85,
      );

      final report = PhysiologyLabTestingService.conductRampTest(
        rider: rider,
        simulateOvertraining: true,
      );

      expect(report.trendAnalysis.verdict, AdaptationVerdict.overreachingDetected);
      expect(report.trendAnalysis.isTrainingGoingInRightDirection, isFalse);
      expect(report.trendAnalysis.adaptationScore, lessThan(50));
      expect(report.diagnosticSummary.contains('UWAGA MEDYCZNA'), isTrue);
      expect(report.coachRecommendations.any((r) => r.contains('regenerac')), isTrue);
    });
  });

  group('PhysiologyLabTestingService - Integracja i aktualizacja stanu kolarza', () {
    test('conductTeamFleetScreening bada całą kadrę zespołu', () {
      final riders = [
        RiderProceduralGenerator.generateRider(specialization: RiderSpecialization.gcClimber),
        RiderProceduralGenerator.generateRider(specialization: RiderSpecialization.pureSprinter),
        RiderProceduralGenerator.generateRider(specialization: RiderSpecialization.timeTrialist),
      ];

      final reports = PhysiologyLabTestingService.conductTeamFleetScreening(
        riders: riders,
        testDate: DateTime(2026, 4, 1),
      );

      expect(reports.length, 3);
      expect(reports[0].riderSpecialization, RiderSpecialization.gcClimber);
      expect(reports[1].riderSpecialization, RiderSpecialization.pureSprinter);
      expect(reports[2].riderSpecialization, RiderSpecialization.timeTrialist);
    });

    test('applyReportToRider aktualizuje FTP, VO2max i profil laboratoryjny zawodnika', () {
      final rider = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.pureClimber,
        targetOverallRating: 84,
      );

      final report = PhysiologyLabTestingService.conductRampTest(
        rider: rider,
        recentFocus: RiderTrainingFocus.ftpDevelopment,
      );

      final updatedRider = PhysiologyLabTestingService.applyReportToRider(rider, report);

      expect(updatedRider.physiology.ftpWatts, report.measuredLt2Watts);
      expect(updatedRider.physiology.criticalPowerWatts, report.measuredLt2Watts);
      expect(updatedRider.physiology.vo2Max, report.measuredVo2MaxMlKgMin);
      expect(updatedRider.physiology.labProfile, equals(report.newLabProfile));
      expect(updatedRider.powerProfile.watts60m, report.measuredLt2Watts);
      expect(updatedRider.powerProfile.watts5m, report.measuredMaxAerobicPowerWatts);
    });

    test('toPhysiologicalTestResult konwertuje raport na strukturę modułu finansowo-karierowego', () {
      final rider = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.puncher,
      );

      final report = PhysiologyLabTestingService.conductRampTest(rider: rider);
      final testResult = report.toPhysiologicalTestResult();

      expect(testResult.riderId, rider.id);
      expect(testResult.measuredFtpWatts, report.measuredLt2Watts.toDouble());
      expect(testResult.measuredVo2Max, report.measuredVo2MaxMlKgMin);
      expect(testResult.lactateThresholdWatts, report.measuredLt2Watts.toDouble());
      expect(testResult.labProfile, equals(report.newLabProfile));
    });

    test('Serializacja toJson i deserializacja fromJson raportu działa bezstratnie', () {
      final rider = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.gcClimber,
      );

      final report = PhysiologyLabTestingService.conductRampTest(rider: rider);
      final json = report.toJson();
      final restored = PhysiologyLabTestReport.fromJson(json);

      expect(restored.riderId, report.riderId);
      expect(restored.measuredLt1Watts, report.measuredLt1Watts);
      expect(restored.measuredLt2Watts, report.measuredLt2Watts);
      expect(restored.measuredVlaMax, report.measuredVlaMax);
      expect(restored.measuredVo2MaxMlKgMin, report.measuredVo2MaxMlKgMin);
      expect(restored.steps.length, report.steps.length);
      expect(restored.trainingZones.length, report.trainingZones.length);
      expect(restored.trendAnalysis.verdict, report.trendAnalysis.verdict);
    });
  });
}
