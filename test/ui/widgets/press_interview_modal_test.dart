// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/models/team/sponsor_contract.dart';
import 'package:pro_peloton_manager/services/career/press_conference_service.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';
import 'package:pro_peloton_manager/ui/widgets/press_interview_modal.dart';

void main() {
  late Rider testLeader;
  late TourRace tourDeFrance;
  late RaceStage alpineStage;
  late CyclingTeam testTeam;
  late PressConferenceSession testSession;

  setUp(() {
    testLeader = RiderProceduralGenerator.generateRider(
      id: 'leader_jonas',
      specialization: RiderSpecialization.gcClimber,
      targetOverallRating: 89,
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
        doctorsLevel: 80,
        mechanicsLevel: 88,
        scoutsLevel: 75,
      ),
      bikeDeal: const BikeManufacturerDeal(
        manufacturerId: 'cervelo',
        manufacturerName: 'Cervélo Bicycles',
        prestigeLevel: 5,
        annualCashContributionEur: 2500000,
        freeBikesQuota: 80,
        researchAndDevelopmentLevel: 92,
        suppliedFrameIds: [],
        suppliedWheelsetIds: [],
        contractYearsLeft: 2,
        minimumUciRankingRequired: 5,
      ),
      sponsors: const [titleSponsor],
      inventoryBikes: [],
    );

    testSession = PressConferenceService.generatePressConference(
      context: PressConferenceContext.preGrandTourOpening,
      race: tourDeFrance,
      currentStage: alpineStage,
      focalRider: testLeader,
    );
  });

  Widget createTestWidget({
    required PressConferenceSession session,
    void Function(PressConferenceResult)? onCompleted,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: PressInterviewModal(
            session: session,
            team: testTeam,
            focalRider: testLeader,
            onCompleted: onCompleted,
          ),
        ),
      ),
    );
  }

  testWidgets('renders press conference header, microphones and initial question',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget(session: testSession));
    await tester.pumpAndSettle();

    // Verify Race name and stage
    expect(find.textContaining('TOUR DE FRANCE 2026'), findsWidgets);
    expect(find.textContaining('ETAP 15'), findsOneWidget);

    // Verify Context title
    expect(find.text(testSession.context.displayName), findsOneWidget);

    // Verify Sponsor Backdrop tiles
    expect(find.textContaining('JUMBO-LEASE MEGA GROUP'), findsWidgets);
    expect(find.textContaining('CERVÉLO BICYCLES'), findsOneWidget);
    expect(find.textContaining('UCI WORLDTOUR'), findsOneWidget);

    // Verify Microphones
    expect(find.text('EUROSPORT'), findsOneWidget);
    expect(find.text('FRANCE TV'), findsOneWidget);
    expect(find.text('RAI SPORT'), findsOneWidget);
    expect(find.text('SPORZA'), findsOneWidget);
    expect(find.text('CYCLINGNEWS'), findsOneWidget);
    expect(find.text("L'ÉQUIPE"), findsWidgets);

    // Verify First Question text and journalist name
    final firstQuestion = testSession.questions.first;
    expect(find.text(firstQuestion.questionText), findsOneWidget);
    expect(find.text(firstQuestion.outlet.journalistName), findsOneWidget);

    // Verify 4 Answer option cards exist
    expect(firstQuestion.options.length, 4);
    for (final opt in firstQuestion.options) {
      expect(find.text(opt.answerText), findsOneWidget);
    }
  });

  testWidgets('selecting an answer reveals Live Reaction Preview panel',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget(session: testSession));
    await tester.pumpAndSettle();

    // Before selection, live reaction is not present
    expect(find.text('ECHO MEDIALNE I REAKCJE NA ŻYWO'), findsNothing);

    // Select the first answer option (e.g. Tactical Bluff)
    final firstOption = testSession.questions.first.options.first;
    final optionFinder = find.text(firstOption.answerText);
    await tester.ensureVisible(optionFinder);
    await tester.tap(optionFinder);
    await tester.pumpAndSettle();

    // Live Reaction Preview should now be visible
    expect(find.text('ECHO MEDIALNE I REAKCJE NA ŻYWO'), findsOneWidget);
    expect(find.text('LIDER & SZATNIA'), findsOneWidget);
    expect(find.text('@PelotonWire • Teraz'), findsOneWidget);
    expect(find.text('SPONSOR TYTULARNY'), findsOneWidget);
    expect(find.text('RADAR CZUJNOŚCI RYWALI AI'), findsOneWidget);

    // Verify Twitter card contains expected headline
    expect(find.text('„${firstOption.expectedMediaReaction}”'), findsOneWidget);
  });

  testWidgets('progresses through multiple questions to final summary view',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    PressConferenceResult? callbackResult;
    await tester.pumpWidget(createTestWidget(
      session: testSession,
      onCompleted: (res) => callbackResult = res,
    ));
    await tester.pumpAndSettle();

    // Answer Question 1
    final q1Option = testSession.questions[0].options[0];
    final q1Finder = find.text(q1Option.answerText);
    await tester.ensureVisible(q1Finder);
    await tester.tap(q1Finder);
    await tester.pumpAndSettle();

    // Click Next Question
    final nextBtnFinder = find.widgetWithText(ElevatedButton, 'Następne pytanie (2 z 2)');
    expect(nextBtnFinder, findsOneWidget);
    await tester.tap(nextBtnFinder);
    await tester.pumpAndSettle();

    // Verify Question 2 is now shown
    final q2 = testSession.questions[1];
    expect(find.text(q2.questionText), findsOneWidget);

    // Answer Question 2
    final q2Option = testSession.questions[1].options[1];
    final q2Finder = find.text(q2Option.answerText);
    await tester.ensureVisible(q2Finder);
    await tester.tap(q2Finder);
    await tester.pumpAndSettle();

    // Click Finish Conference
    final finishBtnFinder = find.widgetWithText(ElevatedButton, 'Zakończ konferencję prasową');
    expect(finishBtnFinder, findsOneWidget);
    await tester.tap(finishBtnFinder);
    await tester.pumpAndSettle();

    // Summary view should now be displayed
    expect(find.text('KONFERENCJA PRASOWA ZAKOŃCZONA'), findsOneWidget);
    expect(find.text('SKUMULOWANY BILANS WYSTĄPIENIA'), findsOneWidget);
    expect(find.text('JUTRZEJSZE JEDYNKI W NAJWIĘKSZYCH DZIENNIKACH:'), findsOneWidget);

    // Click "Zatwierdź i wróć do gry"
    final confirmBtnFinder = find.widgetWithText(ElevatedButton, 'Zatwierdź i wróć do gry');
    expect(confirmBtnFinder, findsOneWidget);
    await tester.tap(confirmBtnFinder);
    await tester.pumpAndSettle();

    // Verify callback was called with valid result
    expect(callbackResult, isNotNull);
    expect(callbackResult!.session.id, testSession.id);
    expect(callbackResult!.chosenAnswers.length, 2);
  });

  testWidgets('PressInterviewModal.show helper opens dialog and returns result',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    PressConferenceResult? returnedResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  returnedResult = await PressInterviewModal.show(
                    context: context,
                    session: testSession,
                    team: testTeam,
                    focalRider: testLeader,
                  );
                },
                child: const Text('Otwórz Konferencję'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open Modal
    await tester.tap(find.text('Otwórz Konferencję'));
    await tester.pumpAndSettle();

    expect(find.byType(PressInterviewModal), findsOneWidget);

    // Answer all questions
    for (int i = 0; i < testSession.questions.length; i++) {
      final opt = testSession.questions[i].options[0];
      final optFinder = find.text(opt.answerText);
      await tester.ensureVisible(optFinder);
      await tester.tap(optFinder);
      await tester.pumpAndSettle();

      if (i < testSession.questions.length - 1) {
        await tester.tap(find.textContaining('Następne pytanie'));
        await tester.pumpAndSettle();
      } else {
        await tester.tap(find.text('Zakończ konferencję prasową'));
        await tester.pumpAndSettle();
      }
    }

    // Confirm in summary view
    await tester.tap(find.text('Zatwierdź i wróć do gry'));
    await tester.pumpAndSettle();

    // Modal dismissed and returned result
    expect(find.byType(PressInterviewModal), findsNothing);
    expect(returnedResult, isNotNull);
    expect(returnedResult!.session.id, testSession.id);
  });

  testWidgets('close button prompts exit confirmation when an answer is chosen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(createTestWidget(session: testSession));
    await tester.pumpAndSettle();

    // Select an answer
    final optFinder = find.text(testSession.questions[0].options[0].answerText);
    await tester.ensureVisible(optFinder);
    await tester.tap(optFinder);
    await tester.pumpAndSettle();

    // Tap Close icon in header
    final closeBtnFinder = find.byIcon(Icons.close);
    await tester.tap(closeBtnFinder);
    await tester.pumpAndSettle();

    // Verify confirmation dialog appears
    expect(find.text('Opuścić salę konferencyjną?'), findsOneWidget);
    expect(find.text('Zostań'), findsOneWidget);
    expect(find.text('Opuść konferencję'), findsOneWidget);

    // Tap "Zostań"
    await tester.tap(find.text('Zostań'));
    await tester.pumpAndSettle();

    // Dialog dismissed, modal still open
    expect(find.text('Opuścić salę konferencyjną?'), findsNothing);
    expect(find.byType(PressInterviewModal), findsOneWidget);
  });
}
