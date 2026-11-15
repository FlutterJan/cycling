// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/models/team/sponsor_contract.dart';
import 'package:pro_peloton_manager/services/career/press_conference_service.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';

void main() {
  late Rider testLeader;
  late Rider rivalLeader;
  late TourRace tourDeFrance;
  late RaceStage alpineStage;
  late CyclingTeam testTeam;

  setUp(() {
    testLeader = RiderProceduralGenerator.generateRider(
      id: 'leader_jonas',
      specialization: RiderSpecialization.gcClimber,
      targetOverallRating: 89,
    );

    rivalLeader = RiderProceduralGenerator.generateRider(
      id: 'rival_tadej',
      specialization: RiderSpecialization.gcClimber,
      targetOverallRating: 90,
    );

    tourDeFrance = const TourRace(
      id: 'tdf_2026',
      name: 'Tour de France 2026',
      countryIso: 'FR',
      uciCategory: RaceCategory.grandTour,
      startMonth: 7,
      startDay: 4,
      stages: [],
      prizePoolEur: 2500000,
      participatingTeamIds: ['team_01'],
      ridersPerTeam: 8,
      classifications: RaceClassifications(
        generalClassification: [],
        pointsClassification: [],
        mountainsClassification: [],
        youthClassification: [],
        teamClassification: [],
      ),
    );

    alpineStage = const RaceStage(
      id: 'st_15',
      stageNumber: 15,
      name: 'Briançon - Alpe d\'Huez',
      stageType: StageType.summitFinish,
      segments: [],
      baseTemperatureCelsius: 22.0,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 10.0,
    );

    const titleSponsor = SponsorContract(
      id: 'sp_title',
      companyName: 'Jumbo-Lease Mega Group',
      industry: SponsorIndustry.supermarkets,
      sponsorTier: SponsorTier.titlePrimary,
      annualBudgetEur: 15000000,
      contractDurationYears: 3,
      sponsorSatisfaction: 80.0,
      objectives: [],
    );

    testTeam = CyclingTeam(
      id: 'team_01',
      name: 'Veloce Pro Cycling',
      division: TeamDivision.worldTour,
      countryIso: 'NL',
      primaryJerseyColorHex: '#FFFF00',
      secondaryJerseyColorHex: '#000000',
      accentJerseyColorHex: '#FF0000',
      cashBalanceEur: 4000000,
      monthlyBurnRateEur: 450000,
      uciPointsSeason: 3200,
      rosterRiderIds: [testLeader.id],
      staff: const TeamStaff(
        trainersLevel: 85,
        sportsDirectorsLevel: 90,
        doctorsLevel: 85,
        mechanicsLevel: 85,
        scoutsLevel: 80,
      ),
      bikeDeal: const BikeManufacturerDeal(
        manufacturerId: 'cervelo',
        manufacturerName: 'Cervélo',
        prestigeLevel: 5,
        annualCashContributionEur: 2000000,
        freeBikesQuota: 85,
        researchAndDevelopmentLevel: 92,
        suppliedFrameIds: ['r5'],
        suppliedWheelsetIds: ['reserve'],
        contractYearsLeft: 2,
        minimumUciRankingRequired: 5,
      ),
      sponsors: const [titleSponsor],
      inventoryBikes: const [],
    );
  });

  group('PressConferenceService - 1. Generowanie Konferencji Prasowych w Różnych Kontekstach', () {
    test('preGrandTourOpening generuje pytania z 4 opcjami odpowiedzi', () {
      final session = PressConferenceService.generatePressConference(
        context: PressConferenceContext.preGrandTourOpening,
        race: tourDeFrance,
        focalRider: testLeader,
        rivalLeader: rivalLeader,
      );

      expect(session.context, equals(PressConferenceContext.preGrandTourOpening));
      expect(session.questions.length, equals(2));
      expect(session.targetRiderName, equals(testLeader.fullName));

      for (final q in session.questions) {
        expect(q.options.length, equals(4));
        final tones = q.options.map((o) => o.tone).toSet();
        expect(tones, contains(PressAnswerTone.tacticalBluff));
        expect(tones, contains(PressAnswerTone.aggressiveConfidence));
        expect(tones, contains(PressAnswerTone.diplomaticShield));
        expect(tones, contains(PressAnswerTone.pressureDeflection));
      }
    });

    test('postStageVictory generuje pytania po triumfie etapowym', () {
      final session = PressConferenceService.generatePressConference(
        context: PressConferenceContext.postStageVictory,
        race: tourDeFrance,
        currentStage: alpineStage,
        focalRider: testLeader,
        rivalLeader: rivalLeader,
        riderWonStage: true,
      );

      expect(session.stageNumber, equals(15));
      expect(session.questions.length, equals(2));
      expect(session.questions.first.questionText, contains('Niesamowity pokaz mocy'));
    });

    test('postStageDefeatOrTimeLoss generuje pytania kryzysowe po stracie czasu', () {
      final session = PressConferenceService.generatePressConference(
        context: PressConferenceContext.postStageDefeatOrTimeLoss,
        race: tourDeFrance,
        currentStage: alpineStage,
        focalRider: testLeader,
        riderLostTime: true,
      );

      expect(session.questions.first.questionText, contains('To był czarny dzień'));
      expect(session.questions.last.questionText, contains('szarżę na wszystko albo nic'));
    });

    test('postCrashAndInjuryCrisis generuje briefing medyczny po kraksie', () {
      final session = PressConferenceService.generatePressConference(
        context: PressConferenceContext.postCrashAndInjuryCrisis,
        race: tourDeFrance,
        focalRider: testLeader,
        riderCrashed: true,
      );

      expect(session.questions.first.topic, equals(QuestionTopic.crashDamageAndPainManagement));
      expect(session.questions.first.questionText, contains('Głębokie szlify, stłuczone biodro'));
    });

    test('preQueenStageMountainPreview generuje pytania o Galibier i blef wysokościowy', () {
      final session = PressConferenceService.generatePressConference(
        context: PressConferenceContext.preQueenStageMountainPreview,
        race: tourDeFrance,
        currentStage: alpineStage,
        focalRider: testLeader,
        rivalLeader: rivalLeader,
      );

      expect(session.questions.first.questionText, contains('Jutro dzień prawdy'));
      expect(session.questions.last.questionText, contains('powyżej 2000 metrów'));
    });

    test('transferRumorsAndSillySeason i intraTeamFeudScandal generują dedykowane tematy', () {
      final sessionTransfer = PressConferenceService.generatePressConference(
        context: PressConferenceContext.transferRumorsAndSillySeason,
        race: tourDeFrance,
        focalRider: testLeader,
      );
      expect(sessionTransfer.questions.first.topic, equals(QuestionTopic.transferRumorsAndContract));

      final sessionFeud = PressConferenceService.generatePressConference(
        context: PressConferenceContext.intraTeamFeudScandal,
        race: tourDeFrance,
        focalRider: testLeader,
        isDualLeaderClash: true,
      );
      expect(sessionFeud.questions.first.topic, equals(QuestionTopic.dualLeaderDynamicAndHierarchy));
    });
  });

  group('PressConferenceService - 2. Wpływ 4 Tonów Odpowiedzi na Presję, Sponsorów i Rywali', () {
    test('Blef taktyczny obniża czujność rywali AI i daje bonus do ataku z daleka', () {
      final session = PressConferenceService.generatePressConference(
        context: PressConferenceContext.preQueenStageMountainPreview,
        race: tourDeFrance,
        focalRider: testLeader,
        rivalLeader: rivalLeader,
      );

      final queenQuestion = session.questions.first;
      final bluffOption = queenQuestion.options.firstWhere(
        (o) => o.tone == PressAnswerTone.tacticalBluff,
      );

      expect(bluffOption.rivalAlertnessMultiplier, lessThan(0.80)); // Rywale uśpieni!
      expect(bluffOption.tacticalSurpriseBonusPercent, greaterThan(0.20)); // +25% bonusu
      expect(bluffOption.riderPressureDelta, lessThan(0)); // Zdejmuje presję
    });

    test('Agresywna pewność siebie podnosi satysfakcję sponsorów, lecz alarmuje rywali i nakłada presję', () {
      final session = PressConferenceService.generatePressConference(
        context: PressConferenceContext.preQueenStageMountainPreview,
        race: tourDeFrance,
        focalRider: testLeader,
        rivalLeader: rivalLeader,
      );

      final queenQuestion = session.questions.first;
      final aggressiveOption = queenQuestion.options.firstWhere(
        (o) => o.tone == PressAnswerTone.aggressiveConfidence,
      );

      expect(aggressiveOption.sponsorSatisfactionDelta, greaterThan(5.0)); // Sponsorzy zachwyceni
      expect(aggressiveOption.rivalAlertnessMultiplier, greaterThan(1.30)); // Rywale w alercie
      expect(aggressiveOption.riderPressureDelta, greaterThan(10)); // Wysoka presja
    });

    test('Spokojna dyplomacja zapewnia bezpieczną stabilizację', () {
      final session = PressConferenceService.generatePressConference(
        context: PressConferenceContext.preGrandTourOpening,
        race: tourDeFrance,
        focalRider: testLeader,
      );

      final diplomaticOption = session.questions.first.options.firstWhere(
        (o) => o.tone == PressAnswerTone.diplomaticShield,
      );

      expect(diplomaticOption.riderPressureDelta, lessThanOrEqualTo(0));
      expect(diplomaticOption.sponsorSatisfactionDelta, greaterThanOrEqualTo(0));
      expect(diplomaticOption.rivalAlertnessMultiplier, closeTo(1.0, 0.05));
    });
  });

  group('PressConferenceService - 3. Rozstrzyganie Konferencji i Aplikacja Konsekwencji na Zespół', () {
    test('processCompletedConference wylicza skumulowany raport z dominacją blefu', () {
      final session = PressConferenceService.generatePressConference(
        context: PressConferenceContext.preQueenStageMountainPreview,
        race: tourDeFrance,
        focalRider: testLeader,
        rivalLeader: rivalLeader,
      );

      // Gracz wybiera blefy na oba pytania
      final chosenMap = <String, String>{};
      for (final q in session.questions) {
        final bluffOpt = q.options.firstWhere((o) => o.tone == PressAnswerTone.tacticalBluff);
        chosenMap[q.id] = bluffOpt.id;
      }

      final result = PressConferenceService.processCompletedConference(
        session: session,
        chosenOptionIdsByQuestionId: chosenMap,
        team: testTeam,
      );

      expect(result.totalRiderPressureDelta, lessThan(-20)); // Presja mocno spadła
      expect(result.rivalAlertnessFactor, lessThan(0.75)); // Rywale AI głęboko uśpieni!
      expect(result.tacticalSurpriseBonusPercent, greaterThan(0.30));
      expect(result.mediaSummaryReport, contains('Rywale uśpieni blefem!'));
      expect(result.frontPageHeadlines.length, equals(2));

      // Modyfikator ataku z daleka w silniku etapu rośnie
      final longRangeFactor =
          PressConferenceService.calculateLongRangeAttackSuccessFactor(result.rivalAlertnessFactor);
      expect(longRangeFactor, greaterThan(1.30)); // Ponad +30% szans powodzenia ucieczki!
    });

    test('applyConferenceImpactToTeam aktualizuje satysfakcję sponsorów w zespole', () {
      final session = PressConferenceService.generatePressConference(
        context: PressConferenceContext.postStageVictory,
        race: tourDeFrance,
        currentStage: alpineStage,
        focalRider: testLeader,
        riderWonStage: true,
      );

      // Wybieramy agresywne odpowiedzi, które zachwycają sponsorów
      final chosenMap = <String, String>{};
      for (final q in session.questions) {
        final aggroOpt = q.options.firstWhere((o) => o.tone == PressAnswerTone.aggressiveConfidence);
        chosenMap[q.id] = aggroOpt.id;
      }

      final result = PressConferenceService.processCompletedConference(
        session: session,
        chosenOptionIdsByQuestionId: chosenMap,
        team: testTeam,
      );

      expect(result.totalSponsorSatisfactionDelta, greaterThan(10.0));

      final updatedTeam = PressConferenceService.applyConferenceImpactToTeam(
        team: testTeam,
        result: result,
      );

      expect(
        updatedTeam.sponsors.first.sponsorSatisfaction,
        equals(testTeam.sponsors.first.sponsorSatisfaction + result.totalSponsorSatisfactionDelta),
      );
    });
  });

  group('PressConferenceService - 4. Serializacja JSON', () {
    test('MediaOutlet, Question, Answer i Session serializują się bezstratnie', () {
      const outlet = MediaOutlet(
        id: 'out_01',
        name: 'Velo Mag',
        countryIso: 'PL',
        journalistName: 'Tomasz Jaroński',
        editorialTone: 'Komentarz z pasją i humorem',
      );
      final jsonOutlet = outlet.toJson();
      final restoredOutlet = MediaOutlet.fromJson(jsonOutlet);
      expect(restoredOutlet.name, equals('Velo Mag'));
      expect(restoredOutlet.journalistName, equals('Tomasz Jaroński'));

      const option = PressConferenceAnswerOption(
        id: 'opt_test',
        tone: PressAnswerTone.tacticalBluff,
        answerText: 'Blefujemy!',
        riderPressureDelta: -10,
        sponsorSatisfactionDelta: -2.0,
        rivalAlertnessMultiplier: 0.70,
        managerReputationDelta: 1,
        teamMoraleDelta: 2.0,
        tacticalSurpriseBonusPercent: 0.15,
        expectedMediaReaction: 'Kupili blef',
      );
      final jsonOption = option.toJson();
      final restoredOption = PressConferenceAnswerOption.fromJson(jsonOption);
      expect(restoredOption.tone, equals(PressAnswerTone.tacticalBluff));
      expect(restoredOption.rivalAlertnessMultiplier, equals(0.70));

      const question = PressConferenceQuestion(
        id: 'q_test',
        outlet: outlet,
        topic: QuestionTopic.mountainTacticsAndPacing,
        questionText: 'Czy zaatakujecie?',
        contextDescription: 'Górski etap',
        options: [option],
      );
      final jsonQuestion = question.toJson();
      final restoredQuestion = PressConferenceQuestion.fromJson(jsonQuestion);
      expect(restoredQuestion.questionText, equals('Czy zaatakujecie?'));
      expect(restoredQuestion.options.length, equals(1));

      final session = PressConferenceSession(
        id: 'sess_01',
        context: PressConferenceContext.preGrandTourOpening,
        raceName: 'Giro d\'Italia',
        stageNumber: 1,
        targetRiderName: 'Jonas Vingegaard',
        questions: [question],
        conferenceDate: DateTime(2026, 5, 8, 14, 0),
      );
      final jsonSession = session.toJson();
      final restoredSession = PressConferenceSession.fromJson(jsonSession);
      expect(restoredSession.raceName, equals('Giro d\'Italia'));
      expect(restoredSession.context, equals(PressConferenceContext.preGrandTourOpening));
      expect(restoredSession.questions.length, equals(1));
    });
  });
}
