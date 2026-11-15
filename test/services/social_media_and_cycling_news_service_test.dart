import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/models/career/season_calendar.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/career/social_media_and_cycling_news_service.dart';
import 'package:pro_peloton_manager/ui/widgets/cycling_news_feed_widget.dart';

Rider _buildTestRider({
  required String id,
  required String firstName,
  required String lastName,
  required String teamId,
  RiderSpecialization spec = RiderSpecialization.gcClimber,
}) {
  return Rider(
    id: id,
    firstName: firstName,
    lastName: lastName,
    nationalityIso: 'PL',
    birthDate: DateTime(1998, 5, 14),
    potential: 90,
    specialization: spec,
    physiology: const RiderPhysiology(
      heightCm: 178,
      weightKg: 64,
      bodyFatPercentage: 6.5,
      ftpWatts: 410,
      wPrimeJoules: 24000,
      vo2Max: 83,
      maxHr: 194,
      restingHr: 39,
      lactateThresholdHr: 176,
      recoveryRate: 85,
      glycogenCapacityGrams: 550,
    ),
    powerProfile: const RiderPowerProfile(
      watts5s: 1180,
      watts15s: 990,
      watts30s: 820,
      watts1m: 670,
      watts3m: 540,
      watts5m: 495,
      watts20m: 430,
      watts60m: 400,
    ),
    skills: const RiderSkills(
      cobbles: 74,
      descending: 82,
      bikeHandling: 84,
      aeroPositioning: 80,
      draftingEfficiency: 81,
      raceIq: 86,
      rainResistance: 78,
      heatTolerance: 80,
      timeTrialPositioning: 82,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#F2C9A0',
      hairStyleIndex: 1,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
      glassesModelId: 'oakley_pro',
      glassesLensColorHex: '#00E5FF',
      helmetModelId: 'aero_pro',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.65,
      bodyBuildType: BodyBuildType.climberLean,
    ),
    contract: RiderContract(
      teamId: teamId,
      role: RiderRole.values.first,
      monthlySalaryEur: 70000,
      signingBonusEur: 50000,
      winBonusEur: 25000,
      releaseClauseEur: 2000000,
      contractEndYear: 2026,
      morale: 0.85,
      leaderLoyalty: 0.9,
      requiredRacesIds: const [],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 75,
      chronicTrainingLoad: 88,
    ),
    careerPointsUci: 1450,
  );
}

CyclingTeam _buildTestTeam(String id, String name, List<String> riderIds) {
  return CyclingTeam(
    id: id,
    name: name,
    countryIso: 'PL',
    division: TeamDivision.worldTour,
    primaryJerseyColorHex: '#8E4A49',
    secondaryJerseyColorHex: '#181B22',
    accentJerseyColorHex: '#D4AF37',
    cashBalanceEur: 12000000,
    monthlyBurnRateEur: 800000,
    uciPointsSeason: 3200,
    rosterRiderIds: riderIds,
    staff: const TeamStaff(
      trainersLevel: 80,
      sportsDirectorsLevel: 82,
      doctorsLevel: 79,
      mechanicsLevel: 81,
      scoutsLevel: 77,
    ),
    bikeDeal: const BikeManufacturerDeal(
      manufacturerId: 'veloce',
      manufacturerName: 'Veloce',
      prestigeLevel: 4,
      annualCashContributionEur: 900000,
      freeBikesQuota: 40,
      researchAndDevelopmentLevel: 80,
      suppliedFrameIds: ['f1'],
      suppliedWheelsetIds: ['w1'],
      contractYearsLeft: 2,
      minimumUciRankingRequired: 18,
    ),
    sponsors: const [],
    inventoryBikes: const [],
  );
}

CareerSave _buildTestSave() {
  final r1 = _buildTestRider(
    id: 'r1',
    firstName: 'Jan',
    lastName: 'Kowalski',
    teamId: 'team_player',
    spec: RiderSpecialization.gcClimber,
  );
  final r2 = _buildTestRider(
    id: 'r2',
    firstName: 'Piotr',
    lastName: 'Nowak',
    teamId: 'team_player',
    spec: RiderSpecialization.breakawaySpecialist,
  );
  final r3 = _buildTestRider(
    id: 'r3',
    firstName: 'Lucas',
    lastName: 'Vandenberg',
    teamId: 'team_rival',
    spec: RiderSpecialization.classicCobbles,
  );

  final t1 = _buildTestTeam('team_player', 'Polonia WT', ['r1', 'r2']);
  final t2 = _buildTestTeam('team_rival', 'Flanders Pro', ['r3']);

  final stage = RaceStage(
    id: 'st_1',
    stageNumber: 1,
    name: 'Alpe d’Huez Summit',
    stageType: StageType.summitFinish,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0,
        lengthKm: 168.0,
        startElevationM: 450,
        endElevationM: 1850,
        surfaceType: SegmentSurfaceType.values.first,
        technicalDifficulty: 35,
        windDirectionDegrees: 180,
        roadBearingDegrees: 90,
        sprintOrKomClassification: SegmentClassification.values.first,
      ),
    ],
    baseTemperatureCelsius: 19,
    weatherCondition: WeatherCondition.sunny,
    windSpeedKmh: 12,
  );

  final race = TourRace(
    id: 'race_1',
    name: 'Critérium du Dauphiné',
    countryIso: 'FR',
    uciCategory: RaceCategory.worldTourStageRace,
    startMonth: 6,
    startDay: 7,
    stages: [stage],
    participatingTeamIds: const ['team_player', 'team_rival'],
    prizePoolEur: 250000,
    ridersPerTeam: 7,
    classifications: const RaceClassifications(
      generalClassification: [],
      pointsClassification: [],
      mountainsClassification: [],
      youthClassification: [],
      teamClassification: [],
    ),
  );

  return CareerSave(
    id: 'save_test',
    saveName: 'Test Career',
    createdAt: DateTime(2026, 1, 1),
    lastSavedAt: DateTime(2026, 6, 6),
    difficulty: CareerDifficulty.normal,
    playerManagerName: 'Menedżer Testowy',
    playerTeamId: 'team_player',
    currentDate: DateTime(2026, 6, 6),
    currentSeasonYear: 2026,
    calendar: SeasonCalendar(seasonYear: 2026, races: [race]),
    teams: [t1, t2],
    riders: [r1, r2, r3],
  );
}

void main() {
  group('SocialMediaAndCyclingNewsService', () {
    const service = SocialMediaAndCyclingNewsService();

    test('generates initial feed covering previews, reports, watt/VAM, rumors, and rider socials', () {
      final save = _buildTestSave();
      final feed = service.generateInitialFeed(save, seed: 42);

      expect(feed, isNotEmpty);
      expect(
        feed.any((i) => i.type == CyclingNewsItemType.stagePreview && i.starPicks.isNotEmpty),
        isTrue,
      );
      expect(
        feed.any((i) => i.type == CyclingNewsItemType.wattAndVamAnalysis),
        isTrue,
      );
      expect(
        feed.any((i) => i.type == CyclingNewsItemType.riderSocialPost && i.rideSnapshot != null),
        isTrue,
      );

      final first = feed.first;
      final restored = CyclingNewsItem.fromJson(first.toJson());
      expect(restored.id, first.id);
      expect(restored.headline, first.headline);
      expect(restored.type, first.type);
    });

    test('generates post-race bundle with VAM, race report, and bike computer telemetry', () {
      final save = _buildTestSave();
      final bundle = service.generatePostRaceBundle(
        date: DateTime(2026, 6, 7),
        raceName: 'Paris-Roubaix',
        raceId: 'race_pr',
        winnerRiderName: 'Jan Kowalski',
        winnerTeamName: 'Polonia WT',
        teams: save.teams,
        riders: save.riders,
        playerTeamId: save.playerTeamId,
        hadMajorCrash: true,
        seed: 7,
      );

      expect(bundle.length, greaterThanOrEqualTo(4));
      expect(bundle.any((e) => e.type == CyclingNewsItemType.raceReport), isTrue);
      expect(bundle.any((e) => e.type == CyclingNewsItemType.wattAndVamAnalysis), isTrue);
      expect(bundle.any((e) => e.type == CyclingNewsItemType.crashAnalysis), isTrue);
      expect(
        bundle.any((e) => e.type == CyclingNewsItemType.riderSocialPost && e.rideSnapshot != null),
        isTrue,
      );
    });
  });

  group('CyclingNewsFeedWidget responsive & interaction tests', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders cleanly without overflow at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final save = _buildTestSave();
        final feed = const SocialMediaAndCyclingNewsService().generateInitialFeed(save, seed: 12);

        String? likedId;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CyclingNewsFeedWidget(
                  items: feed,
                  onToggleLike: (id) => likedId = id,
                  onToggleBookmark: (_) {},
                  onRefresh: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('MEDIA KOLARSKIE & PELOTON SOCIAL'), findsOneWidget);

        await tester.tap(find.text('Social Kolarzy'));
        await tester.pumpAndSettle();
        expect(find.text('TELEMETRIA KOMPUTERA ROWEROWEGO'), findsWidgets);

        final likeIcon = find.byIcon(Icons.favorite_border_rounded).first;
        await tester.tap(likeIcon);
        await tester.pump();
        expect(likedId, isNotNull);
      });
    }
  });
}
