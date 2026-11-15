// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/staff_member.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';

void main() {
  group('StaffMember - 1. SportsDirector (Dyrektor Sportowy)', () {
    test('Dyrektor Sportowy wylicza szybkość wymiany roweru i bonus odprawy', () {
      const eliteDs = SportsDirector(
        id: 'ds_01',
        firstName: 'Patrick',
        lastName: 'Lefevere',
        nationalityIso: 'BEL',
        age: 58,
        experienceLevel: 94,
        monthlySalaryEur: 16000,
        contractEndYear: 2028,
        morale: 92.0,
        reputation: 95,
        convoyCarDrivingSkill: 92,
        tacticalAiInsight: 95,
        preRaceBriefingCharisma: 90,
        radioCommunicationClarity: 88,
        tacticalPhilosophy: DirectorTacticalPhilosophy.aggressiveAttacking,
      );

      expect(eliteDs.role, equals(StaffRole.sportsDirector));
      expect(eliteDs.fullName, equals('Patrick Lefevere'));

      // Szybka wymiana roweru: elitarny dyrektor w ucieczce osiąga poniżej 10s
      final pitStopTimeInBreakaway =
          eliteDs.calculateBikeSwapTimeSeconds(isRiderInMainPeloton: false);
      expect(pitStopTimeInBreakaway, lessThan(10.0));
      expect(pitStopTimeInBreakaway, closeTo(8.5, 1.5));

      // W deszczu czas wymiany w peletonie lekko wzrasta
      final pitStopWetPeloton = eliteDs.calculateBikeSwapTimeSeconds(
        isRiderInMainPeloton: true,
        isWetRainConditions: true,
      );
      expect(pitStopWetPeloton, greaterThan(pitStopTimeInBreakaway));

      // Odprawa przedstartowa daje silny impuls morale (+4 do +6 pkt)
      final normalMoraleBoost = eliteDs.calculateBriefingMoraleBonus(isQueenStage: false);
      final queenStageMoraleBoost = eliteDs.calculateBriefingMoraleBonus(isQueenStage: true);
      expect(normalMoraleBoost, closeTo(4.0, 1.0));
      expect(queenStageMoraleBoost, greaterThan(normalMoraleBoost));

      // Indeks efektywności taktycznej
      expect(eliteDs.tacticalEfficiencyScore, greaterThan(0.90));
    });

    test('Serializacja SportsDirector do i z JSON działa bezstratnie', () {
      const ds = SportsDirector(
        id: 'ds_test',
        firstName: 'Dariusz',
        lastName: 'Baranowski',
        nationalityIso: 'POL',
        age: 52,
        experienceLevel: 82,
        monthlySalaryEur: 9500,
        contractEndYear: 2027,
        reputation: 80,
        convoyCarDrivingSkill: 84,
        tacticalAiInsight: 81,
        preRaceBriefingCharisma: 78,
        radioCommunicationClarity: 85,
        tacticalPhilosophy: DirectorTacticalPhilosophy.gcCalculator,
      );

      final json = ds.toJson();
      final restored = StaffMember.fromJson(json) as SportsDirector;

      expect(restored.id, equals('ds_test'));
      expect(restored.firstName, equals('Dariusz'));
      expect(restored.convoyCarDrivingSkill, equals(84));
      expect(restored.tacticalPhilosophy, equals(DirectorTacticalPhilosophy.gcCalculator));
    });
  });

  group('StaffMember - 2. PerformanceCoach (Trener Przygotowania Fizycznego)', () {
    test('Trener motoryczny wylicza mnożnik FTP, bonus sprintu i retencję siły zimowej', () {
      const coach = PerformanceCoach(
        id: 'coach_01',
        firstName: 'Inigo',
        lastName: 'San Millan',
        nationalityIso: 'ESP',
        age: 50,
        experienceLevel: 96,
        monthlySalaryEur: 14000,
        contractEndYear: 2028,
        reputation: 96,
        ftpDevelopmentEfficiency: 95,
        sprintAndNeuromuscularFocus: 85,
        winterGymPeriodizationSkill: 92,
        overtrainingPrevention: 90,
        specialization: CoachSpecialization.enduranceAndClimbing,
      );

      expect(coach.role, equals(StaffRole.performanceCoach));

      // Mnożnik przyrostu FTP podczas obozu (np. ~1.33x)
      expect(coach.ftpProgressionMultiplier, closeTo(1.33, 0.05));

      // Bonus sprinterski dla mocy 15s (np. z 1200W zysk o 40W)
      final sprintBonus = coach.calculateSprintBonusWatts(1200);
      expect(sprintBonus, inInclusiveRange(30, 50));

      // Retencja siły po okresie zimowym na siłowni
      expect(coach.winterStrengthRetentionFactor, greaterThan(0.92));
    });

    test('Serializacja PerformanceCoach do i z JSON', () {
      const coach = PerformanceCoach(
        id: 'coach_pl',
        firstName: 'Piotr',
        lastName: 'Wadecki',
        nationalityIso: 'POL',
        age: 48,
        experienceLevel: 80,
        monthlySalaryEur: 8500,
        contractEndYear: 2027,
        reputation: 79,
        ftpDevelopmentEfficiency: 82,
        sprintAndNeuromuscularFocus: 78,
        winterGymPeriodizationSkill: 85,
        overtrainingPrevention: 80,
        specialization: CoachSpecialization.allRoundDevelopment,
      );

      final json = coach.toJson();
      final restored = StaffMember.fromJson(json) as PerformanceCoach;

      expect(restored.id, equals('coach_pl'));
      expect(restored.specialization, equals(CoachSpecialization.allRoundDevelopment));
      expect(restored.winterGymPeriodizationSkill, equals(85));
    });
  });

  group('StaffMember - 3. TeamDoctor (Lekarz Klubowy)', () {
    test('Lekarz przyspiesza zrost złamań i chroni przed infekcjami', () {
      const doctor = TeamDoctor(
        id: 'doc_01',
        firstName: 'Pedro',
        lastName: 'Celaya',
        nationalityIso: 'ESP',
        age: 55,
        experienceLevel: 92,
        monthlySalaryEur: 18000,
        contractEndYear: 2028,
        reputation: 92,
        bloodDiagnosticsSkill: 94,
        infectionPreventionAndHygiene: 90,
        fractureAndOrthopedicRehabSpeed: 95,
        woundHealingCare: 88,
        medicalSpecialization: DoctorSpecialization.orthopedicsAndTrauma,
      );

      expect(doctor.role, equals(StaffRole.teamDoctor));

      // Złamanie obojczyka (28 dni) skrócone o ok. 9 dni
      final reductionDays = doctor.calculateFractureDaysReduction(28);
      expect(reductionDays, inInclusiveRange(8, 10));

      // Redukcja ryzyka infekcji w hotelach
      expect(doctor.infectionRiskReductionPercent, closeTo(58.5, 3.0));

      // Zdolność wczesnego wykrywania niedoboru żelaza
      expect(doctor.canDetectEarlyIronDeficiency, isTrue);
    });

    test('Serializacja TeamDoctor do i z JSON', () {
      const doc = TeamDoctor(
        id: 'doc_test',
        firstName: 'Krzysztof',
        lastName: 'Ficek',
        nationalityIso: 'POL',
        age: 56,
        experienceLevel: 86,
        monthlySalaryEur: 12000,
        contractEndYear: 2027,
        reputation: 85,
        bloodDiagnosticsSkill: 88,
        infectionPreventionAndHygiene: 84,
        fractureAndOrthopedicRehabSpeed: 87,
        woundHealingCare: 89,
      );

      final json = doc.toJson();
      final restored = StaffMember.fromJson(json) as TeamDoctor;

      expect(restored.id, equals('doc_test'));
      expect(restored.bloodDiagnosticsSkill, equals(88));
      expect(restored.woundHealingCare, equals(89));
    });
  });

  group('StaffMember - 4. HeadMechanic (Główny Mechanik)', () {
    test('Mechanik obniża usterki napędu, wylicza zysk wosku i chroni przed defektami', () {
      const mechanic = HeadMechanic(
        id: 'mech_01',
        firstName: 'Fausto',
        lastName: 'Pinarello-Mech',
        nationalityIso: 'ITA',
        age: 46,
        experienceLevel: 94,
        monthlySalaryEur: 7500,
        contractEndYear: 2028,
        reputation: 92,
        drivetrainReliabilitySkill: 95,
        tubelessAndTireMastery: 92,
        serviceTimeMinutesPerBike: 38,
        chainWaxingExpertise: 96,
        wheelTruingPrecision: 93,
      );

      expect(mechanic.role, equals(StaffRole.headMechanic));

      // Obniżenie wskaźnika defektu napędu (spadek do ~0.39x)
      expect(mechanic.mechanicalFailureRateMultiplier, lessThan(0.50));

      // Zysk watów z wygotowanego łańcucha Hot Melt Wax (3.0 - 5.5W)
      expect(mechanic.chainWaxWattageSavings, closeTo(5.3, 0.4));

      // Redukcja ryzyka przebicia opony
      expect(mechanic.punctureRiskReductionPercent, closeTo(55.2, 2.0));
      expect(mechanic.serviceTimeMinutesPerBike, equals(38));
    });

    test('Serializacja HeadMechanic do i z JSON', () {
      const mech = HeadMechanic(
        id: 'mech_pl',
        firstName: 'Marek',
        lastName: 'Leśniewski',
        nationalityIso: 'POL',
        age: 50,
        experienceLevel: 81,
        monthlySalaryEur: 5200,
        contractEndYear: 2027,
        reputation: 80,
        drivetrainReliabilitySkill: 83,
        tubelessAndTireMastery: 82,
        chainWaxingExpertise: 85,
        wheelTruingPrecision: 80,
      );

      final json = mech.toJson();
      final restored = StaffMember.fromJson(json) as HeadMechanic;

      expect(restored.id, equals('mech_pl'));
      expect(restored.chainWaxingExpertise, equals(85));
      expect(restored.wheelTruingPrecision, equals(80));
    });
  });

  group('StaffMember - 5. Scout (Skaut Talentów U23)', () {
    test('Skaut weryfikuje regiony geograficzne i margines błędu estymacji', () {
      const scout = Scout(
        id: 'scout_01',
        firstName: 'Joxean',
        lastName: 'Fernandez Matxin',
        nationalityIso: 'ESP',
        age: 53,
        experienceLevel: 96,
        monthlySalaryEur: 8500,
        contractEndYear: 2028,
        reputation: 97,
        talentDiscoveryRating: 98,
        evaluationPrecision: 92,
        assignedRegion: ScoutingRegion.colombiaAndSouthAmerica,
        networkReach: 95,
        specialtyFocus: ScoutTalentFocus.grandTourContenders,
      );

      expect(scout.role, equals(StaffRole.scout));

      // Wąski margines błędu oceny potencjału (np. +/- 2 pkt zamiast +/- 7)
      expect(scout.potentialEstimationMargin, inInclusiveRange(1, 3));

      // Weryfikacja krajów w regionie Andy / Ameryka Płd.
      expect(scout.isCountryInRegion('COL'), isTrue);
      expect(scout.isCountryInRegion('ECU'), isTrue);
      expect(scout.isCountryInRegion('POL'), isFalse);
    });

    test('Serializacja Scout do i z JSON', () {
      const scout = Scout(
        id: 'scout_eu',
        firstName: 'Luc',
        lastName: 'Meersman',
        nationalityIso: 'BEL',
        age: 49,
        experienceLevel: 83,
        monthlySalaryEur: 6200,
        contractEndYear: 2027,
        reputation: 82,
        talentDiscoveryRating: 85,
        evaluationPrecision: 84,
        assignedRegion: ScoutingRegion.westernEurope,
        networkReach: 86,
        specialtyFocus: ScoutTalentFocus.cobblesClassicsSpecialists,
      );

      final json = scout.toJson();
      final restored = StaffMember.fromJson(json) as Scout;

      expect(restored.id, equals('scout_eu'));
      expect(restored.assignedRegion, equals(ScoutingRegion.westernEurope));
      expect(restored.specialtyFocus, equals(ScoutTalentFocus.cobblesClassicsSpecialists));
    });
  });

  group('StaffMember - FullTeamStaffRoster & Generator Proceduralny', () {
    test('FullTeamStaffRoster poprawnie agreguje poziomy do TeamStaff', () {
      final roster = StaffProceduralGenerator.generateDefaultTeamStaffRoster(
        division: TeamDivision.worldTour,
        teamCountryIso: 'POL',
        seed: 123,
      );

      expect(roster.sportsDirectors.length, equals(2));
      expect(roster.coaches.length, equals(2));
      expect(roster.doctors.length, equals(1));
      expect(roster.mechanics.length, equals(2));
      expect(roster.scouts.length, equals(2));
      expect(roster.allMembers.length, equals(9));

      // Konwersja do modelu TeamStaff
      final teamStaff = roster.toTeamStaff();
      expect(teamStaff.sportsDirectorsLevel, inInclusiveRange(70, 95));
      expect(teamStaff.trainersLevel, inInclusiveRange(70, 95));
      expect(teamStaff.doctorsLevel, inInclusiveRange(70, 95));
      expect(teamStaff.mechanicsLevel, inInclusiveRange(70, 95));
      expect(teamStaff.scoutsLevel, inInclusiveRange(70, 95));

      // Wynagrodzenia
      expect(roster.totalMonthlySalariesEur, greaterThan(40000));
    });

    test('Serializacja FullTeamStaffRoster do i z JSON', () {
      final roster = StaffProceduralGenerator.generateDefaultTeamStaffRoster(
        division: TeamDivision.proTeam,
        teamCountryIso: 'BEL',
        seed: 456,
      );

      final json = roster.toJson();
      final restored = FullTeamStaffRoster.fromJson(json);

      expect(restored.sportsDirectors.length, equals(roster.sportsDirectors.length));
      expect(restored.doctors.first.firstName, equals(roster.doctors.first.firstName));
      expect(restored.totalMonthlySalariesEur, equals(roster.totalMonthlySalariesEur));
    });

    test('Rynek Wolnych Agentów i premia za podpisanie (signingBonusEur)', () {
      final pool = StaffProceduralGenerator.generateFreeAgentMarketPool(
        countPerRole: 2,
        seed: 888,
      );

      expect(pool.length, equals(10));
      for (final member in pool) {
        expect(member.monthlySalaryEur, greaterThan(3000));
        expect(member.signingBonusEur, equals((member.monthlySalaryEur * 2.5).round()));
      }
    });

    test('TrainingGroup wylicza synergię profilu trenera i bonus progresji', () {
      const coach = PerformanceCoach(
        id: 'c_climb',
        firstName: 'Michele',
        lastName: 'Ferrari',
        nationalityIso: 'ITA',
        age: 48,
        experienceLevel: 90,
        monthlySalaryEur: 14000,
        contractEndYear: 2027,
        reputation: 92,
        ftpDevelopmentEfficiency: 92,
        sprintAndNeuromuscularFocus: 60,
        winterGymPeriodizationSkill: 85,
        overtrainingPrevention: 88,
        specialization: CoachSpecialization.enduranceAndClimbing,
      );

      final r1 = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.gcClimber,
      );
      final r2 = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.pureClimber,
      );
      final r3 = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.pureSprinter,
      );

      final group = TrainingGroup(
        id: 'grp_gc',
        name: 'Grupa Górska',
        description: 'Wspinaczka i VO2max',
        focusSpecialization: CoachSpecialization.enduranceAndClimbing,
        assignedCoachId: coach.id,
        assignedRiderIds: [r1.id, r2.id, r3.id],
      );

      final synergyRatio = group.calculateSynergyRatio(coach, [r1, r2, r3]);
      expect(synergyRatio, greaterThan(0.65));

      final bonusPercent = group.calculateSynergyBonusPercent(coach, [r1, r2, r3]);
      expect(bonusPercent, inInclusiveRange(12, 20));

      final json = group.toJson();
      final fromJson = TrainingGroup.fromJson(json);
      expect(fromJson.name, equals('Grupa Górska'));
      expect(fromJson.focusSpecialization, equals(CoachSpecialization.enduranceAndClimbing));
    });

    test('RaceDirectorAssignment zapisuje i deserializuje obsadę wozów na wyścig', () {
      final assignment = RaceDirectorAssignment(
        raceId: 'tour_de_france_2026',
        raceName: 'Tour de France 2026',
        leadDirectorId: 'ds_1',
        supportDirectorId: 'ds_2',
        assignedAt: DateTime(2026, 7, 1),
      );

      final json = assignment.toJson();
      final fromJson = RaceDirectorAssignment.fromJson(json);

      expect(fromJson.raceId, equals('tour_de_france_2026'));
      expect(fromJson.leadDirectorId, equals('ds_1'));
      expect(fromJson.supportDirectorId, equals('ds_2'));
    });
  });
}

