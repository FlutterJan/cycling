import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/ui/widgets/stage_favorites_bookmakers_odds_card.dart';

CyclingTeam _buildTeam({
  required String id,
  required String name,
  required List<String> rosterIds,
}) {
  return CyclingTeam(
    id: id,
    name: name,
    division: TeamDivision.worldTour,
    countryIso: 'POL',
    primaryJerseyColorHex: '#8E4A49',
    secondaryJerseyColorHex: '#181B22',
    accentJerseyColorHex: '#D4AF37',
    cashBalanceEur: 5000000,
    monthlyBurnRateEur: 250000,
    uciPointsSeason: 1200,
    rosterRiderIds: rosterIds,
    staff: const TeamStaff(
      trainersLevel: 85,
      sportsDirectorsLevel: 88,
      doctorsLevel: 82,
      mechanicsLevel: 86,
      scoutsLevel: 80,
    ),
    bikeDeal: const BikeManufacturerDeal(
      manufacturerId: 'bike_1',
      manufacturerName: 'Aethon Cycles',
      prestigeLevel: 5,
      annualCashContributionEur: 1200000,
      freeBikesQuota: 80,
      researchAndDevelopmentLevel: 88,
      suppliedFrameIds: ['frame_1'],
      suppliedWheelsetIds: ['wheel_1'],
      contractYearsLeft: 2,
      minimumUciRankingRequired: 18,
    ),
    sponsors: const [],
    inventoryBikes: const [],
  );
}

Rider _buildRider({
  required String id,
  required String firstName,
  required String lastName,
  required String teamId,
  required RiderSpecialization specialization,
  double weightKg = 68.0,
  int ftpWatts = 410,
  int watts5s = 1150,
  int watts1m = 680,
  int watts5m = 500,
  int watts20m = 435,
  int watts60m = 400,
  double ctl = 85.0,
  double atl = 73.0, // TSB = +12
  int cobbles = 65,
  int drafting = 78,
  int bikeHandling = 78,
  int ttPos = 75,
  Injury? currentInjury,
}) {
  return Rider(
    id: id,
    firstName: firstName,
    lastName: lastName,
    nationalityIso: 'POL',
    birthDate: DateTime(1998, 5, 14),
    potential: 92,
    specialization: specialization,
    physiology: RiderPhysiology(
      heightCm: 178.0,
      weightKg: weightKg,
      bodyFatPercentage: 6.2,
      ftpWatts: ftpWatts,
      wPrimeJoules: 22000,
      vo2Max: 84.0,
      maxHr: 192,
      restingHr: 38,
      lactateThresholdHr: 174,
      recoveryRate: 85.0,
      glycogenCapacityGrams: 550.0,
    ),
    powerProfile: RiderPowerProfile(
      watts5s: watts5s,
      watts15s: (watts5s * 0.88).round(),
      watts30s: (watts5s * 0.72).round(),
      watts1m: watts1m,
      watts3m: (watts5m * 1.12).round(),
      watts5m: watts5m,
      watts20m: watts20m,
      watts60m: watts60m,
    ),
    skills: RiderSkills(
      cobbles: cobbles,
      descending: 82,
      bikeHandling: bikeHandling,
      aeroPositioning: 80,
      draftingEfficiency: drafting,
      raceIq: 84,
      rainResistance: 78,
      heatTolerance: 78,
      timeTrialPositioning: ttPos,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#F1C27D',
      hairStyleIndex: 2,
      hairColorHex: '#2C221E',
      facialHairIndex: 0,
      glassesModelId: 'g1',
      glassesLensColorHex: '#D4AF37',
      helmetModelId: 'h1',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.7,
      bodyBuildType: BodyBuildType.allRounder,
    ),
    contract: RiderContract(
      teamId: teamId,
      role: RiderRole.teamLeader,
      monthlySalaryEur: 35000,
      signingBonusEur: 0,
      winBonusEur: 10000,
      releaseClauseEur: 500000,
      contractEndYear: 2028,
      morale: 85.0,
      leaderLoyalty: 85.0,
      requiredRacesIds: const [],
    ),
    health: RiderHealth(
      acuteTrainingLoad: atl,
      chronicTrainingLoad: ctl,
      currentInjury: currentInjury,
    ),
    careerPointsUci: 1850,
  );
}

RaceStage _buildStage(StageType type) {
  return RaceStage(
    id: 'stage_1',
    stageNumber: 14,
    name: type == StageType.flat ? 'Montpellier — Nîmes' : "Pau — L'Alpe d'Huez",
    stageType: type,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0,
        lengthKm: 150,
        startElevationM: 200,
        endElevationM: type == StageType.flat ? 220 : 1850,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 45,
        windDirectionDegrees: 90,
        roadBearingDegrees: 0,
        sprintOrKomClassification: type == StageType.flat
            ? SegmentClassification.finishLine
            : SegmentClassification.horsCategorie,
      ),
    ],
    baseTemperatureCelsius: 22.0,
    weatherCondition: WeatherCondition.sunny,
    windSpeedKmh: 12.0,
  );
}

void main() {
  group('StageFavoritesBookmakersCalculator', () {
    test('ranks climbers highest on summitFinish and sprinters highest on flat', () {
      final team1 = _buildTeam(id: 't1', name: 'Apex Pro', rosterIds: ['r_climb', 'r_helper1']);
      final team2 = _buildTeam(id: 't2', name: 'Aero Velocity', rosterIds: ['r_sprint', 'r_helper2']);

      final climber = _buildRider(
        id: 'r_climb',
        firstName: 'Tadej',
        lastName: 'Kowalczyk',
        teamId: 't1',
        specialization: RiderSpecialization.gcClimber,
        weightKg: 62.0,
        watts20m: 410, // 6.61 W/kg
        watts5m: 495,
        watts5s: 980,
      );
      final helper1 = _buildRider(
        id: 'r_helper1',
        firstName: 'Jan',
        lastName: 'Nowak',
        teamId: 't1',
        specialization: RiderSpecialization.domestiqueEngine,
      );
      final sprinter = _buildRider(
        id: 'r_sprint',
        firstName: 'Jasper',
        lastName: 'Blysk',
        teamId: 't2',
        specialization: RiderSpecialization.pureSprinter,
        weightKg: 78.0,
        watts20m: 360, // 4.61 W/kg
        watts5m: 430,
        watts5s: 1680,
        drafting: 92,
        bikeHandling: 90,
      );
      final helper2 = _buildRider(
        id: 'r_helper2',
        firstName: 'Piotr',
        lastName: 'Szybki',
        teamId: 't2',
        specialization: RiderSpecialization.versatileSprinter,
      );

      final inputs = StageFavoritesBookmakersCalculator.buildInputsFromRosters(
        riders: [climber, helper1, sprinter, helper2],
        teamsById: {'t1': team1, 't2': team2},
        playerTeamId: 't1',
      );

      final mountainFavorites = StageFavoritesBookmakersCalculator.calculateTopFavorites(
        stage: _buildStage(StageType.summitFinish),
        candidates: inputs,
      );
      expect(mountainFavorites.first.rider.id, 'r_climb');
      expect(mountainFavorites.first.stars, 5);
      expect(mountainFavorites.first.isPlayerTeam, isTrue);

      final flatFavorites = StageFavoritesBookmakersCalculator.calculateTopFavorites(
        stage: _buildStage(StageType.flat),
        candidates: inputs,
      );
      expect(flatFavorites.first.rider.id, 'r_sprint');
      expect(flatFavorites.first.stars, 5);
    });

    test('TSB peak form and stronger train improve ranking and shorten odds', () {
      final tPeak = _buildTeam(id: 't_peak', name: 'Peak Squad', rosterIds: ['peak', 'm1', 'm2', 'm3']);
      final tTired = _buildTeam(id: 't_tired', name: 'Tired Squad', rosterIds: ['tired']);

      final peakRider = _buildRider(
        id: 'peak',
        firstName: 'Marek',
        lastName: 'Szczyt',
        teamId: 't_peak',
        specialization: RiderSpecialization.gcClimber,
        weightKg: 64.0,
        watts20m: 410,
        ctl: 90,
        atl: 78, // TSB = +12
      );
      final tiredRider = _buildRider(
        id: 'tired',
        firstName: 'Adam',
        lastName: 'Zmeczony',
        teamId: 't_tired',
        specialization: RiderSpecialization.gcClimber,
        weightKg: 64.0,
        watts20m: 410,
        ctl: 75,
        atl: 105, // TSB = -30
      );
      final mates = [
        _buildRider(id: 'm1', firstName: 'H1', lastName: 'One', teamId: 't_peak', specialization: RiderSpecialization.domestiqueEngine),
        _buildRider(id: 'm2', firstName: 'H2', lastName: 'Two', teamId: 't_peak', specialization: RiderSpecialization.domestiqueEngine),
        _buildRider(id: 'm3', firstName: 'H3', lastName: 'Three', teamId: 't_peak', specialization: RiderSpecialization.pureClimber),
      ];

      final inputs = [
        StageFavoriteCandidateInput(rider: tiredRider, team: tTired),
        StageFavoriteCandidateInput(rider: peakRider, team: tPeak, teammates: mates),
      ];

      final result = StageFavoritesBookmakersCalculator.calculateTopFavorites(
        stage: _buildStage(StageType.highMountain),
        candidates: inputs,
      );

      expect(result.length, 2);
      expect(result[0].rider.id, 'peak');
      expect(result[0].decimalOdds, lessThan(result[1].decimalOdds));
      expect(result[0].oddsTrend, BookmakerOddsTrend.shortening);
      expect(result[1].oddsTrend, BookmakerOddsTrend.drifting);
    });

    test('returns at most 5 favorites and handles empty list', () {
      expect(
        StageFavoritesBookmakersCalculator.calculateTopFavorites(
          stage: _buildStage(StageType.flat),
          candidates: const [],
        ),
        isEmpty,
      );

      final team = _buildTeam(
        id: 't1',
        name: 'Team Seven',
        rosterIds: List.generate(7, (i) => 'r$i'),
      );
      final inputs = List.generate(
        7,
        (i) => StageFavoriteCandidateInput(
          rider: _buildRider(
            id: 'r$i',
            firstName: 'Rider',
            lastName: '$i',
            teamId: 't1',
            specialization: RiderSpecialization.pureSprinter,
            watts5s: 1600 - i * 40,
          ),
          team: team,
        ),
      );

      final top5 = StageFavoritesBookmakersCalculator.calculateTopFavorites(
        stage: _buildStage(StageType.flat),
        candidates: inputs,
      );
      expect(top5.length, 5);
      for (final entry in top5) {
        expect(entry.stars, inInclusiveRange(1, 5));
        expect(entry.decimalOdds, greaterThanOrEqualTo(1.25));
      }
    });
  });

  group('StageFavoritesBookmakersOddsCard Widget', () {
    List<StageFavoriteCandidateInput> sampleInputs() {
      final team = _buildTeam(
        id: 't1',
        name: 'Team Polska Pro',
        rosterIds: ['r0', 'r1', 'r2', 'r3', 'r4', 'r5'],
      );
      return List.generate(
        6,
        (i) => StageFavoriteCandidateInput(
          rider: _buildRider(
            id: 'r$i',
            firstName: 'Kolarz',
            lastName: 'Faworyt $i',
            teamId: 't1',
            specialization: RiderSpecialization.gcClimber,
            weightKg: 63.0 + i,
            watts20m: 415 - i * 10,
          ),
          team: team,
          isPlayerTeam: i == 0,
        ),
      );
    }

    testWidgets('displays top 5, toggles odds mode, expands breakdown on tap', (tester) async {
      StageFavoriteOddsEntry? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StageFavoritesBookmakersOddsCard(
                stage: _buildStage(StageType.highMountain),
                candidates: sampleInputs(),
                onFavoriteSelected: (entry) => selected = entry,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('FAWORYCI I KURSY PRZEDETAPOWE'), findsOneWidget);
      expect(find.text('Kolarz Faworyt 0'), findsOneWidget);
      expect(find.text('Kolarz Faworyt 4'), findsOneWidget);
      expect(find.text('Kolarz Faworyt 5'), findsNothing);

      // Tap first rider to expand scouting breakdown
      await tester.tap(find.text('Kolarz Faworyt 0'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(selected?.rider.id, 'r0');
      expect(find.text('RAPORT SKAUTINGU PRZEDETAPOWEGO'), findsOneWidget);

      // Toggle to probability mode
      await tester.tap(find.text('Szansa %'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('handles empty candidates state gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StageFavoritesBookmakersOddsCard(
              stage: _buildStage(StageType.flat),
              candidates: const [],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Brak zgłoszonych kolarzy do wyliczenia kursów'), findsOneWidget);
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('no overflow at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: StageFavoritesBookmakersOddsCard(
                  stage: _buildStage(StageType.summitFinish),
                  candidates: sampleInputs(),
                  onRefreshOdds: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
      });
    }
  });
}
