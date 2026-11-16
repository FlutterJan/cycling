import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/models/team/sponsor_contract.dart';
import 'package:pro_peloton_manager/services/career/pre_season_team_presentation_event.dart';

void main() {
  const deal = BikeManufacturerDeal(
    manufacturerId: 'aero_works',
    manufacturerName: 'AeroWorks Carbon',
    prestigeLevel: 5,
    annualCashContributionEur: 1200000,
    freeBikesQuota: 90,
    researchAndDevelopmentLevel: 92,
    suppliedFrameIds: ['aw_sl8'],
    suppliedWheelsetIds: ['aw_60'],
    contractYearsLeft: 2,
    minimumUciRankingRequired: 10,
  );

  const staff = TeamStaff(
    trainersLevel: 85,
    sportsDirectorsLevel: 88,
    doctorsLevel: 82,
    mechanicsLevel: 86,
    scoutsLevel: 80,
  );

  const sponsor = SponsorContract(
    id: 'sp_orlen',
    companyName: 'Apex Energy',
    industry: SponsorIndustry.energy,
    sponsorTier: SponsorTier.titlePrimary,
    annualBudgetEur: 8500000,
    contractDurationYears: 3,
    sponsorSatisfaction: 58.0,
    objectives: [],
  );

  const team = CyclingTeam(
    id: 'team_wt_1',
    name: 'Veloce Pro Cycling',
    division: TeamDivision.worldTour,
    countryIso: 'PL',
    primaryJerseyColorHex: '#8E4A49',
    secondaryJerseyColorHex: '#181B22',
    accentJerseyColorHex: '#D4AF37',
    cashBalanceEur: 3500000,
    monthlyBurnRateEur: 450000,
    uciPointsSeason: 0,
    rosterRiderIds: ['r1', 'r2', 'r3', 'r4'],
    staff: staff,
    bikeDeal: deal,
    sponsors: [sponsor],
    inventoryBikes: [],
  );

  Rider buildRider({
    required String id,
    required String firstName,
    required String lastName,
    required int birthYear,
    required RiderRole role,
    required int watts20m,
  }) {
    return Rider(
      id: id,
      firstName: firstName,
      lastName: lastName,
      nationalityIso: 'PL',
      birthDate: DateTime(birthYear, 4, 12),
      potential: 88,
      specialization: RiderSpecialization.gcClimber,
      physiology: const RiderPhysiology(
        heightCm: 178.0,
        weightKg: 64.0,
        bodyFatPercentage: 6.2,
        ftpWatts: 410,
        wPrimeJoules: 22000,
        vo2Max: 84.0,
        maxHr: 192,
        restingHr: 38,
        lactateThresholdHr: 174,
        recoveryRate: 85.0,
        glycogenCapacityGrams: 520.0,
      ),
      powerProfile: RiderPowerProfile(
        watts5s: 1150,
        watts15s: 960,
        watts30s: 810,
        watts1m: 640,
        watts3m: 540,
        watts5m: 495,
        watts20m: watts20m,
        watts60m: 385,
      ),
      skills: const RiderSkills(
        cobbles: 70,
        descending: 82,
        bikeHandling: 84,
        aeroPositioning: 82,
        draftingEfficiency: 80,
        raceIq: 85,
        rainResistance: 78,
        heatTolerance: 75,
        timeTrialPositioning: 80,
      ),
      appearance: const RiderAppearance(
        faceShapeIndex: 1,
        skinToneHex: '#F1C27D',
        hairStyleIndex: 2,
        hairColorHex: '#3B2F2F',
        facialHairIndex: 0,
        glassesModelId: 'aero_1',
        glassesLensColorHex: '#38BDF8',
        helmetModelId: 'helmet_pro',
        shoeColorHex: '#FFFFFF',
        sockHeightProportion: 0.75,
        bodyBuildType: BodyBuildType.climberLean,
      ),
      contract: RiderContract(
        teamId: 'team_wt_1',
        role: role,
        monthlySalaryEur: 45000,
        signingBonusEur: 50000,
        winBonusEur: 15000,
        releaseClauseEur: 1500000,
        contractEndYear: 2028,
        morale: 75,
        leaderLoyalty: 85,
        requiredRacesIds: const [],
      ),
      health: const RiderHealth(
        acuteTrainingLoad: 40.0,
        chronicTrainingLoad: 78.0,
      ),
      careerPointsUci: 1200,
    );
  }

  final signings = [
    buildRider(
      id: 'r1',
      firstName: 'Kamil',
      lastName: 'Majewski',
      birthYear: 1998,
      role: RiderRole.teamLeader,
      watts20m: 415,
    ),
    buildRider(
      id: 'r2',
      firstName: 'Lukas',
      lastName: 'Bauer',
      birthYear: 2005,
      role: RiderRole.neoPro,
      watts20m: 365,
    ),
    buildRider(
      id: 'r3',
      firstName: 'Matteo',
      lastName: 'Conti',
      birthYear: 1996,
      role: RiderRole.superDomestique,
      watts20m: 385,
    ),
    buildRider(
      id: 'r4',
      firstName: 'Jan',
      lastName: 'Nowak',
      birthYear: 1999,
      role: RiderRole.domestique,
      watts20m: 350,
    ),
  ];

  group('PreSeasonTeamPresentationEvent unit tests', () {
    test('detects January presentation window accurately', () {
      expect(
        PreSeasonTeamPresentationEvent.isJanuaryPresentationWindow(
          DateTime(2026, 1, 10),
        ),
        isTrue,
      );
      expect(
        PreSeasonTeamPresentationEvent.isJanuaryPresentationWindow(
          DateTime(2026, 2, 1),
        ),
        isFalse,
      );
      expect(
        PreSeasonTeamPresentationEvent.isJanuaryPresentationWindow(
          DateTime(2026, 12, 28),
        ),
        isFalse,
      );
    });

    test('builds 4 kit variants and sorts signings by overall rating', () {
      final kits = PreSeasonTeamPresentationEvent.buildDefaultKitVariants(team);
      expect(kits, hasLength(4));
      expect(kits.first.primaryHex, '#8E4A49');

      final spotlights = PreSeasonTeamPresentationEvent.buildSigningsFromRoster(
        signings,
        seasonYear: 2026,
        previousTeams: const {'r1': 'Team Alpina'},
      );
      expect(spotlights, hasLength(4));
      expect(spotlights.first.riderId, 'r1');
      expect(spotlights.first.previousTeamName, 'Team Alpina');
      expect(spotlights.first.signingType, SigningSpotlightType.marqueeSigning);
      expect(
        spotlights.any((s) => s.signingType == SigningSpotlightType.u23Promotion),
        isTrue,
      );
    });

    test('press tone, ambition and kit choice impact sponsor and media indices', () {
      final kits = PreSeasonTeamPresentationEvent.buildDefaultKitVariants(team);
      final spotlights = PreSeasonTeamPresentationEvent.buildSigningsFromRoster(
        signings,
      );

      final boldPreview = PreSeasonTeamPresentationEvent.evaluateLivePreview(
        team: team,
        mainObjective: SeasonMainObjectiveCategory.uciWorldTourPointsSurvival,
        secondaryObjective: null,
        ambitionLevel: SeasonObjectiveAmbitionLevel.conservative,
        newSignings: spotlights,
        featuredSigningIds: const {},
        selectedKit: kits[3], // Stealth Carbon Lab
        pressTone: PressQaTone.boldPromise,
      );

      final sponsorPreview = PreSeasonTeamPresentationEvent.evaluateLivePreview(
        team: team,
        mainObjective: SeasonMainObjectiveCategory.uciWorldTourPointsSurvival,
        secondaryObjective: null,
        ambitionLevel: SeasonObjectiveAmbitionLevel.conservative,
        newSignings: spotlights,
        featuredSigningIds: const {},
        selectedKit: kits[3],
        pressTone: PressQaTone.sponsorCentric,
      );

      expect(
        boldPreview.initialMediaInterestIndex,
        greaterThan(sponsorPreview.initialMediaInterestIndex),
      );
      expect(
        sponsorPreview.initialSponsorSatisfactionIndex,
        greaterThan(boldPreview.initialSponsorSatisfactionIndex),
      );
      expect(boldPreview.projectedMediaValueEur, greaterThan(0));
    });

    test('completePresentation and applyOutcomeToTeam update team and serialize JSON', () {
      final kits = PreSeasonTeamPresentationEvent.buildDefaultKitVariants(team);
      final spotlights = PreSeasonTeamPresentationEvent.buildSigningsFromRoster(
        signings,
      );

      final outcome = PreSeasonTeamPresentationEvent.completePresentation(
        seasonYear: 2026,
        team: team,
        mainObjective: SeasonMainObjectiveCategory.grandTourGcPodium,
        secondaryObjective: SeasonMainObjectiveCategory.springMonumentsVictory,
        ambitionLevel: SeasonObjectiveAmbitionLevel.ambitious,
        newSignings: spotlights,
        featuredSigningIds: {'r1', 'r2'},
        selectedKit: kits[2],
        pressTone: PressQaTone.sponsorCentric,
      );

      expect(outcome.presentedSignings, hasLength(2));
      expect(outcome.mediaQuotes, isNotEmpty);
      expect(outcome.initialSponsorSatisfactionIndex, greaterThan(58.0));

      final updatedTeam = PreSeasonTeamPresentationEvent.applyOutcomeToTeam(
        team,
        outcome,
      );
      expect(updatedTeam.primaryJerseyColorHex, kits[2].primaryHex);
      expect(
        updatedTeam.sponsors.first.sponsorSatisfaction,
        greaterThan(team.sponsors.first.sponsorSatisfaction),
      );

      final roundTrip = PreSeasonTeamPresentationOutcome.fromJson(
        outcome.toJson(),
      );
      expect(roundTrip.seasonYear, outcome.seasonYear);
      expect(roundTrip.selectedKit.id, outcome.selectedKit.id);
      expect(
        roundTrip.initialSponsorSatisfactionIndex,
        outcome.initialSponsorSatisfactionIndex,
      );
    });

    test('notifier enforces max 3 featured signings and completes cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(preSeasonTeamPresentationProvider.notifier);
      notifier.initializeForTeam(
        seasonYear: 2026,
        team: team,
        newSignings: signings,
      );

      var state = container.read(preSeasonTeamPresentationProvider);
      expect(state.status, PreSeasonPresentationStatus.inProgress);
      expect(state.featuredSigningIds, hasLength(3));

      // Attempt to add 4th featured signing
      notifier.toggleFeaturedSigning('r4');
      state = container.read(preSeasonTeamPresentationProvider);
      expect(state.validationError, isNotNull);
      expect(state.featuredSigningIds, hasLength(3));

      // JSON round-trip of state
      final stateRoundTrip = PreSeasonTeamPresentationState.fromJson(
        state.toJson(),
      );
      expect(stateRoundTrip.seasonYear, 2026);
      expect(stateRoundTrip.kitVariants, hasLength(4));

      final outcome = notifier.confirmPresentation();
      expect(outcome, isNotNull);
      state = container.read(preSeasonTeamPresentationProvider);
      expect(state.status, PreSeasonPresentationStatus.completed);
      expect(state.outcome, isNotNull);
    });
  });

  group('PreSeasonTeamPresentationPanel responsive widget tests', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      void Function(PreSeasonTeamPresentationOutcome)? onCompleted,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(preSeasonTeamPresentationProvider.notifier).initializeForTeam(
            seasonYear: 2026,
            team: team,
            newSignings: signings,
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: PreSeasonTeamPresentationPanel(
                onCompleted: onCompleted,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders without overflow at 390x844 mobile', (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.textContaining('GALA STYCZNIOWA'), findsOneWidget);
      expect(find.text('ZATWIERDŹ PREZENTACJĘ SEZONU'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at 1024x768 tablet', (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('Indeksy Otwarcia Sezonu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders and confirms presentation at 1600x900 desktop', (
      tester,
    ) async {
      PreSeasonTeamPresentationOutcome? capturedOutcome;
      await pumpPanelAtSize(
        tester,
        const Size(1600, 900),
        onCompleted: (o) => capturedOutcome = o,
      );

      final confirmButton = find.text('ZATWIERDŹ PREZENTACJĘ SEZONU');
      await tester.ensureVisible(confirmButton);
      await tester.tap(confirmButton);
      await tester.pump(const Duration(milliseconds: 300));

      expect(capturedOutcome, isNotNull);
      expect(find.text('RAPORT KOŃCOWY MEDIÓW'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
