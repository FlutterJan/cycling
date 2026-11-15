// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/staff_member.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/services/career/winter_offseason_training_service.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';

void main() {
  group('WinterOffSeasonTrainingService - 1. Ćwiczenia Siłowe i Cross-Training', () {
    test('GymExerciseType definiuje bułgary, RDL i front squats z poprawnymi korzyściami', () {
      const bss = GymExerciseType.bulgarianSplitSquats;
      const rdl = GymExerciseType.romanianDeadlift;
      const fs = GymExerciseType.frontSquats;

      expect(bss.displayName, contains('Bulgarian Split Squats'));
      expect(bss.primaryMuscles, contains('pasmo ITB'));
      expect(bss.injuryPreventionBonus, greaterThan(0.20));

      expect(rdl.displayName, contains('Romanian Deadlift'));
      expect(rdl.primaryMuscles, contains('hamstrings'));
      expect(rdl.injuryPreventionBonus, greaterThan(0.20));

      expect(fs.displayName, contains('Front Squats'));
      expect(fs.primaryMuscles, contains('core'));
      expect(fs.biomechanicalBenefits, contains('włókna IIx'));
    });

    test('CrossTrainingType definiuje narty biegowe, ergometr i bieganie tempowe', () {
      const ski = CrossTrainingType.crossCountrySkiing;
      const row = CrossTrainingType.rowingErgometer;
      const run = CrossTrainingType.tempoRunning;

      // Narty biegowe dają najwyższy bodziec tlenowy
      expect(ski.vo2maxStimulusFactor, equals(1.00));
      expect(ski.description, contains('WorldTour'));

      // Ergometr angażuje górną obręcz
      expect(row.description, contains('85% masy mięśniowej'));
      expect(row.vo2maxStimulusFactor, inInclusiveRange(0.80, 0.90));

      // Bieganie tempowe stymuluje gęstość kości (BMD)
      expect(run.boneDensityBoostFactor, greaterThan(0.90));
      expect(run.description, contains('osteopenii'));
    });

    test('SpanishCampLocation zawiera 5 kultowych baz zgrupowaniowych w Hiszpanii', () {
      final camps = WinterOffSeasonTrainingService.getAllSpanishCampLocations();
      expect(camps.length, equals(5));

      const calpe = SpanishCampLocation.calpeCostaBlanca;
      expect(calpe.averageJanuaryTempC, inInclusiveRange(16.0, 19.0));
      expect(calpe.iconicClimbs, contains('Coll de Rates (6.5 km, 5.2%)'));
      expect(calpe.iconicClimbs, contains('Cumbre del Sol (4.0 km, 10.1%)'));

      const mallorca = SpanishCampLocation.mallorcaAlcudia;
      expect(mallorca.iconicClimbs, contains('Sa Calobra / Coll dels Reis (9.4 km, 7.1%)'));
      expect(mallorca.iconicClimbs, contains('Puig Major (14.2 km, 6.0%)'));

      const girona = SpanishCampLocation.gironaCatalonia;
      expect(girona.iconicClimbs, contains('Rocacorba (9.9 km, 7.4%)'));
    });
  });

  group('WinterOffSeasonTrainingService - 2. Plany i Symulacja Tygodnia', () {
    test('generateRecommendedPlan dopasowuje ćwiczenia do profilu sprintera i górala', () {
      final sprinter = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.pureSprinter,
      );
      final climber = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.gcClimber,
      );

      final sprinterNovPlan = WinterOffSeasonTrainingService.generateRecommendedPlan(
        rider: sprinter,
        month: WinterMonth.november,
      );
      expect(sprinterNovPlan.month, equals(WinterMonth.november));
      expect(sprinterNovPlan.gymPhase, equals(GymLoadPhase.anatomicalAdaptation));
      expect(sprinterNovPlan.selectedCrossTrainingDiscipline, equals(CrossTrainingType.rowingErgometer));
      expect(sprinterNovPlan.primaryGymExercises, contains(GymExerciseType.frontSquats));

      final climberDecPlan = WinterOffSeasonTrainingService.generateRecommendedPlan(
        rider: climber,
        month: WinterMonth.december,
      );
      expect(climberDecPlan.month, equals(WinterMonth.december));
      expect(climberDecPlan.gymPhase, equals(GymLoadPhase.maximumStrength));
      expect(climberDecPlan.selectedCrossTrainingDiscipline, equals(CrossTrainingType.crossCountrySkiing));
      expect(climberDecPlan.targetSpanishCamp, equals(SpanishCampLocation.calpeCostaBlanca));
    });

    test('simulateWeek wylicza zysk watów 5s-1m, symetrię i odporność na urazy', () {
      final rider = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.versatileSprinter,
        targetOverallRating: 84,
      );

      const coach = PerformanceCoach(
        id: 'coach_elite',
        firstName: 'Paolo',
        lastName: 'Slongo',
        nationalityIso: 'ITA',
        age: 46,
        experienceLevel: 92,
        monthlySalaryEur: 15000,
        contractEndYear: 2028,
        reputation: 92,
        ftpDevelopmentEfficiency: 90,
        sprintAndNeuromuscularFocus: 94,
        winterGymPeriodizationSkill: 95,
        overtrainingPrevention: 91,
        specialization: CoachSpecialization.sprintAndExplosiveness,
      );

      final plan = WinterOffSeasonPlan(
        riderId: rider.id,
        month: WinterMonth.december,
        gymSessionsPerWeek: 3,
        crossTrainingSessionsPerWeek: 2,
        indoorCyclingZ2HoursPerWeek: 8.0,
        gymPhase: GymLoadPhase.maximumStrength,
        primaryGymExercises: const [
          GymExerciseType.frontSquats,
          GymExerciseType.romanianDeadlift,
          GymExerciseType.bulgarianSplitSquats,
        ],
        selectedCrossTrainingDiscipline: CrossTrainingType.crossCountrySkiing,
      );

      final report = WinterOffSeasonTrainingService.simulateWeek(
        rider: rider,
        plan: plan,
        coach: coach,
      );

      expect(report.weeksSimulated, equals(1));
      expect(report.watts5sGained, greaterThan(10));
      expect(report.watts15sGained, greaterThan(10));
      expect(report.watts1mGained, greaterThan(5));
      expect(report.injuryResistanceBoostPct, greaterThan(10.0));
      expect(report.leftRightBalanceImprovementPct, greaterThan(0.2));
      expect(report.trainingLog.isNotEmpty, isTrue);

      // Sprawdzenie zaktualizowanego kolarza
      expect(report.updatedRider.powerProfile.watts5s, greaterThan(rider.powerProfile.watts5s));
      expect(report.updatedRider.powerProfile.watts15s, greaterThan(rider.powerProfile.watts15s));
      expect(report.updatedRider.health.chronicTrainingLoad, greaterThan(0));
    });
  });

  group('WinterOffSeasonTrainingService - 3. Testy Przedzgrupowaniowe i Pełny Off-Season', () {
    test('conductPreCampFitnessTesting wylicza 1RM, symetrię i gotowość do Hiszpanii', () {
      final rider = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.gcClimber,
        targetOverallRating: 88,
      );

      final testResult = WinterOffSeasonTrainingService.conductPreCampFitnessTesting(
        rider: rider,
        plannedCamp: SpanishCampLocation.calpeCostaBlanca,
      );

      expect(testResult.riderName, equals(rider.fullName));
      expect(testResult.estimated1rmFrontSquatKg, greaterThan(80.0));
      expect(testResult.estimated1rmRdlKg, greaterThan(testResult.estimated1rmFrontSquatKg));
      expect(testResult.leftLegPowerPct, inInclusiveRange(48.0, 52.0));
      expect(testResult.rightLegPowerPct, inInclusiveRange(48.0, 52.0));
      expect(testResult.isLeftRightSymmetrical, isTrue);
      expect(testResult.campReadinessScore, inInclusiveRange(60, 99));
      expect(testResult.verdict.isApprovedToFly, isTrue);
      expect(testResult.recommendedCampLocation, equals(SpanishCampLocation.calpeCostaBlanca));
      expect(testResult.coachNotes, anyOf(contains('Coll de Rates'), contains('Bulgarian Split Squats')));
      expect(testResult.doctorClearanceNotes, contains('Brak przeciwwskazań'));
    });

    test('simulateFullWinterOffSeason symuluje 8 tygodni (listopad + grudzień) z testem', () {
      final rider = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.puncher,
        targetOverallRating: 85,
      );

      const coach = PerformanceCoach(
        id: 'c_01',
        firstName: 'Marc',
        lastName: 'Lamberts',
        nationalityIso: 'BEL',
        age: 50,
        experienceLevel: 94,
        monthlySalaryEur: 16000,
        contractEndYear: 2028,
        reputation: 95,
        ftpDevelopmentEfficiency: 92,
        sprintAndNeuromuscularFocus: 88,
        winterGymPeriodizationSkill: 94,
        overtrainingPrevention: 92,
        specialization: CoachSpecialization.allRoundDevelopment,
      );

      final report = WinterOffSeasonTrainingService.simulateFullWinterOffSeason(
        rider: rider,
        coach: coach,
        plannedCamp: SpanishCampLocation.mallorcaAlcudia,
      );

      expect(report.weeksSimulated, equals(8));
      expect(report.watts5sGained, greaterThan(50));
      expect(report.watts15sGained, greaterThan(40));
      expect(report.watts1mGained, greaterThan(20));
      expect(report.vo2maxDelta, greaterThan(0.5));
      expect(report.injuryResistanceBoostPct, greaterThan(50.0));
      expect(report.testingResult, isNotNull);
      expect(report.testingResult!.recommendedCampLocation, equals(SpanishCampLocation.mallorcaAlcudia));
      expect(report.trainingLog.length, greaterThanOrEqualTo(10));
    });

    test('Serializacja i deserializacja JSON dla planów i wyników testów', () {
      const plan = WinterOffSeasonPlan(
        riderId: 'r_test_1',
        month: WinterMonth.december,
        gymSessionsPerWeek: 3,
        crossTrainingSessionsPerWeek: 2,
        indoorCyclingZ2HoursPerWeek: 9.5,
        gymPhase: GymLoadPhase.maximumStrength,
        primaryGymExercises: [
          GymExerciseType.bulgarianSplitSquats,
          GymExerciseType.frontSquats,
        ],
        selectedCrossTrainingDiscipline: CrossTrainingType.crossCountrySkiing,
        targetSpanishCamp: SpanishCampLocation.gironaCatalonia,
      );

      final json = plan.toJson();
      final restored = WinterOffSeasonPlan.fromJson(json);

      expect(restored.riderId, equals('r_test_1'));
      expect(restored.month, equals(WinterMonth.december));
      expect(restored.primaryGymExercises.length, equals(2));
      expect(restored.targetSpanishCamp, equals(SpanishCampLocation.gironaCatalonia));

      const scheduled = ScheduledGymExercise(
        exerciseType: GymExerciseType.romanianDeadlift,
        sets: 4,
        reps: 6,
        intensityPct1Rm: 82.5,
      );
      final schedJson = scheduled.toJson();
      final schedRestored = ScheduledGymExercise.fromJson(schedJson);
      expect(schedRestored.exerciseType, equals(GymExerciseType.romanianDeadlift));
      expect(schedRestored.reps, equals(6));
    });
  });
}
