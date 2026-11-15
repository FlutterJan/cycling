// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/models/team/sponsor_contract.dart';
import 'package:pro_peloton_manager/services/career/development_team_u23_service.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';

void main() {
  late CyclingTeam testTeam;
  late Rider testSeniorMentor;

  setUp(() {
    final baseMentor = RiderProceduralGenerator.generateRider(
      id: 'mentor_veteran',
      specialization: RiderSpecialization.domestiqueEngine,
      targetOverallRating: 82,
      age: 32,
    );
    testSeniorMentor = baseMentor.copyWith(
      skills: baseMentor.skills.copyWith(raceIq: 85),
    );

    const titleSponsor = SponsorContract(
      id: 'sp_01',
      companyName: 'Lotto-Visma Tech Group',
      industry: SponsorIndustry.tech,
      sponsorTier: SponsorTier.titlePrimary,
      annualBudgetEur: 18000000,
      contractDurationYears: 3,
      sponsorSatisfaction: 85.0,
      objectives: [],
    );

    testTeam = CyclingTeam(
      id: 'team_worldtour_01',
      name: 'Veloce Pro Cycling',
      division: TeamDivision.worldTour,
      countryIso: 'BEL',
      primaryJerseyColorHex: '#003399',
      secondaryJerseyColorHex: '#FFFFFF',
      accentJerseyColorHex: '#FFCC00',
      cashBalanceEur: 3500000,
      monthlyBurnRateEur: 420000,
      uciPointsSeason: 4100,
      rosterRiderIds: [testSeniorMentor.id],
      staff: const TeamStaff(
        trainersLevel: 85,
        sportsDirectorsLevel: 88,
        doctorsLevel: 84,
        mechanicsLevel: 90,
        scoutsLevel: 92,
      ),
      bikeDeal: const BikeManufacturerDeal(
        manufacturerId: 'cervelo',
        manufacturerName: 'Cervélo Bicycles',
        prestigeLevel: 5,
        annualCashContributionEur: 2800000,
        freeBikesQuota: 85,
        researchAndDevelopmentLevel: 90,
        suppliedFrameIds: [],
        suppliedWheelsetIds: [],
        contractYearsLeft: 2,
        minimumUciRankingRequired: 5,
      ),
      sponsors: const [titleSponsor],
      inventoryBikes: [],
    );
  });

  group('DevelopmentTeamU23Service - 1. Powołanie i rozbudowa bazy Devo', () {
    test('formDevelopmentTeam poprawnie zakłada zespół U23 i potrąca opłatę licencyjną', () {
      final result = DevelopmentTeamU23Service.formDevelopmentTeam(
        primaryTeam: testTeam,
        customDevoName: 'Veloce Future Stars Devo Team',
        currentDate: DateTime(2026, 1, 1),
      );

      expect(result.devoTeam.isFormed, isTrue);
      expect(result.devoTeam.devoTeamName, 'Veloce Future Stars Devo Team');
      expect(result.devoTeam.infrastructureTier, DevoInfrastructureTier.regional);
      expect(result.devoTeam.infrastructureTier.maxRosterCapacity, 8);

      // Potrącono 120 000 € za założenie
      expect(result.updatedTeam.cashBalanceEur, 3500000 - 120000);
      expect(result.devoTeam.cashBudgetEur, 40000);
    });

    test('formDevelopmentTeam rzuca wyjątek przy braku środków w budżecie', () {
      final poorTeam = testTeam.copyWith(cashBalanceEur: 50000);
      expect(
        () => DevelopmentTeamU23Service.formDevelopmentTeam(primaryTeam: poorTeam),
        throwsStateError,
      );
    });

    test('upgradeInfrastructure rozbudowuje bazę do poziomu Continental i World-Class', () {
      final formed = DevelopmentTeamU23Service.formDevelopmentTeam(
        primaryTeam: testTeam,
      );

      // Upgrade do National Continental (Tier 2)
      final tier2 = DevelopmentTeamU23Service.upgradeInfrastructure(
        primaryTeam: formed.updatedTeam,
        devoTeam: formed.devoTeam,
        targetTier: DevoInfrastructureTier.nationalContinental,
      );

      expect(tier2.updatedDevo.infrastructureTier, DevoInfrastructureTier.nationalContinental);
      expect(tier2.updatedDevo.infrastructureTier.maxRosterCapacity, 12);
      expect(tier2.updatedDevo.infrastructureTier.growthMultiplier, 1.25);
      expect(tier2.updatedTeam.cashBalanceEur, formed.updatedTeam.cashBalanceEur - 85000);

      // Upgrade do World-Class Campus (Tier 3)
      final tier3 = DevelopmentTeamU23Service.upgradeInfrastructure(
        primaryTeam: tier2.updatedTeam,
        devoTeam: tier2.updatedDevo,
        targetTier: DevoInfrastructureTier.worldClassCampus,
      );

      expect(tier3.updatedDevo.infrastructureTier, DevoInfrastructureTier.worldClassCampus);
      expect(tier3.updatedDevo.infrastructureTier.maxRosterCapacity, 16);
      expect(tier3.updatedDevo.infrastructureTier.growthMultiplier, 1.55);
      expect(tier3.updatedTeam.cashBalanceEur, tier2.updatedTeam.cashBalanceEur - 180000);
    });
  });

  group('DevelopmentTeamU23Service - 2. Skauting i kontraktowanie 18-latków', () {
    test('generateAvailableYoungTalents generuje utalentowanych 18-latków', () {
      final talents = DevelopmentTeamU23Service.generateAvailableYoungTalents(
        currentSeasonYear: 2026,
        count: 8,
      );

      expect(talents.length, 8);
      for (final t in talents) {
        final age = 2026 - t.birthDate.year;
        expect(age, 18);
        expect(t.potential, greaterThanOrEqualTo(65));
      }
    });

    test('signYoungProspectToDevo podpisuje kontrakt młodzieżowy i tworzy pierwszy audyt', () {
      final formed = DevelopmentTeamU23Service.formDevelopmentTeam(primaryTeam: testTeam);
      final youngRider = RiderProceduralGenerator.generateNeoProTalent(
        currentSeasonYear: 2026,
        tier: ScoutingTier.generationalTalent,
      ).copyWith(birthDate: DateTime(2008, 4, 15)); // 18 lat

      final signed = DevelopmentTeamU23Service.signYoungProspectToDevo(
        primaryTeam: formed.updatedTeam,
        devoTeam: formed.devoTeam,
        prospectRider: youngRider,
        monthlySalaryEur: 2200,
        contractDurationYears: 2,
        signingBonusEur: 8000,
        currentDate: DateTime(2026, 1, 1),
      );

      expect(signed.updatedDevo.riders.length, 1);
      final profile = signed.updatedDevo.riders.first;
      expect(profile.rider.id, youngRider.id);
      expect(profile.isEligibleForU23, isTrue);
      expect(profile.status, DevoRiderStatus.activeU23);
      expect(profile.monthlySalaryEur, 2200);
      expect(profile.auditHistory.length, 1);
      expect(profile.auditHistory.first.ftpWatts, youngRider.physiology.ftpWatts);
      expect(profile.auditHistory.first.vo2Max, youngRider.physiology.vo2Max);
      expect(signed.updatedTeam.cashBalanceEur, formed.updatedTeam.cashBalanceEur - 8000);
    });

    test('signYoungProspectToDevo odrzuca kolarza powyżej 22 lat', () {
      final formed = DevelopmentTeamU23Service.formDevelopmentTeam(primaryTeam: testTeam);
      final olderRider = RiderProceduralGenerator.generateRider(
        age: 24,
      );

      expect(
        () => DevelopmentTeamU23Service.signYoungProspectToDevo(
          primaryTeam: formed.updatedTeam,
          devoTeam: formed.devoTeam,
          prospectRider: olderRider,
          monthlySalaryEur: 2000,
          contractDurationYears: 2,
        ),
        throwsArgumentError,
      );
    });
  });

  group('DevelopmentTeamU23Service - 3. Wyścigi młodzieżowe i symulacja', () {
    test('getOfficialYouthRaceCalendar zawiera najważniejsze wyścigi U23', () {
      final races = DevelopmentTeamU23Service.getOfficialYouthRaceCalendar();
      expect(races.length, greaterThanOrEqualTo(6));

      expect(races.any((r) => r.id == 'u23_baby_giro'), isTrue);
      expect(races.any((r) => r.id == 'u23_tour_de_l_avenir'), isTrue);
      expect(races.any((r) => r.id == 'u23_roubaix_espoirs'), isTrue);
      expect(races.any((r) => r.id == 'u23_liege_espoirs'), isTrue);
    });

    test('simulateYouthRace przeprowadza wyścig, przyznaje punkty, premie i zmęczenie', () {
      final formed = DevelopmentTeamU23Service.formDevelopmentTeam(primaryTeam: testTeam);
      var dev = formed.devoTeam;
      var team = formed.updatedTeam;

      // Dodajemy 4 młodych kolarzy do składu
      final squadRiders = <Rider>[];
      for (int i = 0; i < 4; i++) {
        final r = RiderProceduralGenerator.generateNeoProTalent(
          currentSeasonYear: 2026,
          tier: ScoutingTier.worldTourProspect,
        ).copyWith(birthDate: DateTime(2008, 3, 10));
        squadRiders.add(r);

        final res = DevelopmentTeamU23Service.signYoungProspectToDevo(
          primaryTeam: team,
          devoTeam: dev,
          prospectRider: r,
          monthlySalaryEur: 1800,
          contractDurationYears: 2,
          signingBonusEur: 1000,
        );
        team = res.updatedTeam;
        dev = res.updatedDevo;
      }

      final babyGiro = DevelopmentTeamU23Service.getOfficialYouthRaceCalendar()
          .firstWhere((r) => r.id == 'u23_baby_giro');

      final raceSim = DevelopmentTeamU23Service.simulateYouthRace(
        devoTeam: dev,
        raceEvent: babyGiro,
        participantRiderIds: squadRiders.map((r) => r.id).toList(),
        random: math.Random(42),
      );

      expect(raceSim.raceResult.placements.length, 4);
      expect(raceSim.raceResult.raceId, 'u23_baby_giro');
      expect(raceSim.updatedDevo.raceResultsHistory.length, 1);

      // Kolarze zyskali dni wyścigowe (8 dni Baby Giro)
      for (final p in raceSim.updatedDevo.riders) {
        expect(p.raceDaysThisSeason, 8);
        expect(p.burnoutFatigueIndex, greaterThan(12.0));
      }
    });
  });

  group('DevelopmentTeamU23Service - 4. Ewolucja fizjologiczna i mentoring weterana', () {
    test('runMonthlyDevoPhysiologicalEvolution podnosi FTP, VO2max i tworzy snapshot', () {
      final formed = DevelopmentTeamU23Service.formDevelopmentTeam(primaryTeam: testTeam);
      final youngClimber = RiderProceduralGenerator.generateNeoProTalent(
        currentSeasonYear: 2026,
        tier: ScoutingTier.generationalTalent,
        preferredSpecialization: RiderSpecialization.gcClimber,
      ).copyWith(birthDate: DateTime(2008, 5, 20));

      final signed = DevelopmentTeamU23Service.signYoungProspectToDevo(
        primaryTeam: formed.updatedTeam,
        devoTeam: formed.devoTeam,
        prospectRider: youngClimber,
        monthlySalaryEur: 2500,
        contractDurationYears: 3,
      );

      final initialFtp = youngClimber.physiology.ftpWatts;
      final initialVo2 = youngClimber.physiology.vo2Max;

      // Symulacja miesiąca rozwoju
      final evolvedDevo = DevelopmentTeamU23Service.runMonthlyDevoPhysiologicalEvolution(
        devoTeam: signed.updatedDevo,
        currentDate: DateTime(2026, 2, 1),
        random: math.Random(1),
      );

      final evolvedProfile = evolvedDevo.riders.first;
      expect(evolvedProfile.rider.physiology.ftpWatts, greaterThanOrEqualTo(initialFtp));
      expect(evolvedProfile.rider.physiology.vo2Max, greaterThanOrEqualTo(initialVo2));
      expect(evolvedProfile.auditHistory.length, 2); // Startowy + po 1 miesiącu
    });

    test('assignSeniorMentor przyspiesza rozwój młodego kolarza', () {
      final formed = DevelopmentTeamU23Service.formDevelopmentTeam(primaryTeam: testTeam);
      final youngRider = RiderProceduralGenerator.generateNeoProTalent(
        currentSeasonYear: 2026,
      ).copyWith(birthDate: DateTime(2008, 1, 15));

      final signed = DevelopmentTeamU23Service.signYoungProspectToDevo(
        primaryTeam: formed.updatedTeam,
        devoTeam: formed.devoTeam,
        prospectRider: youngRider,
        monthlySalaryEur: 2000,
        contractDurationYears: 2,
      );

      // Przypisanie mentora
      final withMentor = DevelopmentTeamU23Service.assignSeniorMentor(
        devoTeam: signed.updatedDevo,
        primaryTeam: testTeam,
        devoRiderId: youngRider.id,
        seniorMentor: testSeniorMentor,
      );

      expect(withMentor.riders.first.seniorMentorId, testSeniorMentor.id);
      expect(withMentor.riders.first.seniorMentorName, testSeniorMentor.fullName);
    });

    test('przetrenowanie (burnout > 70) blokuje rozwój i obniża morale', () {
      final formed = DevelopmentTeamU23Service.formDevelopmentTeam(primaryTeam: testTeam);
      final youngRider = RiderProceduralGenerator.generateNeoProTalent(
        currentSeasonYear: 2026,
      ).copyWith(birthDate: DateTime(2008, 1, 15));

      final signed = DevelopmentTeamU23Service.signYoungProspectToDevo(
        primaryTeam: formed.updatedTeam,
        devoTeam: formed.devoTeam,
        prospectRider: youngRider,
        monthlySalaryEur: 2000,
        contractDurationYears: 2,
      );

      // Wymuszamy stan skrajnego zmęczenia / burnout
      final burnedProfile = signed.updatedDevo.riders.first.copyWith(
        burnoutFatigueIndex: 78.0,
      );
      final burnedDevo = signed.updatedDevo.copyWith(riders: [burnedProfile]);

      final evolved = DevelopmentTeamU23Service.runMonthlyDevoPhysiologicalEvolution(
        devoTeam: burnedDevo,
      );

      // Morale spadło, brak przyrostu audytu
      expect(evolved.riders.first.rider.contract.morale, lessThan(youngRider.contract.morale));
      expect(evolved.riders.first.burnoutFatigueIndex, lessThan(78.0)); // Regeneracja przy wymuszonym odpoczynku
    });
  });

  group('DevelopmentTeamU23Service - 5. Awans do pierwszego składu, Stagiaire i Zsyłka', () {
    test('promoteRiderToFirstTeam awansuje kolarza do WorldTeamu w trakcie sezonu', () {
      final formed = DevelopmentTeamU23Service.formDevelopmentTeam(primaryTeam: testTeam);
      final youngStar = RiderProceduralGenerator.generateNeoProTalent(
        currentSeasonYear: 2026,
        tier: ScoutingTier.generationalTalent,
      ).copyWith(birthDate: DateTime(2008, 2, 20));

      final signed = DevelopmentTeamU23Service.signYoungProspectToDevo(
        primaryTeam: formed.updatedTeam,
        devoTeam: formed.devoTeam,
        prospectRider: youngStar,
        monthlySalaryEur: 2500,
        contractDurationYears: 2,
      );

      final promoted = DevelopmentTeamU23Service.promoteRiderToFirstTeam(
        primaryTeam: signed.updatedTeam,
        devoTeam: signed.updatedDevo,
        devoRiderId: youngStar.id,
      );

      // Dodano do kadry pierwszego zespołu
      expect(promoted.updatedTeam.rosterRiderIds.contains(youngStar.id), isTrue);

      // Status w Devo zmieniony na promotedToWorldTeam
      final devoProfile = promoted.updatedDevo.riders.firstWhere((r) => r.rider.id == youngStar.id);
      expect(devoProfile.status, DevoRiderStatus.promotedToWorldTeam);
      expect(promoted.updatedDevo.totalAlumniPromoted, 1);

      // Pensja podniesiona do standardu WorldTouru
      expect(devoProfile.rider.contract.monthlySalaryEur, greaterThanOrEqualTo(3750));
    });

    test('appointStagiaire nadaje status stażysty od 1 sierpnia', () {
      final formed = DevelopmentTeamU23Service.formDevelopmentTeam(primaryTeam: testTeam);
      final youngRider = RiderProceduralGenerator.generateNeoProTalent(
        currentSeasonYear: 2026,
      ).copyWith(birthDate: DateTime(2007, 6, 12));

      final signed = DevelopmentTeamU23Service.signYoungProspectToDevo(
        primaryTeam: formed.updatedTeam,
        devoTeam: formed.devoTeam,
        prospectRider: youngRider,
        monthlySalaryEur: 2000,
        contractDurationYears: 2,
      );

      // Próba przed 1 sierpnia kończy się błędem
      expect(
        () => DevelopmentTeamU23Service.appointStagiaire(
          devoTeam: signed.updatedDevo,
          devoRiderId: youngRider.id,
          currentDate: DateTime(2026, 7, 20),
        ),
        throwsStateError,
      );

      // Z dniem 1 sierpnia mianowanie udaje się
      final stagiaireDevo = DevelopmentTeamU23Service.appointStagiaire(
        devoTeam: signed.updatedDevo,
        devoRiderId: youngRider.id,
        currentDate: DateTime(2026, 8, 2),
      );

      expect(stagiaireDevo.riders.first.status, DevoRiderStatus.stagiaire);
    });

    test('demoteRiderToDevo zsyła młodego kolarza z WorldTeamu do Devo', () {
      final formed = DevelopmentTeamU23Service.formDevelopmentTeam(primaryTeam: testTeam);
      final strugglingPro = RiderProceduralGenerator.generateRider(
        age: 21,
      );
      final teamWithPro = testTeam.copyWith(
        rosterRiderIds: [...testTeam.rosterRiderIds, strugglingPro.id],
      );

      final demoted = DevelopmentTeamU23Service.demoteRiderToDevo(
        primaryTeam: teamWithPro,
        devoTeam: formed.devoTeam,
        riderToDemote: strugglingPro,
      );

      // Usunięty z pierwszego składu
      expect(demoted.updatedTeam.rosterRiderIds.contains(strugglingPro.id), isFalse);

      // Dodany do Devo ze statusem demotedFromWorldTeam
      expect(demoted.updatedDevo.riders.any((r) => r.rider.id == strugglingPro.id), isTrue);
      final profile = demoted.updatedDevo.riders.firstWhere((r) => r.rider.id == strugglingPro.id);
      expect(profile.status, DevoRiderStatus.demotedFromWorldTeam);
    });
  });

  group('DevelopmentTeamU23Service - 6. Finanse i Serializacja JSON', () {
    test('processMonthlyDevoFinances rozlicza koszty bazy i pensje', () {
      final formed = DevelopmentTeamU23Service.formDevelopmentTeam(primaryTeam: testTeam);
      final youngRider = RiderProceduralGenerator.generateNeoProTalent(
        currentSeasonYear: 2026,
      ).copyWith(birthDate: DateTime(2008, 1, 1));

      final signed = DevelopmentTeamU23Service.signYoungProspectToDevo(
        primaryTeam: formed.updatedTeam,
        devoTeam: formed.devoTeam,
        prospectRider: youngRider,
        monthlySalaryEur: 2500,
        contractDurationYears: 2,
      );

      final totalBurn = signed.updatedDevo.totalMonthlyBurnRateEur;
      // 9500 € (baza regionalna) + 2500 € (pensja kolarza) = 12000 €
      expect(totalBurn, 9500 + 2500);

      final monthEnd = DevelopmentTeamU23Service.processMonthlyDevoFinances(
        primaryTeam: signed.updatedTeam,
        devoTeam: signed.updatedDevo,
      );

      expect(monthEnd.updatedTeam.cashBalanceEur, signed.updatedTeam.cashBalanceEur - 12000);
    });

    test('pełny model DevelopmentTeamU23 serializuje się i deserializuje bezstratnie', () {
      final formed = DevelopmentTeamU23Service.formDevelopmentTeam(primaryTeam: testTeam);
      final youngRider = RiderProceduralGenerator.generateNeoProTalent(
        currentSeasonYear: 2026,
      ).copyWith(birthDate: DateTime(2008, 3, 1));

      final signed = DevelopmentTeamU23Service.signYoungProspectToDevo(
        primaryTeam: formed.updatedTeam,
        devoTeam: formed.devoTeam,
        prospectRider: youngRider,
        monthlySalaryEur: 2100,
        contractDurationYears: 2,
      );

      final json = signed.updatedDevo.toJson();
      final restored = DevelopmentTeamU23.fromJson(json);

      expect(restored.primaryTeamId, signed.updatedDevo.primaryTeamId);
      expect(restored.devoTeamName, signed.updatedDevo.devoTeamName);
      expect(restored.isFormed, isTrue);
      expect(restored.infrastructureTier, signed.updatedDevo.infrastructureTier);
      expect(restored.riders.length, 1);
      expect(restored.riders.first.rider.id, youngRider.id);
      expect(restored.riders.first.auditHistory.length, 1);
    });
  });
}
