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
import 'package:pro_peloton_manager/services/career/team_chemistry_and_builder_service.dart';
import 'package:pro_peloton_manager/state/career_state_notifier.dart';
import 'package:pro_peloton_manager/ui/widgets/season_calendar_gantt_timeline.dart';

Rider _buildTestRider(int index, String teamId) {
  const specs = RiderSpecialization.values;
  return Rider(
    id: 'rider_$index',
    firstName: 'Kolarz',
    lastName: 'Nr$index',
    nationalityIso: 'PL',
    birthDate: DateTime(1998, 5, 14),
    potential: 86,
    specialization: specs[index % specs.length],
    physiology: const RiderPhysiology(
      heightCm: 178,
      weightKg: 66,
      bodyFatPercentage: 6.8,
      ftpWatts: 400,
      wPrimeJoules: 22000,
      vo2Max: 81,
      maxHr: 192,
      restingHr: 40,
      lactateThresholdHr: 174,
      recoveryRate: 84,
      glycogenCapacityGrams: 540,
    ),
    powerProfile: const RiderPowerProfile(
      watts5s: 1150,
      watts15s: 960,
      watts30s: 800,
      watts1m: 650,
      watts3m: 520,
      watts5m: 480,
      watts20m: 420,
      watts60m: 390,
    ),
    skills: const RiderSkills(
      cobbles: 74,
      descending: 80,
      bikeHandling: 82,
      aeroPositioning: 78,
      draftingEfficiency: 80,
      raceIq: 82,
      rainResistance: 76,
      heatTolerance: 78,
      timeTrialPositioning: 80,
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
      role: index < 3 ? RiderRole.values.first : RiderRole.domestique,
      monthlySalaryEur: 70000,
      signingBonusEur: 50000,
      winBonusEur: 25000,
      releaseClauseEur: 2000000,
      contractEndYear: 2028,
      morale: 0.85,
      leaderLoyalty: 0.9,
      requiredRacesIds: const [],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 68,
      chronicTrainingLoad: 82,
    ),
    careerPointsUci: 450,
  );
}

RaceStage _buildStage(int num) {
  return RaceStage(
    id: 'st_$num',
    stageNumber: num,
    name: 'Etap $num',
    stageType: StageType.summitFinish,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0,
        lengthKm: 165.0,
        startElevationM: 400,
        endElevationM: 1600,
        surfaceType: SegmentSurfaceType.values.first,
        technicalDifficulty: 30,
        windDirectionDegrees: 180,
        roadBearingDegrees: 90,
        sprintOrKomClassification: SegmentClassification.values.first,
      ),
    ],
    baseTemperatureCelsius: 20,
    weatherCondition: WeatherCondition.sunny,
    windSpeedKmh: 10,
  );
}

TourRace _buildRace({
  required String id,
  required String name,
  required RaceCategory category,
  required int startMonth,
  required int startDay,
  required int stageCount,
  required String teamId,
}) {
  return TourRace(
    id: id,
    name: name,
    countryIso: 'FR',
    uciCategory: category,
    startMonth: startMonth,
    startDay: startDay,
    stages: List.generate(stageCount, (i) => _buildStage(i + 1)),
    participatingTeamIds: [teamId],
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
}

CareerSave _build28RiderSave({bool withOverlapConflict = false}) {
  const teamId = 'team_player';
  final riders = List.generate(28, (i) => _buildTestRider(i + 1, teamId));
  final team = CyclingTeam(
    id: teamId,
    name: 'Polonia WorldTour',
    division: TeamDivision.worldTour,
    countryIso: 'PL',
    primaryJerseyColorHex: '#8E4A49',
    secondaryJerseyColorHex: '#D4AF37',
    accentJerseyColorHex: '#FFFFFF',
    cashBalanceEur: 5000000,
    monthlyBurnRateEur: 250000,
    uciPointsSeason: 2400,
    rosterRiderIds: riders.map((r) => r.id).toList(),
    staff: const TeamStaff(
      trainersLevel: 75,
      sportsDirectorsLevel: 75,
      doctorsLevel: 75,
      mechanicsLevel: 75,
      scoutsLevel: 75,
    ),
    bikeDeal: const BikeManufacturerDeal(
      manufacturerId: 'romet',
      manufacturerName: 'Romet Carbon',
      prestigeLevel: 4,
      annualCashContributionEur: 300000,
      freeBikesQuota: 50,
      researchAndDevelopmentLevel: 80,
      suppliedFrameIds: ['frame_1'],
      suppliedWheelsetIds: ['wheel_1'],
      contractYearsLeft: 2,
      minimumUciRankingRequired: 18,
    ),
    sponsors: const [],
    inventoryBikes: const [],
  );

  final race1 = _buildRace(
    id: 'race_pn',
    name: 'Paris-Nice',
    category: RaceCategory.worldTourStageRace,
    startMonth: 3,
    startDay: 8,
    stageCount: 8,
    teamId: teamId,
  );
  final race2 = _buildRace(
    id: 'race_tirreno',
    name: 'Tirreno-Adriatico',
    category: RaceCategory.worldTourStageRace,
    startMonth: withOverlapConflict ? 3 : 4,
    startDay: withOverlapConflict ? 10 : 12,
    stageCount: 7,
    teamId: teamId,
  );
  final race3 = _buildRace(
    id: 'race_tdf',
    name: 'Tour de France',
    category: RaceCategory.grandTour,
    startMonth: 7,
    startDay: 4,
    stageCount: 21,
    teamId: teamId,
  );

  return CareerSave(
    id: 'save_gantt',
    saveName: 'Gantt Test Save',
    createdAt: DateTime(2026, 1, 1),
    lastSavedAt: DateTime(2026, 2, 15),
    difficulty: CareerDifficulty.normal,
    playerManagerName: 'Menedżer Testowy',
    playerTeamId: teamId,
    currentDate: DateTime(2026, 2, 15),
    currentSeasonYear: 2026,
    calendar: SeasonCalendar(
      seasonYear: 2026,
      races: [race1, race2, race3],
    ),
    teams: [team],
    riders: riders,
    franchiseLeaders: [
      FranchiseRider(
        riderId: riders.first.id,
        riderName: riders.first.fullName,
        focus: FranchiseRoleFocus.grandTourGc,
        priorityRank: 1,
      ),
    ],
    dedicatedSquads: [
      DedicatedSquad(
        id: 'sq_1',
        name: 'Skład: ${race1.name}',
        leaderRiderId: riders.first.id,
        domestiqueRiderIds: riders.skip(1).take(6).map((r) => r.id).toList(),
        targetSeasonObjective: race1.id,
      ),
      DedicatedSquad(
        id: 'sq_2',
        name: 'Skład: ${race2.name}',
        leaderRiderId: riders.first.id,
        domestiqueRiderIds: riders.skip(1).take(6).map((r) => r.id).toList(),
        targetSeasonObjective: race2.id,
      ),
      DedicatedSquad(
        id: 'sq_3',
        name: 'Skład: ${race3.name}',
        leaderRiderId: riders.first.id,
        domestiqueRiderIds: riders.skip(1).take(7).map((r) => r.id).toList(),
        targetSeasonObjective: race3.id,
      ),
    ],
  );
}

void main() {
  Widget wrapForSize(Widget child, Size size) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renderuje wszystkich 28 kolarzy od STY do PAŹ, obozy i Peak 1/2',
      (tester) async {
    final save = _build28RiderSave();
    final camps = [
      ActiveTrainingCampAssignment(
        riderId: save.playerRoster.first.id,
        locationName: 'Sierra Nevada',
        altitudeMeters: 2320,
        daysRemaining: 12,
        dailyFtpGain: 0.4,
        dailyVo2Gain: 0.1,
        dailyAtlLoad: 95.0,
        dailyCtlGain: 1.4,
      ),
    ];

    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapForSize(
        SeasonCalendarGanttTimeline(
          save: save,
          activeTrainingCamps: camps,
        ),
        const Size(1600, 900),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Planer Obciążeń Sezonu (Gantt)'), findsOneWidget);
    expect(find.text('STY'), findsOneWidget);
    expect(find.text('PAŹ'), findsOneWidget);
    expect(find.text('28 Kolarzy'), findsOneWidget);
    expect(find.text('0 Kolizji'), findsOneWidget);
    expect(find.textContaining('Obóz: Sierra Nevada'), findsOneWidget);
    expect(find.text('P1'), findsWidgets);
    expect(find.text('P2'), findsWidgets);
  });

  testWidgets('wykrywa kolizje nakładających się wyścigów i rozdziela tory',
      (tester) async {
    final saveWithConflict = _build28RiderSave(withOverlapConflict: true);

    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapForSize(
        SeasonCalendarGanttTimeline(save: saveWithConflict),
        const Size(1600, 900),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('7 Kolizji'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
  });

  testWidgets('brak przepełnień LayoutBuilder na 390x844, 1024x768 i 1600x900',
      (tester) async {
    final save = _build28RiderSave();
    const sizes = [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ];

    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        wrapForSize(
          SeasonCalendarGanttTimeline(save: save),
          size,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });
}
