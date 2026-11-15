// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/staff_member.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/services/career/race_reconnaissance_service.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';

void main() {
  late List<Rider> testRiders;
  late SportsDirector testDirector;
  late HeadMechanic testMechanic;

  setUp(() {
    testRiders = List.generate(5, (index) {
      return RiderProceduralGenerator.generateRider(
        id: 'rider_$index',
        specialization: RiderSpecialization.classicCobbles,
        targetOverallRating: 75 + index,
      );
    });

    testDirector = const SportsDirector(
      id: 'ds_1',
      firstName: 'Patrick',
      lastName: 'Lefevere',
      nationalityIso: 'BEL',
      age: 58,
      experienceLevel: 90,
      monthlySalaryEur: 12000,
      contractEndYear: 2028,
      morale: 90.0,
      reputation: 92,
      convoyCarDrivingSkill: 88,
      tacticalAiInsight: 90,
      preRaceBriefingCharisma: 88,
      radioCommunicationClarity: 85,
    );

    testMechanic = const HeadMechanic(
      id: 'mech_1',
      firstName: 'Fausto',
      lastName: 'Pinarello',
      nationalityIso: 'ITA',
      age: 46,
      experienceLevel: 88,
      monthlySalaryEur: 7000,
      contractEndYear: 2028,
      reputation: 88,
      drivetrainReliabilitySkill: 92,
      tubelessAndTireMastery: 90,
      chainWaxingExpertise: 92,
      wheelTruingPrecision: 90,
    );
  });

  TourRace createMockRace({required List<RaceStage> stages}) {
    return TourRace(
      id: 'mock_tour_2026',
      name: 'Tour de France 2026',
      countryIso: 'FR',
      uciCategory: RaceCategory.grandTour,
      startMonth: 7,
      startDay: 4,
      stages: stages,
      prizePoolEur: 2500000,
      participatingTeamIds: ['team_1', 'team_2'],
      ridersPerTeam: 8,
      classifications: const RaceClassifications(
        generalClassification: [],
        pointsClassification: [],
        mountainsClassification: [],
        youthClassification: [],
        teamClassification: [],
      ),
    );
  }

  RaceStage createCobbledStage({int stageNum = 5}) {
    return RaceStage(
      id: 'stage_$stageNum',
      stageNumber: stageNum,
      name: 'Arenberg Classic Pavé',
      stageType: StageType.cobbleClassic,
      segments: const [
        StageSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 40.0,
          startElevationM: 50.0,
          endElevationM: 60.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 20.0,
          windDirectionDegrees: 180.0,
          roadBearingDegrees: 0.0,
          sprintOrKomClassification: SegmentClassification.none,
        ),
        StageSegment(
          index: 1,
          startKm: 40.0,
          lengthKm: 2.4,
          startElevationM: 60.0,
          endElevationM: 60.0,
          surfaceType: SegmentSurfaceType.cobblestonesSector5,
          technicalDifficulty: 95.0,
          windDirectionDegrees: 180.0,
          roadBearingDegrees: 0.0,
          sprintOrKomClassification: SegmentClassification.none,
        ),
      ],
      baseTemperatureCelsius: 16.0,
      weatherCondition: WeatherCondition.overcast,
      windSpeedKmh: 20.0,
    );
  }

  RaceStage createMountainStage({int stageNum = 12}) {
    return RaceStage(
      id: 'stage_$stageNum',
      stageNumber: stageNum,
      name: 'Alpe d\'Huez Summit Finish',
      stageType: StageType.summitFinish,
      segments: const [
        StageSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 120.0,
          startElevationM: 700.0,
          endElevationM: 750.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 30.0,
          windDirectionDegrees: 90.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.none,
        ),
        StageSegment(
          index: 1,
          startKm: 120.0,
          lengthKm: 13.8,
          startElevationM: 750.0,
          endElevationM: 1860.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 85.0,
          windDirectionDegrees: 270.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.horsCategorie,
        ),
      ],
      baseTemperatureCelsius: 22.0,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 12.0,
    );
  }

  RaceStage createTimeTrialStage({int stageNum = 7}) {
    return RaceStage(
      id: 'stage_$stageNum',
      stageNumber: stageNum,
      name: 'Dijon ITT',
      stageType: StageType.individualTimeTrial,
      segments: const [
        StageSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 32.0,
          startElevationM: 220.0,
          endElevationM: 240.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 50.0,
          windDirectionDegrees: 45.0,
          roadBearingDegrees: 225.0,
          sprintOrKomClassification: SegmentClassification.none,
        ),
      ],
      baseTemperatureCelsius: 24.0,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 15.0,
    );
  }

  RaceStage createGravelStage({int stageNum = 9}) {
    return RaceStage(
      id: 'stage_$stageNum',
      stageNumber: stageNum,
      name: 'Troyes White Roads',
      stageType: StageType.hilly,
      segments: const [
        StageSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 80.0,
          startElevationM: 150.0,
          endElevationM: 180.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 30.0,
          windDirectionDegrees: 0.0,
          roadBearingDegrees: 180.0,
          sprintOrKomClassification: SegmentClassification.none,
        ),
        StageSegment(
          index: 1,
          startKm: 80.0,
          lengthKm: 4.5,
          startElevationM: 180.0,
          endElevationM: 220.0,
          surfaceType: SegmentSurfaceType.gravelStrade,
          technicalDifficulty: 75.0,
          windDirectionDegrees: 0.0,
          roadBearingDegrees: 180.0,
          sprintOrKomClassification: SegmentClassification.none,
        ),
      ],
      baseTemperatureCelsius: 28.0,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 10.0,
    );
  }

  RaceStage createFlatStage({int stageNum = 2}) {
    return RaceStage(
      id: 'stage_$stageNum',
      stageNumber: stageNum,
      name: 'Bordeaux Sprint Boulevard',
      stageType: StageType.flat,
      segments: const [
        StageSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 180.0,
          startElevationM: 20.0,
          endElevationM: 15.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 15.0,
          windDirectionDegrees: 0.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.none,
        ),
      ],
      baseTemperatureCelsius: 25.0,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 10.0,
    );
  }

  group('RaceReconnaissanceService - 1. Identyfikacja kluczowych etapów', () {
    test('identifyHighPriorityStages prawidłowo wykrywa bruki, góry, czasówki i szutry', () {
      final cobbles = createCobbledStage(stageNum: 5);
      final mountain = createMountainStage(stageNum: 12);
      final itt = createTimeTrialStage(stageNum: 7);
      final gravel = createGravelStage(stageNum: 9);
      final flat = createFlatStage(stageNum: 2);

      final race = createMockRace(stages: [flat, cobbles, itt, gravel, mountain]);

      final candidates = RaceReconnaissanceService.identifyHighPriorityStages(race);

      // Płaski etap nie powinien być w priorytetach (score < 70)
      expect(candidates.length, equals(4));

      // Pierwszy powinien być etap brukowy (score: 98)
      expect(candidates[0].reconType, equals(ReconnaissanceType.cobbledSectors));
      expect(candidates[0].priorityScore, equals(98));
      expect(candidates[0].stage.stageNumber, equals(5));
      expect(candidates[0].rationale, contains('Trouée d\'Arenberg'));

      // Drugi powinien być etap górski HC (score: 92)
      expect(candidates[1].reconType, equals(ReconnaissanceType.alpineMountainPasses));
      expect(candidates[1].priorityScore, equals(92));
      expect(candidates[1].stage.stageNumber, equals(12));

      // Trzeci powinien być etap szutrowy (score: 88)
      expect(candidates[2].reconType, equals(ReconnaissanceType.gravelWhiteRoads));
      expect(candidates[2].priorityScore, equals(88));

      // Czwarty etap ITT (score: 85)
      expect(candidates[3].reconType, equals(ReconnaissanceType.timeTrialCourse));
      expect(candidates[3].priorityScore, equals(85));
    });

    test('Koszt rekonesansu uwzględnia specyfikę etapu (bruki i góry)', () {
      final cobbles = createCobbledStage(stageNum: 5);
      final mountain = createMountainStage(stageNum: 12);
      final itt = createTimeTrialStage(stageNum: 7);

      final race = createMockRace(stages: [cobbles, mountain, itt]);
      final candidates = RaceReconnaissanceService.identifyHighPriorityStages(race);

      final cobbleCand = candidates.firstWhere((c) => c.stage.stageNumber == 5);
      final mountainCand = candidates.firstWhere((c) => c.stage.stageNumber == 12);
      final ittCand = candidates.firstWhere((c) => c.stage.stageNumber == 7);

      expect(cobbleCand.estimatedCostEur, equals(7000)); // 4500 + 2500
      expect(mountainCand.estimatedCostEur, equals(4500)); // summitFinish base 4500 (lub 7500 dla highMountain)
      expect(ittCand.estimatedCostEur, equals(4500)); // base 4500
    });
  });

  group('RaceReconnaissanceService - 2. Wykonanie misji rekonesansowej', () {
    test('executeReconnaissance rzuca błąd, gdy brak zawodników', () {
      final race = createMockRace(stages: [createCobbledStage()]);
      expect(
        () => RaceReconnaissanceService.executeReconnaissance(
          race: race,
          stage: race.stages.first,
          participantRiders: [],
          dateConducted: DateTime(2026, 6, 15),
        ),
        throwsArgumentError,
      );
    });

    test('executeReconnaissance generuje kompletną misję, raporty i aplikuje zmęczenie', () {
      final stage = createCobbledStage(stageNum: 5);
      final race = createMockRace(stages: [stage]);

      final initialAtl = testRiders.first.health.acuteTrainingLoad;

      final result = RaceReconnaissanceService.executeReconnaissance(
        race: race,
        stage: stage,
        participantRiders: testRiders,
        director: testDirector,
        mechanic: testMechanic,
        dateConducted: DateTime(2026, 6, 20),
      );

      // Sprawdzenie misji
      expect(result.mission.raceId, equals(race.id));
      expect(result.mission.stageNumber, equals(5));
      expect(result.mission.reconType, equals(ReconnaissanceType.cobbledSectors));
      expect(result.mission.participantRiderIds.length, equals(5));
      expect(result.mission.directorId, equals(testDirector.id));
      expect(result.mission.mechanicId, equals(testMechanic.id));
      expect(result.mission.recommendedTirePressureBar, equals(3.8));
      expect(result.mission.keyTacticalFindings.length, greaterThanOrEqualTo(3));

      // Sprawdzenie raportów
      expect(result.directorSummaryReport, contains(testDirector.fullName));
      expect(result.directorSummaryReport, contains('Arenberg'));
      expect(result.mechanicTireReport, contains(testMechanic.fullName));
      expect(result.mechanicTireReport, contains('3.8 bar'));

      // Sprawdzenie zmęczenia ATL (+12) i CTL (+3)
      final updatedRider = result.updatedParticipants.first;
      expect(updatedRider.health.acuteTrainingLoad, closeTo(initialAtl + 12.0, 0.01));
    });
  });

  group('RaceReconnaissanceService - 3. Mechanika bonusów wyścigowych', () {
    test('isRiderReconCompleted prawidłowo weryfikuje udział kolarza w misji', () {
      final stage = createMountainStage(stageNum: 14);
      final race = createMockRace(stages: [stage]);

      final result = RaceReconnaissanceService.executeReconnaissance(
        race: race,
        stage: stage,
        participantRiders: [testRiders[0], testRiders[1], testRiders[2]],
        dateConducted: DateTime(2026, 6, 25),
      );

      final completedMissions = [result.mission];

      // Kolarz 0 brał udział
      expect(
        RaceReconnaissanceService.isRiderReconCompleted(
          completedMissions: completedMissions,
          riderId: testRiders[0].id,
          raceId: race.id,
          stageNumber: 14,
        ),
        isTrue,
      );

      // Kolarz 4 nie brał udziału
      expect(
        RaceReconnaissanceService.isRiderReconCompleted(
          completedMissions: completedMissions,
          riderId: testRiders[4].id,
          raceId: race.id,
          stageNumber: 14,
        ),
        isFalse,
      );

      // Inny etap niż ten z misji
      expect(
        RaceReconnaissanceService.isRiderReconCompleted(
          completedMissions: completedMissions,
          riderId: testRiders[0].id,
          raceId: race.id,
          stageNumber: 15,
        ),
        isFalse,
      );
    });

    test('applyReconBonusToRider dodaje +10 do bikeHandling i +10 do descending (max 99)', () {
      final stage = createMountainStage(stageNum: 14);
      final race = createMockRace(stages: [stage]);

      final result = RaceReconnaissanceService.executeReconnaissance(
        race: race,
        stage: stage,
        participantRiders: [testRiders[0]],
        dateConducted: DateTime(2026, 6, 25),
      );

      final originalHandling = testRiders[0].skills.bikeHandling;
      final originalDescending = testRiders[0].skills.descending;

      final boostedRider = RaceReconnaissanceService.applyReconBonusToRider(
        rider: testRiders[0],
        completedMissions: [result.mission],
        raceId: race.id,
        stageNumber: 14,
      );

      expect(boostedRider.skills.bikeHandling, equals((originalHandling + 10).clamp(0, 99)));
      expect(boostedRider.skills.descending, equals((originalDescending + 10).clamp(0, 99)));

      // Kolarz bez rekonesansu nie dostaje bonusu
      final nonParticipant = RaceReconnaissanceService.applyReconBonusToRider(
        rider: testRiders[1],
        completedMissions: [result.mission],
        raceId: race.id,
        stageNumber: 14,
      );
      expect(nonParticipant.skills.bikeHandling, equals(testRiders[1].skills.bikeHandling));
      expect(nonParticipant.skills.descending, equals(testRiders[1].skills.descending));
    });

    test('getEffectiveRiderSkills zwraca wzmocnione atrybuty po rekonesansie', () {
      final stage = createMountainStage(stageNum: 14);
      final race = createMockRace(stages: [stage]);

      final result = RaceReconnaissanceService.executeReconnaissance(
        race: race,
        stage: stage,
        participantRiders: [testRiders[0]],
        dateConducted: DateTime(2026, 6, 25),
      );

      final effectiveSkills = RaceReconnaissanceService.getEffectiveRiderSkills(
        rider: testRiders[0],
        completedMissions: [result.mission],
        raceId: race.id,
        stageNumber: 14,
      );

      expect(effectiveSkills.bikeHandling, equals((testRiders[0].skills.bikeHandling + 10).clamp(0, 99)));
      expect(effectiveSkills.descending, equals((testRiders[0].skills.descending + 10).clamp(0, 99)));
    });

    test('calculatePositioningAdvantage daje +15 do +23 punktów w zależności od raceIq', () {
      final stage = createCobbledStage(stageNum: 5);
      final race = createMockRace(stages: [stage]);

      final result = RaceReconnaissanceService.executeReconnaissance(
        race: race,
        stage: stage,
        participantRiders: [testRiders[0]],
        dateConducted: DateTime(2026, 6, 20),
      );

      // Kolarz bez rekonesansu
      final advNoRecon = RaceReconnaissanceService.calculatePositioningAdvantage(
        rider: testRiders[1],
        completedMissions: [result.mission],
        raceId: race.id,
        stageNumber: 5,
      );
      expect(advNoRecon, equals(0.0));

      // Kolarz z rekonesansem
      final advWithRecon = RaceReconnaissanceService.calculatePositioningAdvantage(
        rider: testRiders[0],
        completedMissions: [result.mission],
        raceId: race.id,
        stageNumber: 5,
      );
      expect(advWithRecon, inInclusiveRange(15.0, 23.0));
    });

    test('calculateCrashRiskMultiplier i calculatePunctureRiskMultiplier poprawnie redukują ryzyko', () {
      final stage = createCobbledStage(stageNum: 5);
      final race = createMockRace(stages: [stage]);

      final result = RaceReconnaissanceService.executeReconnaissance(
        race: race,
        stage: stage,
        participantRiders: [testRiders[0]],
        dateConducted: DateTime(2026, 6, 20),
      );

      // Uczestnik: -45% ryzyka kraksy (0.55) i -30% ryzyka kapcia (0.70)
      expect(
        RaceReconnaissanceService.calculateCrashRiskMultiplier(
          riderId: testRiders[0].id,
          completedMissions: [result.mission],
          raceId: race.id,
          stageNumber: 5,
        ),
        equals(0.55),
      );

      expect(
        RaceReconnaissanceService.calculatePunctureRiskMultiplier(
          riderId: testRiders[0].id,
          completedMissions: [result.mission],
          raceId: race.id,
          stageNumber: 5,
        ),
        equals(0.70),
      );

      // Brak rekonesansu: mnożnik 1.0 (brak zniżki ryzyka)
      expect(
        RaceReconnaissanceService.calculateCrashRiskMultiplier(
          riderId: testRiders[1].id,
          completedMissions: [result.mission],
          raceId: race.id,
          stageNumber: 5,
        ),
        equals(1.0),
      );

      expect(
        RaceReconnaissanceService.calculatePunctureRiskMultiplier(
          riderId: testRiders[1].id,
          completedMissions: [result.mission],
          raceId: race.id,
          stageNumber: 5,
        ),
        equals(1.0),
      );
    });
  });

  group('RaceReconnaissanceService - 4. Serializacja JSON', () {
    test('ReconnaissanceType toJson i fromJson działają poprawnie', () {
      for (final type in ReconnaissanceType.values) {
        final json = type.toJson();
        final parsed = ReconnaissanceType.fromJson(json);
        expect(parsed, equals(type));
        expect(type.displayName.isNotEmpty, isTrue);
        expect(type.description.isNotEmpty, isTrue);
      }
    });

    test('ReconnaissanceStageBonus toJson i fromJson działają poprawnie', () {
      const original = ReconnaissanceStageBonus(
        bikeHandlingBonus: 12,
        descendingBonus: 12,
        positioningAdvantageScore: 20,
        crashRiskMultiplier: 0.50,
        punctureRiskMultiplier: 0.65,
        descentAttackSuccessBonus: 0.25,
      );

      final json = original.toJson();
      final restored = ReconnaissanceStageBonus.fromJson(json);

      expect(restored.bikeHandlingBonus, equals(12));
      expect(restored.descendingBonus, equals(12));
      expect(restored.positioningAdvantageScore, equals(20));
      expect(restored.crashRiskMultiplier, equals(0.50));
      expect(restored.punctureRiskMultiplier, equals(0.65));
      expect(restored.descentAttackSuccessBonus, equals(0.25));
    });

    test('ReconnaissanceMission toJson i fromJson działają poprawnie', () {
      final original = ReconnaissanceMission(
        id: 'mission_123',
        raceId: 'tour_2026',
        raceName: 'Tour de France',
        stageNumber: 5,
        stageName: 'Arenberg',
        reconType: ReconnaissanceType.cobbledSectors,
        participantRiderIds: ['rider_1', 'rider_2'],
        directorId: 'ds_1',
        mechanicId: 'mech_1',
        dateConducted: DateTime(2026, 6, 20, 10, 30),
        costEur: 7000,
        fatigueAtlAdded: 12.0,
        moraleBoost: 6.0,
        targetSectorOrClimbName: 'Trouée d\'Arenberg',
        keyTacticalFindings: ['Wąski wjazd', 'Korona drogi'],
        recommendedTirePressureBar: 3.8,
      );

      final json = original.toJson();
      final restored = ReconnaissanceMission.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.raceId, equals(original.raceId));
      expect(restored.stageNumber, equals(original.stageNumber));
      expect(restored.reconType, equals(original.reconType));
      expect(restored.participantRiderIds, equals(original.participantRiderIds));
      expect(restored.directorId, equals(original.directorId));
      expect(restored.mechanicId, equals(original.mechanicId));
      expect(restored.costEur, equals(original.costEur));
      expect(restored.recommendedTirePressureBar, equals(3.8));
      expect(restored.keyTacticalFindings, equals(original.keyTacticalFindings));
    });
  });
}
