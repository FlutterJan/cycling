// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/staff_member.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/models/team/sponsor_contract.dart';
import 'package:pro_peloton_manager/services/career/anti_doping_and_whereabouts_service.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';

void main() {
  late Rider testLeader;
  late Rider testDomestique;
  late TeamDoctor eliteDoctor;
  late TeamDoctor noviceDoctor;
  late CyclingTeam testTeam;

  setUp(() {
    testLeader = RiderProceduralGenerator.generateRider(
      id: 'leader_gc',
      specialization: RiderSpecialization.gcClimber,
      targetOverallRating: 88,
    );

    testDomestique = RiderProceduralGenerator.generateRider(
      id: 'domestique_01',
      specialization: RiderSpecialization.domestiqueEngine,
      targetOverallRating: 76,
    );

    eliteDoctor = const TeamDoctor(
      id: 'doc_elite',
      firstName: 'Michele',
      lastName: 'Ferrari-Ethics',
      nationalityIso: 'ITA',
      age: 52,
      experienceLevel: 95,
      monthlySalaryEur: 14000,
      contractEndYear: 2028,
      reputation: 92,
      bloodDiagnosticsSkill: 96,
      infectionPreventionAndHygiene: 92,
      fractureAndOrthopedicRehabSpeed: 90,
      woundHealingCare: 92,
    );

    noviceDoctor = const TeamDoctor(
      id: 'doc_novice',
      firstName: 'Jan',
      lastName: 'Kowalski-Med',
      nationalityIso: 'POL',
      age: 29,
      experienceLevel: 45,
      monthlySalaryEur: 3500,
      contractEndYear: 2027,
      reputation: 50,
      bloodDiagnosticsSkill: 48,
      infectionPreventionAndHygiene: 50,
      fractureAndOrthopedicRehabSpeed: 45,
      woundHealingCare: 50,
    );

    const titleSponsor = SponsorContract(
      id: 'sponsor_title',
      companyName: 'TotalEnergies Mega Corp',
      industry: SponsorIndustry.energy,
      sponsorTier: SponsorTier.titlePrimary,
      annualBudgetEur: 12000000,
      contractDurationYears: 3,
      sponsorSatisfaction: 85.0,
      objectives: [],
    );

    const subSponsor = SponsorContract(
      id: 'sponsor_sub',
      companyName: 'Shimano Components',
      industry: SponsorIndustry.tech,
      sponsorTier: SponsorTier.majorPartner,
      annualBudgetEur: 2500000,
      contractDurationYears: 2,
      sponsorSatisfaction: 80.0,
      objectives: [],
    );

    testTeam = CyclingTeam(
      id: 'team_pro',
      name: 'Veloce Racing WorldTour',
      division: TeamDivision.worldTour,
      countryIso: 'FR',
      primaryJerseyColorHex: '#003399',
      secondaryJerseyColorHex: '#FFFFFF',
      accentJerseyColorHex: '#FFCC00',
      cashBalanceEur: 3500000,
      monthlyBurnRateEur: 450000,
      uciPointsSeason: 2800,
      rosterRiderIds: [testLeader.id, testDomestique.id],
      staff: const TeamStaff(
        trainersLevel: 85,
        sportsDirectorsLevel: 85,
        doctorsLevel: 90,
        mechanicsLevel: 85,
        scoutsLevel: 80,
      ),
      bikeDeal: const BikeManufacturerDeal(
        manufacturerId: 'brand_colnago',
        manufacturerName: 'Colnago',
        prestigeLevel: 5,
        annualCashContributionEur: 1500000,
        freeBikesQuota: 80,
        researchAndDevelopmentLevel: 90,
        suppliedFrameIds: ['frame_v4rs'],
        suppliedWheelsetIds: ['wheels_enve'],
        contractYearsLeft: 3,
        minimumUciRankingRequired: 10,
      ),
      sponsors: const [titleSponsor, subSponsor],
      inventoryBikes: const [],
    );
  });

  group('AntiDopingAndWhereaboutsService - 1. Paszport Biologiczny UCI (ABP)', () {
    test('calculateOffScore wylicza wskaźnik Gore\'a zgodnie ze standardami WADA', () {
      // Przykład wzorcowy: Hb 15.0 g/dL, RET 1.0% -> OFF = 150 - 60*1 = 90.0
      final normalOff = AntiDopingAndWhereaboutsService.calculateOffScore(
        hemoglobinGDL: 15.0,
        reticulocytesPercent: 1.0,
      );
      expect(normalOff, equals(90.0));

      // Podejrzana manipulacja krwią / mikro-dawkowanie:
      // Wysoka hemoglobina 16.5 g/dL i stłumione retikulocyty 0.25% (sqrt(0.25) = 0.5)
      // OFF = 165 - 60*0.5 = 165 - 30 = 135.0 (Ekstremalna anomalia!)
      final suspiciousOff = AntiDopingAndWhereaboutsService.calculateOffScore(
        hemoglobinGDL: 16.5,
        reticulocytesPercent: 0.25,
      );
      expect(suspiciousOff, equals(135.0));
      expect(suspiciousOff, greaterThan(125.0));
    });

    test('generatePassportSample poprawnie tworzy próbkę i wykrywa anomalię', () {
      final cleanSample = AntiDopingAndWhereaboutsService.generatePassportSample(
        rider: testLeader,
        testType: AntiDopingTestType.inCompetition,
        sampleDate: DateTime(2026, 7, 14),
        customHemoglobin: 15.2,
        customReticulocytes: 1.1,
        customTeRatio: 1.2,
      );

      expect(cleanSample.hemoglobinGDL, equals(15.2));
      expect(cleanSample.reticulocytesPercent, equals(1.1));
      expect(cleanSample.testosteroneEpitestosteroneRatio, equals(1.2));
      expect(cleanSample.offScore, inInclusiveRange(85.0, 95.0));
      expect(cleanSample.isAtypicalAnomaly, isFalse);

      // Anomalia: skrajny OFF-score lub przekroczenie limitu UCI 50% hematokrytu
      final anomalySample = AntiDopingAndWhereaboutsService.generatePassportSample(
        rider: testLeader,
        testType: AntiDopingTestType.targetedAudit,
        sampleDate: DateTime(2026, 7, 18),
        customHemoglobin: 17.5,
        customReticulocytes: 0.20,
        customTeRatio: 4.8,
      );
      expect(anomalySample.isAtypicalAnomaly, isTrue);
      expect(anomalySample.testosteroneEpitestosteroneRatio, greaterThan(4.0));
    });

    test('evaluateBiologicalPassport podnosi status podejrzenia i wszczyna postępowanie przy powtarzających się anomaliach', () {
      final sample1 = AntiDopingAndWhereaboutsService.generatePassportSample(
        rider: testLeader,
        testType: AntiDopingTestType.inCompetition,
        sampleDate: DateTime(2026, 5, 10),
        customHemoglobin: 15.0,
        customReticulocytes: 1.0,
      );

      final sample2 = AntiDopingAndWhereaboutsService.generatePassportSample(
        rider: testLeader,
        testType: AntiDopingTestType.inCompetition,
        sampleDate: DateTime(2026, 6, 12),
        customHemoglobin: 16.8,
        customReticulocytes: 0.22, // Anomalia OFF > 120
      );

      final sample3 = AntiDopingAndWhereaboutsService.generatePassportSample(
        rider: testLeader,
        testType: AntiDopingTestType.targetedAudit,
        sampleDate: DateTime(2026, 7, 2),
        customHemoglobin: 17.0,
        customReticulocytes: 0.20, // Druga anomalia OFF > 120
      );

      var passport = AthleteBiologicalPassport(
        riderId: testLeader.id,
        samples: [sample1],
      );
      passport = AntiDopingAndWhereaboutsService.evaluateBiologicalPassport(passport);
      expect(passport.status, equals(BiologicalPassportStatus.normalClean));

      // Dodajemy jedną anomalię
      passport = passport.copyWith(samples: [sample1, sample2]);
      passport = AntiDopingAndWhereaboutsService.evaluateBiologicalPassport(passport);
      expect(passport.status, equals(BiologicalPassportStatus.suspiciousProfile));
      expect(passport.suspicionScore, greaterThanOrEqualTo(70));

      // Dodajemy drugą anomalię -> natychmiastowe postępowanie dyscyplinarne UCI!
      passport = passport.copyWith(samples: [sample1, sample2, sample3]);
      passport = AntiDopingAndWhereaboutsService.evaluateBiologicalPassport(passport);
      expect(passport.status, equals(BiologicalPassportStatus.disciplinaryProceedings));
      expect(passport.suspicionScore, greaterThanOrEqualTo(90));
      expect(passport.expertNotes.last, contains('Panel Niezależnych Ekspertów UCI'));
    });
  });

  group('AntiDopingAndWhereaboutsService - 2. System ADAMS & Whereabouts', () {
    test('WhereaboutsStrike weryfikuje ważność 365 dni i regułę 3 naruszeń', () {
      final now = DateTime(2026, 8, 1);

      final strikeOld = WhereaboutsStrike(
        id: 's1',
        riderId: testLeader.id,
        type: WhereaboutsFailureType.missedTest,
        incidentDate: DateTime(2025, 7, 1), // ponad 365 dni temu
        explanation: 'Nieobecność o 06:00 w hotelu',
      );

      final strikeRecent1 = WhereaboutsStrike(
        id: 's2',
        riderId: testLeader.id,
        type: WhereaboutsFailureType.filingFailure,
        incidentDate: DateTime(2026, 2, 10),
        explanation: 'Spóźniony kwartalny raport ADAMS',
      );

      final strikeRecent2 = WhereaboutsStrike(
        id: 's3',
        riderId: testLeader.id,
        type: WhereaboutsFailureType.missedTest,
        incidentDate: DateTime(2026, 5, 20),
        explanation: 'Brak kolarza pod wskazanym adresem',
      );

      final strikeRecent3 = WhereaboutsStrike(
        id: 's4',
        riderId: testLeader.id,
        type: WhereaboutsFailureType.missedTest,
        incidentDate: DateTime(2026, 7, 25),
        explanation: 'Brak kolarza w 60-minutowym oknie',
      );

      expect(strikeOld.isActiveAt(now), isFalse);
      expect(strikeRecent1.isActiveAt(now), isTrue);

      // Kolarz ma 2 aktywne incydenty - brak naruszenia dyskwalifikującego
      final twoStrikes = [strikeOld, strikeRecent1, strikeRecent2];
      final activeTwo = AntiDopingAndWhereaboutsService.getActiveWhereaboutsStrikes(
        allStrikes: twoStrikes,
        riderId: testLeader.id,
        currentDate: now,
      );
      expect(activeTwo.length, equals(2));
      expect(
        AntiDopingAndWhereaboutsService.hasWhereaboutsRuleViolation(
          allStrikes: twoStrikes,
          riderId: testLeader.id,
          currentDate: now,
        ),
        isFalse,
      );

      // Kolarz otrzymuje 3. strike w ciągu 12 miesięcy -> ZŁAMANIE PRZEPISÓW ANTYDOPINGOWYCH!
      final threeStrikes = [strikeOld, strikeRecent1, strikeRecent2, strikeRecent3];
      final activeThree = AntiDopingAndWhereaboutsService.getActiveWhereaboutsStrikes(
        allStrikes: threeStrikes,
        riderId: testLeader.id,
        currentDate: now,
      );
      expect(activeThree.length, equals(3));
      expect(
        AntiDopingAndWhereaboutsService.hasWhereaboutsRuleViolation(
          allStrikes: threeStrikes,
          riderId: testLeader.id,
          currentDate: now,
        ),
        isTrue,
      );
    });
  });

  group('AntiDopingAndWhereaboutsService - 3. Szara Strefa Medyczna & TUE', () {
    test('TherapeuticSubstance definiuje leki szarej strefy i ich profil działania', () {
      const triam = TherapeuticSubstance.triamcinolone;
      const cort = TherapeuticSubstance.oralCortisone;
      const tram = TherapeuticSubstance.tramadol;
      const salb = TherapeuticSubstance.salbutamolHighDose;

      expect(triam.wadaCategory, contains('S9'));
      expect(triam.performanceRetentionPercent, equals(0.92));
      expect(triam.detectionWindowDays, equals(10));

      expect(cort.detectionWindowDays, equals(6));
      expect(tram.wadaCategory, contains('opioidowe'));
      expect(salb.displayName, contains('Salbutamol'));
    });

    test('submitTueApplication: lekarz elitarny zwiększa szansę zatwierdzenia TUE, a brak wskazań skutkuje odrzuceniem', () {
      final now = DateTime(2026, 6, 1);
      const kneeInjury = Injury(
        name: 'Zapalenie ścięgna rzepki',
        type: InjuryType.kneeTendinitis,
        daysRemaining: 12,
        trainingAllowed: false,
      );

      // Z elitarnym lekarzem i dedykowanym ziarnem losowości
      final rngHigh = math.Random(42);
      final tueApproved = AntiDopingAndWhereaboutsService.submitTueApplication(
        rider: testLeader,
        injury: kneeInjury,
        substance: TherapeuticSubstance.triamcinolone,
        doctor: eliteDoctor,
        applicationDate: now,
        rng: rngHigh,
      );
      expect(tueApproved.substance, equals(TherapeuticSubstance.triamcinolone));
      expect(tueApproved.doctorName, equals(eliteDoctor.fullName));
      expect(tueApproved.status, equals(TueApplicationStatus.approved));
      expect(tueApproved.isValidAt(DateTime(2026, 6, 5)), isTrue);

      // Ze słabym lekarzem i złamaniem obojczyka (steryd spowalnia zrost kości)
      const clavicleInjury = Injury(
        name: 'Złamanie obojczyka',
        type: InjuryType.clavicleFracture,
        daysRemaining: 28,
        trainingAllowed: false,
      );
      final rngLow = math.Random(999);
      final tueRejected = AntiDopingAndWhereaboutsService.submitTueApplication(
        rider: testLeader,
        injury: clavicleInjury,
        substance: TherapeuticSubstance.triamcinolone,
        doctor: noviceDoctor,
        applicationDate: now,
        rng: rngLow,
      );
      expect(tueRejected.status, equals(TueApplicationStatus.rejected));
      expect(tueRejected.rejectionReason, contains('niewystarczającą'));
      expect(tueRejected.status.displayName, contains('Brak wskazań klinicznych'));
    });

    test('administerGreyZoneTreatment pozwala kontuzjowanemu kolarzowi na start i ustala okno detekcji', () {
      final now = DateTime(2026, 7, 1);
      const injury = Injury(
        name: 'Bolesne zapalenie ścięgna',
        type: InjuryType.kneeTendinitis,
        daysRemaining: 10,
        trainingAllowed: false, // Normalnie nie może jechać
      );

      final injuredLeader = testLeader.copyWith(
        health: testLeader.health.copyWith(currentInjury: injury),
      );

      final treatmentResult = AntiDopingAndWhereaboutsService.administerGreyZoneTreatment(
        rider: injuredLeader,
        substance: TherapeuticSubstance.triamcinolone,
        hasApprovedTue: true,
        treatmentDate: now,
      );

      // Kolarz ma teraz odblokowaną możliwość startu w etapie!
      expect(treatmentResult.updatedRider.health.currentInjury?.trainingAllowed, isTrue);

      // Okno detekcji: 10 dni
      final treatment = treatmentResult.treatment;
      expect(treatment.isDetectableAt(DateTime(2026, 7, 5)), isTrue);
      expect(treatment.isDetectableAt(DateTime(2026, 7, 15)), isFalse); // Wypłukany po 10 dniach
    });
  });

  group('AntiDopingAndWhereaboutsService - 4. Kontrole Antydopingowe i Wykrywanie Nadużyć', () {
    test('selectRidersForStageAntiDoping wybiera zwycięzcę, lidera i losowych kolarzy', () {
      final riders = List.generate(10, (i) {
        return RiderProceduralGenerator.generateRider(
          id: 'rider_$i',
          specialization: RiderSpecialization.domestiqueEngine,
          targetOverallRating: 70 + i,
        );
      });

      final winner = riders[0];
      final gcLeader = riders[1];

      final selected = AntiDopingAndWhereaboutsService.selectRidersForStageAntiDoping(
        stageWinner: winner,
        gcLeader: gcLeader,
        pelotonRiders: riders,
      );

      expect(selected, contains(winner));
      expect(selected, contains(gcLeader));
      expect(selected.length, inInclusiveRange(4, 5));
    });

    test('conductAntiDopingTest: czysty kolarz otrzymuje wynik negatywny', () {
      final testDate = DateTime(2026, 7, 10);
      final result = AntiDopingAndWhereaboutsService.conductAntiDopingTest(
        rider: testLeader,
        testType: AntiDopingTestType.inCompetition,
        testDate: testDate,
        activeTreatments: [],
        approvedTues: [],
      );

      expect(result.outcome, equals(DopingTestOutcome.negativeClean));
      expect(result.detectedSubstance, isNull);
      expect(result.labReportSummary, contains('Brak obecności substancji'));
    });

    test('conductAntiDopingTest: kolarz z zatwierdzonym TUE przechodzi kontrolę legalnie', () {
      final testDate = DateTime(2026, 7, 10);
      const substance = TherapeuticSubstance.triamcinolone;

      final treatment = ActiveMedicalTreatment(
        id: 'tr_1',
        riderId: testLeader.id,
        substance: substance,
        administeredDate: DateTime(2026, 7, 5),
        hasApprovedTue: true,
        detectionWindowEndDate: DateTime(2026, 7, 15),
      );

      final tue = TueApplication(
        id: 'tue_1',
        riderId: testLeader.id,
        riderName: testLeader.fullName,
        injuryType: InjuryType.kneeTendinitis,
        substance: substance,
        applicationDate: DateTime(2026, 7, 2),
        status: TueApplicationStatus.approved,
        doctorName: eliteDoctor.fullName,
        validUntil: DateTime(2026, 7, 20),
      );

      final result = AntiDopingAndWhereaboutsService.conductAntiDopingTest(
        rider: testLeader,
        testType: AntiDopingTestType.inCompetition,
        testDate: testDate,
        activeTreatments: [treatment],
        approvedTues: [tue],
      );

      expect(result.outcome, equals(DopingTestOutcome.negativeClean));
      expect(result.detectedSubstance, equals(substance));
      expect(result.isCoveredByValidTue, isTrue);
      expect(result.labReportSummary, contains('posiada ważne wyłączenie'));
    });

    test('conductAntiDopingTest: kolarz na leku BEZ TUE wpada na teście (Adverse Analytical Finding - AAF)', () {
      final testDate = DateTime(2026, 7, 10);
      const substance = TherapeuticSubstance.triamcinolone;

      // Zastosowano szarą strefę bez TUE
      final treatment = ActiveMedicalTreatment(
        id: 'tr_clandestine',
        riderId: testLeader.id,
        substance: substance,
        administeredDate: DateTime(2026, 7, 7),
        hasApprovedTue: false,
        detectionWindowEndDate: DateTime(2026, 7, 17),
      );

      final result = AntiDopingAndWhereaboutsService.conductAntiDopingTest(
        rider: testLeader,
        testType: AntiDopingTestType.inCompetition,
        testDate: testDate,
        activeTreatments: [treatment],
        approvedTues: [], // Brak ważnego TUE!
      );

      expect(result.outcome, equals(DopingTestOutcome.adverseAnalyticalFinding));
      expect(result.detectedSubstance, equals(substance));
      expect(result.isCoveredByValidTue, isFalse);
      expect(result.labReportSummary, contains('POZYTYWNY WYNIK ANALITYCZNY (AAF)'));
    });
  });

  group('AntiDopingAndWhereaboutsService - 5. Skandal Antydopingowy, Kary i Utrata Sponsora', () {
    test('processAntiDopingViolation i applyScandalConsequencesToTeam nakładają kary i mogą zerwać umowę sponsorską', () {
      final incidentDate = DateTime(2026, 7, 20);

      // Wymuszamy zerwanie umowy sponsora tytularnego za pomocą ziarna
      final rngTerminate = math.Random(1);

      final scandalReport = AntiDopingAndWhereaboutsService.processAntiDopingViolation(
        rider: testLeader,
        team: testTeam,
        substance: TherapeuticSubstance.triamcinolone,
        violationReason: 'Pozytywny wynik testu na obecność triamcynolonu bez TUE po etapie 14 Tour de France',
        incidentDate: incidentDate,
        isInCompetition: true,
        rng: rngTerminate,
      );

      // Zawieszenie zawodnika i odebranie punktów
      expect(scandalReport.sanction.suspensionMonths, equals(12));
      expect(scandalReport.sanction.uciPointsStripped, greaterThan(0));
      expect(scandalReport.sanction.isActiveAt(DateTime(2026, 10, 1)), isTrue);

      // Grzywna dla drużyny i straty reputacyjne
      expect(scandalReport.teamFineEur, inInclusiveRange(100000, 200000));
      expect(scandalReport.managerReputationPenalty, greaterThanOrEqualTo(35));
      expect(scandalReport.mediaReactionHeadline, contains('SKANDAL W PELETONIE'));

      // Aplikacja konsekwencji na drużynę
      final updatedTeam = AntiDopingAndWhereaboutsService.applyScandalConsequencesToTeam(
        team: testTeam,
        report: scandalReport,
      );

      // Gotówka pomniejszona o grzywnę
      expect(updatedTeam.cashBalanceEur, equals(testTeam.cashBalanceEur - scandalReport.teamFineEur));

      // Punkty UCI pomniejszone
      expect(updatedTeam.uciPointsSeason, equals(testTeam.uciPointsSeason - scandalReport.sanction.uciPointsStripped));

      // Jeśli sponsor tytularny zerwał umowę, lista sponsorów zmniejsza się
      if (scandalReport.titleSponsorTerminated) {
        expect(updatedTeam.sponsors.length, equals(testTeam.sponsors.length - 1));
        expect(
          updatedTeam.sponsors.any((s) => s.sponsorTier == SponsorTier.titlePrimary),
          isFalse,
        );
      } else {
        // Satysfakcja spadła
        expect(
          updatedTeam.sponsors.first.sponsorSatisfaction,
          lessThan(testTeam.sponsors.first.sponsorSatisfaction),
        );
      }
    });
  });

  group('AntiDopingAndWhereaboutsService - 6. Serializacja JSON', () {
    test('Wszystkie modele antydopingowe serializują się bezstratnie', () {
      final sample = BiologicalPassportSample(
        id: 's_01',
        riderId: 'r_01',
        sampleDate: DateTime(2026, 5, 10),
        testType: AntiDopingTestType.inCompetition,
        hemoglobinGDL: 15.4,
        hematocritPercent: 45.2,
        reticulocytesPercent: 0.95,
        offScore: 95.5,
        testosteroneEpitestosteroneRatio: 1.3,
        isHydrationAbnormal: false,
        isAtypicalAnomaly: false,
      );
      final jsonSample = sample.toJson();
      final restoredSample = BiologicalPassportSample.fromJson(jsonSample);
      expect(restoredSample.id, equals(sample.id));
      expect(restoredSample.hemoglobinGDL, equals(15.4));
      expect(restoredSample.offScore, equals(95.5));

      final passport = AthleteBiologicalPassport(
        riderId: 'r_01',
        samples: [sample],
        status: BiologicalPassportStatus.atypicalVariance,
        suspicionScore: 35,
        expertNotes: const ['Monitorowanie'],
      );
      final jsonPassport = passport.toJson();
      final restoredPassport = AthleteBiologicalPassport.fromJson(jsonPassport);
      expect(restoredPassport.riderId, equals('r_01'));
      expect(restoredPassport.samples.length, equals(1));
      expect(restoredPassport.status, equals(BiologicalPassportStatus.atypicalVariance));

      final strike = WhereaboutsStrike(
        id: 'str_1',
        riderId: 'r_01',
        type: WhereaboutsFailureType.missedTest,
        incidentDate: DateTime(2026, 6, 1),
        explanation: 'Brak w oknie 60 min',
      );
      final restoredStrike = WhereaboutsStrike.fromJson(strike.toJson());
      expect(restoredStrike.type, equals(WhereaboutsFailureType.missedTest));

      final tue = TueApplication(
        id: 'tue_01',
        riderId: 'r_01',
        riderName: 'Jan Kowalski',
        injuryType: InjuryType.kneeTendinitis,
        substance: TherapeuticSubstance.triamcinolone,
        applicationDate: DateTime(2026, 6, 2),
        status: TueApplicationStatus.approved,
        doctorName: 'Dr House',
        validUntil: DateTime(2026, 6, 20),
      );
      final restoredTue = TueApplication.fromJson(tue.toJson());
      expect(restoredTue.substance, equals(TherapeuticSubstance.triamcinolone));
      expect(restoredTue.status, equals(TueApplicationStatus.approved));

      final sanction = AntiDopingSanction(
        id: 'sanc_01',
        riderId: 'r_01',
        riderName: 'Jan Kowalski',
        reason: 'AAF Triamcinolone',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2027, 7, 1),
        suspensionMonths: 12,
        uciPointsStripped: 450,
      );
      final restoredSanction = AntiDopingSanction.fromJson(sanction.toJson());
      expect(restoredSanction.suspensionMonths, equals(12));
      expect(restoredSanction.uciPointsStripped, equals(450));
    });
  });
}
