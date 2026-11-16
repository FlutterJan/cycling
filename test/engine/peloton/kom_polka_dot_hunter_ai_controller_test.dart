import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/kom_polka_dot_hunter_ai_controller.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';

Rider _buildTestRider({
  String id = 'kom_hunter_1',
  RiderSpecialization specialization = RiderSpecialization.pureClimber,
  int ftpWatts = 380,
  double weightKg = 60.0,
  int wPrimeJoules = 22000,
}) {
  return Rider(
    id: id,
    firstName: 'Rafal',
    lastName: 'Majka',
    nationalityIso: 'PL',
    birthDate: DateTime(1995, 9, 12),
    potential: 88,
    specialization: specialization,
    physiology: RiderPhysiology(
      heightCm: 173,
      weightKg: weightKg,
      bodyFatPercentage: 5.5,
      ftpWatts: ftpWatts,
      wPrimeJoules: wPrimeJoules,
      vo2Max: 84.0,
      maxHr: 194,
      restingHr: 38,
      lactateThresholdHr: 174,
      recoveryRate: 86.0,
      glycogenCapacityGrams: 550.0,
    ),
    powerProfile: const RiderPowerProfile(
      watts5s: 980,
      watts15s: 840,
      watts30s: 710,
      watts1m: 580,
      watts3m: 470,
      watts5m: 440,
      watts20m: 400,
      watts60m: 380,
    ),
    skills: const RiderSkills(
      cobbles: 55,
      descending: 82,
      bikeHandling: 80,
      aeroPositioning: 74,
      draftingEfficiency: 84,
      raceIq: 88,
      rainResistance: 75,
      heatTolerance: 82,
      timeTrialPositioning: 70,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#F2C9A0',
      hairStyleIndex: 2,
      hairColorHex: '#4A3728',
      facialHairIndex: 0,
      glassesModelId: 'oakley_pro',
      glassesLensColorHex: '#FF4500',
      helmetModelId: 'aero_climber',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.7,
      bodyBuildType: BodyBuildType.climberLean,
    ),
    contract: const RiderContract(
      teamId: 'team_pl',
      role: RiderRole.superDomestique,
      monthlySalaryEur: 25000,
      signingBonusEur: 0,
      winBonusEur: 5000,
      releaseClauseEur: 1000000,
      contractEndYear: 2028,
      morale: 0.85,
      leaderLoyalty: 0.9,
      requiredRacesIds: [],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 60.0,
      chronicTrainingLoad: 78.0,
    ),
    careerPointsUci: 1250,
  );
}

RaceStage _buildMountainStage() {
  return const RaceStage(
    id: 'stage_alpine_kom',
    stageNumber: 14,
    name: 'Col du Galibier -> Alpe d\'Huez',
    stageType: StageType.summitFinish,
    baseTemperatureCelsius: 18.0,
    weatherCondition: WeatherCondition.sunny,
    windSpeedKmh: 12.0,
    segments: [
      // 0 - 20 km: płaska dolina
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 20.0,
        startElevationM: 400.0,
        endElevationM: 450.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 15.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      // 20 - 30 km: podjazd Cat 2 (10 km, +600 m = 6%)
      StageSegment(
        index: 1,
        startKm: 20.0,
        lengthKm: 10.0,
        startElevationM: 450.0,
        endElevationM: 1050.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 35.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.cat2,
      ),
      // 30 - 45 km: zjazd (-650 m / 15 km = -4.33%)
      StageSegment(
        index: 2,
        startKm: 30.0,
        lengthKm: 15.0,
        startElevationM: 1050.0,
        endElevationM: 400.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 65.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      // 45 - 65 km: długa dolina (0.5%)
      StageSegment(
        index: 3,
        startKm: 45.0,
        lengthKm: 20.0,
        startElevationM: 400.0,
        endElevationM: 500.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 20.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      // 65 - 80 km: podjazd Cat 1 (15 km, +1150 m = 7.67%)
      StageSegment(
        index: 4,
        startKm: 65.0,
        lengthKm: 15.0,
        startElevationM: 500.0,
        endElevationM: 1650.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 50.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.cat1,
      ),
      // 80 - 95 km: zjazd do podnóża finałowego podjazdu
      StageSegment(
        index: 5,
        startKm: 80.0,
        lengthKm: 15.0,
        startElevationM: 1650.0,
        endElevationM: 750.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 70.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      // 95 - 109 km: Alpe d'Huez HC finisz na szczycie (14 km, +1120 m = 8.0%)
      StageSegment(
        index: 6,
        startKm: 95.0,
        lengthKm: 14.0,
        startElevationM: 750.0,
        endElevationM: 1870.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 55.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      ),
    ],
  );
}

void main() {
  group('KomPolkaDotHunterAiController', () {
    test('kalkuluje punkty górskie KOM na etapie z premiami Cat 2, Cat 1 i HC (podwójne na mecie)', () {
      final stage = _buildMountainStage();
      final eval = KomPolkaDotHunterAiController.evaluateStageKomPoints(stage);

      expect(eval.totalPrimesCount, 3);
      expect(eval.cat2Count, 1);
      expect(eval.cat1Count, 1);
      expect(eval.hcCount, 1);
      expect(eval.cat3And4Count, 0);
      // Cat2 pośrednie (5) + Cat1 pośrednie (10) + HC finisz na szczycie (40) = 55
      expect(eval.totalAvailableKomPoints, 55);
      expect(eval.highValuePointsTotal, 55);
      expect(eval.isStageWorthHunting, isTrue);
      expect(eval.primes.last.isSummitFinish, isTrue);
      expect(eval.primes.last.summitDistanceMeters, 109000.0);
    });

    test('zwraca pustą ewaluację i brak opłacalności dla etapu płaskiego', () {
      const flatStage = RaceStage(
        id: 'stage_flat',
        stageNumber: 1,
        name: 'Płaski etap',
        stageType: StageType.flat,
        baseTemperatureCelsius: 22.0,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 10.0,
        segments: [
          StageSegment(
            index: 0,
            startKm: 0.0,
            lengthKm: 150.0,
            startElevationM: 100.0,
            endElevationM: 120.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 10.0,
            windDirectionDegrees: 0.0,
            roadBearingDegrees: 90.0,
            sprintOrKomClassification: SegmentClassification.finishLine,
          ),
        ],
      );

      final eval = KomPolkaDotHunterAiController.evaluateStageKomPoints(flatStage);
      expect(eval.primes, isEmpty);
      expect(eval.totalAvailableKomPoints, 0);
      expect(eval.isStageWorthHunting, isFalse);
    });

    test('oszczędza siły na zjazdach oraz w dolinach (regeneracja W\' i glikogenu)', () {
      final rider = _buildTestRider();
      final stage = _buildMountainStage();

      // Zjazd na 35. km (-4.33%)
      final descentState = RiderRaceState.initial(
        riderId: rider.id,
        teamId: 'team_pl',
        initialWPrimeJoules: 15000.0,
        initialGlycogenGrams: 400.0,
        groupIndex: 0,
      ).copyWith(distanceCoveredMeters: 35000.0);

      final descentDecision = KomPolkaDotHunterAiController.evaluateStep(
        rider: rider,
        raceState: descentState,
        stage: stage,
      );

      expect(descentDecision.phase, KomHunterTacticalPhase.conservingInValleyOrDescent);
      expect(descentDecision.shouldConserveEnergy, isTrue);
      expect(descentDecision.shouldSprintForSummit, isFalse);
      expect(descentDecision.tacticalOrder, TacticalOrder.saveEnergy);
      expect(descentDecision.targetWatts, lessThan((rider.physiology.ftpWatts * 0.45).round()));

      // Dolina na 52. km (0.5% nachylenia, > 800 m przed kolejnym podjazdem)
      final valleyState = descentState.copyWith(
        distanceCoveredMeters: 52000.0,
        groupIndex: 1,
      );

      final valleyDecision = KomPolkaDotHunterAiController.evaluateStep(
        rider: rider,
        raceState: valleyState,
        stage: stage,
      );

      expect(valleyDecision.phase, KomHunterTacticalPhase.conservingInValleyOrDescent);
      expect(valleyDecision.shouldConserveEnergy, isTrue);
      expect(valleyDecision.tacticalOrder, TacticalOrder.saveEnergy);
      expect(valleyDecision.targetEffortRatio, lessThanOrEqualTo(0.65));
    });

    test('odpala dynamiczny finisz na ostatnich 600 m przed szczytem Cat 2, Cat 1 i HC', () {
      final rider = _buildTestRider();
      final stage = _buildMountainStage();

      // 1) 700 m przed szczytem Cat 2 (30 000 m) -> jeszcze kontrolowane tempo
      final before600mState = RiderRaceState.initial(
        riderId: rider.id,
        teamId: 'team_pl',
        initialWPrimeJoules: 20000.0,
        initialGlycogenGrams: 420.0,
        groupIndex: 0,
      ).copyWith(distanceCoveredMeters: 29300.0);

      final preSprintDecision = KomPolkaDotHunterAiController.evaluateStep(
        rider: rider,
        raceState: before600mState,
        stage: stage,
      );

      expect(preSprintDecision.phase, KomHunterTacticalPhase.controlledClimbTempo);
      expect(preSprintDecision.shouldSprintForSummit, isFalse);

      // 2) 550 m przed szczytem Cat 2 (29 450 m) -> dynamiczny finisz 600 m!
      final cat2SprintState = before600mState.copyWith(distanceCoveredMeters: 29450.0);
      final cat2SprintDecision = KomPolkaDotHunterAiController.evaluateStep(
        rider: rider,
        raceState: cat2SprintState,
        stage: stage,
      );

      expect(cat2SprintDecision.phase, KomHunterTacticalPhase.summitSprint600m);
      expect(cat2SprintDecision.shouldSprintForSummit, isTrue);
      expect(cat2SprintDecision.tacticalOrder, TacticalOrder.attack);
      expect(cat2SprintDecision.targetWatts, greaterThan(rider.physiology.ftpWatts));

      // 3) 400 m przed szczytem Cat 1 (79 600 m) -> dynamiczny finisz 600 m!
      final cat1SprintState = before600mState.copyWith(distanceCoveredMeters: 79600.0);
      final cat1SprintDecision = KomPolkaDotHunterAiController.evaluateStep(
        rider: rider,
        raceState: cat1SprintState,
        stage: stage,
      );

      expect(cat1SprintDecision.phase, KomHunterTacticalPhase.summitSprint600m);
      expect(cat1SprintDecision.shouldSprintForSummit, isTrue);
      expect(cat1SprintDecision.expectedPointsIfWon, 10);

      // 4) 200 m przed szczytem HC (108 800 m) z rywalem obok -> maksymalny finisz po 40 pkt!
      final hcSprintState = before600mState.copyWith(distanceCoveredMeters: 108800.0);
      final rivalState = hcSprintState.copyWith(
        riderId: 'rival_kom',
        teamId: 'team_rival',
        distanceCoveredMeters: 108780.0,
      );

      final hcSprintDecision = KomPolkaDotHunterAiController.evaluateStep(
        rider: rider,
        raceState: hcSprintState,
        stage: stage,
        nearbyRivals: [rivalState],
      );

      expect(hcSprintDecision.phase, KomHunterTacticalPhase.summitSprint600m);
      expect(hcSprintDecision.shouldSprintForSummit, isTrue);
      expect(hcSprintDecision.expectedPointsIfWon, 40);
      expect(hcSprintDecision.targetWattsPerKg, greaterThan(7.5));
    });

    test('nie uruchamia finiszu 600 m na premii Cat 4 i poprawnie obsługuje wyczerpane W\'', () {
      final rider = _buildTestRider();
      const cat4Stage = RaceStage(
        id: 'stage_cat4',
        stageNumber: 3,
        name: 'Pagórkowaty z Cat 4',
        stageType: StageType.hilly,
        baseTemperatureCelsius: 20.0,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 8.0,
        segments: [
          StageSegment(
            index: 0,
            startKm: 0.0,
            lengthKm: 10.0,
            startElevationM: 100.0,
            endElevationM: 450.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 20.0,
            windDirectionDegrees: 0.0,
            roadBearingDegrees: 90.0,
            sprintOrKomClassification: SegmentClassification.cat4,
          ),
        ],
      );

      final stateAt300m = RiderRaceState.initial(
        riderId: rider.id,
        teamId: 'team_pl',
        initialWPrimeJoules: 0.0,
        initialGlycogenGrams: 300.0,
        groupIndex: 0,
      ).copyWith(distanceCoveredMeters: 9700.0);

      final decision = KomPolkaDotHunterAiController.evaluateStep(
        rider: rider,
        raceState: stateAt300m,
        stage: cat4Stage,
      );

      expect(decision.phase, KomHunterTacticalPhase.controlledClimbTempo);
      expect(decision.shouldSprintForSummit, isFalse);
      expect(decision.targetWatts.isNaN, isFalse);
      expect(decision.targetWatts, greaterThan(0));
    });

    test('ocenia przydatność łowcy grochów wyżej dla czystego górala niż sprintera', () {
      final pureClimber = _buildTestRider(
        id: 'climber',
        specialization: RiderSpecialization.pureClimber,
        ftpWatts: 390,
        weightKg: 59.0,
      );
      final sprinter = _buildTestRider(
        id: 'sprinter',
        specialization: RiderSpecialization.pureSprinter,
        ftpWatts: 370,
        weightKg: 78.0,
      );

      final climberScore = KomPolkaDotHunterAiController.calculateKomHunterSuitability(pureClimber);
      final sprinterScore = KomPolkaDotHunterAiController.calculateKomHunterSuitability(sprinter);

      expect(climberScore, greaterThan(sprinterScore));
      expect(climberScore, greaterThan(70.0));
    });
  });
}
