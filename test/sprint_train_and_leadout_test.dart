import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/peloton/sprint_leadout_aerodynamic_slingshot.dart';
import 'package:pro_peloton_manager/engine/peloton/sprint_train_ai_controller.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';

Rider _buildTestRider({
  required String id,
  required String teamId,
  required RiderSpecialization specialization,
  required int ftpWatts,
  required int watts5s,
  int bikeHandling = 82,
  int raceIq = 80,
  double weightKg = 74.0,
}) {
  return Rider(
    id: id,
    firstName: 'Test',
    lastName: id.toUpperCase(),
    nationalityIso: 'PL',
    birthDate: DateTime(1997, 5, 14),
    potential: 88,
    specialization: specialization,
    physiology: RiderPhysiology(
      heightCm: 181.0,
      weightKg: weightKg,
      bodyFatPercentage: 7.5,
      ftpWatts: ftpWatts,
      wPrimeJoules: 24000,
      vo2Max: 78.0,
      maxHr: 194,
      restingHr: 42,
      lactateThresholdHr: 174,
      recoveryRate: 84.0,
      glycogenCapacityGrams: 580.0,
    ),
    powerProfile: RiderPowerProfile(
      watts5s: watts5s,
      watts15s: (watts5s * 0.84).round(),
      watts30s: (watts5s * 0.66).round(),
      watts1m: (ftpWatts * 1.65).round(),
      watts3m: (ftpWatts * 1.28).round(),
      watts5m: (ftpWatts * 1.18).round(),
      watts20m: (ftpWatts * 1.05).round(),
      watts60m: ftpWatts,
    ),
    skills: RiderSkills(
      cobbles: 68,
      descending: 74,
      bikeHandling: bikeHandling,
      aeroPositioning: 84,
      draftingEfficiency: 86,
      raceIq: raceIq,
      rainResistance: 75,
      heatTolerance: 75,
      timeTrialPositioning: 72,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#F1C27D',
      hairStyleIndex: 2,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
      glassesModelId: 'aero_pro',
      glassesLensColorHex: '#38BDF8',
      helmetModelId: 'aero_road',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.75,
      bodyBuildType: BodyBuildType.sprinterMuscular,
    ),
    contract: RiderContract(
      teamId: teamId,
      role: specialization == RiderSpecialization.pureSprinter
          ? RiderRole.sprinter
          : RiderRole.domestique,
      monthlySalaryEur: 25000,
      signingBonusEur: 10000,
      winBonusEur: 5000,
      releaseClauseEur: 500000,
      contractEndYear: 2028,
      morale: 0.88,
      leaderLoyalty: 0.85,
      requiredRacesIds: const <String>[],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 55.0,
      chronicTrainingLoad: 78.0,
    ),
    careerPointsUci: 850,
  );
}

RiderRaceState _buildRaceState({
  required String riderId,
  required String teamId,
  double distanceCoveredMeters = 177000.0,
  double lateralPositionRoad = 0.0,
  double speedMs = 16.0,
}) {
  return RiderRaceState(
    riderId: riderId,
    teamId: teamId,
    distanceCoveredMeters: distanceCoveredMeters,
    lateralPositionRoad: lateralPositionRoad,
    currentSpeedMs: speedMs,
    currentWatts: 420,
    currentCadenceRpm: 98,
    currentHeartRate: 168,
    currentWPrime: 24000.0,
    currentGlycogen: 320.0,
    bidonsLeft: 1,
    gelsLeft: 2,
    activeTacticalOrder: TacticalOrder.protectLeader,
    groupIndex: 0,
    timeGapToLeaderSeconds: 0.0,
  );
}

({
  SprintTrain train,
  Map<String, Rider> ridersMap,
  Map<String, RiderRaceState> riderStates,
}) _buildFullSprintTrain({
  String teamId = 'team_alpha',
  String teamName = 'Alpha Pro Cycling',
  double lateralRoadPosition = 0.0,
  int sprinterWatts5s = 1580,
  int sprinterBikeHandling = 85,
  int sprinterRaceIq = 83,
}) {
  final loco = _buildTestRider(
    id: '${teamId}_loco3',
    teamId: teamId,
    specialization: RiderSpecialization.domestiqueEngine,
    ftpWatts: 430,
    watts5s: 1150,
  );
  final lifter = _buildTestRider(
    id: '${teamId}_lifter2',
    teamId: teamId,
    specialization: RiderSpecialization.classicCobbles,
    ftpWatts: 420,
    watts5s: 1280,
  );
  final pilot = _buildTestRider(
    id: '${teamId}_pilot1',
    teamId: teamId,
    specialization: RiderSpecialization.versatileSprinter,
    ftpWatts: 410,
    watts5s: 1420,
  );
  final sprinter = _buildTestRider(
    id: '${teamId}_sprinter',
    teamId: teamId,
    specialization: RiderSpecialization.pureSprinter,
    ftpWatts: 395,
    watts5s: sprinterWatts5s,
    bikeHandling: sprinterBikeHandling,
    raceIq: sprinterRaceIq,
  );

  final train = SprintTrain(
    teamId: teamId,
    teamName: teamName,
    sprinterId: sprinter.id,
    members: [
      SprintTrainMember(
        riderId: loco.id,
        role: LeadoutRole.locomotive3,
        orderInTrain: 1,
        targetWatts: 560,
      ),
      SprintTrainMember(
        riderId: lifter.id,
        role: LeadoutRole.speedLifter2,
        orderInTrain: 2,
        targetWatts: 360,
      ),
      SprintTrainMember(
        riderId: pilot.id,
        role: LeadoutRole.finalPilot,
        orderInTrain: 3,
        targetWatts: 310,
      ),
      SprintTrainMember(
        riderId: sprinter.id,
        role: LeadoutRole.sprinter,
        orderInTrain: 4,
        targetWatts: 260,
      ),
    ],
    activeLeadoutRiderId: loco.id,
    lateralRoadPosition: lateralRoadPosition,
    trainSpeedKmh: 58.0,
  );

  final ridersMap = <String, Rider>{
    loco.id: loco,
    lifter.id: lifter,
    pilot.id: pilot,
    sprinter.id: sprinter,
  };

  final riderStates = <String, RiderRaceState>{
    loco.id: _buildRaceState(
      riderId: loco.id,
      teamId: teamId,
      lateralPositionRoad: lateralRoadPosition,
    ),
    lifter.id: _buildRaceState(
      riderId: lifter.id,
      teamId: teamId,
      lateralPositionRoad: lateralRoadPosition,
    ),
    pilot.id: _buildRaceState(
      riderId: pilot.id,
      teamId: teamId,
      lateralPositionRoad: lateralRoadPosition,
    ),
    sprinter.id: _buildRaceState(
      riderId: sprinter.id,
      teamId: teamId,
      lateralPositionRoad: lateralRoadPosition,
    ),
  };

  return (train: train, ridersMap: ridersMap, riderStates: riderStates);
}

void main() {
  group('SprintTrainAiController — formowanie pociągu na ostatnich 3 km i odczepianie rozprowadzających', () {
    test('Sekwencyjne zmiany na czele (3 km -> 1.5 km -> 600 m -> 240 m) oraz spływanie zużytych pomocników', () {
      final setup = _buildFullSprintTrain();
      List<SprintTrain> trains = [setup.train];

      // Faza 1: 2800 m do mety — Lokomotywa #3 na czele (~59.5 km/h), nikt jeszcze nie spłynął
      final step3km = SprintTrainAiController.updateFinalKilometers(
        distanceToFinishMeters: 2800.0,
        existingTrains: trains,
        ridersMap: setup.ridersMap,
        riderStates: setup.riderStates,
        independentSprinterIds: const <String>[],
      );
      trains = step3km.trains;
      final train3km = trains.single;
      expect(train3km.activeLeadoutRiderId, equals('team_alpha_loco3'));
      expect(train3km.trainSpeedKmh, inInclusiveRange(57.0, 61.5));
      expect(train3km.members.every((m) => !m.isSwungOff), isTrue);
      expect(step3km.sprinterDecisions.single.isSprinting, isFalse);

      // Faza 2: 1200 m do mety — Lokomotywa #3 odczepia się, Podkręcający #2 przejmuje czoło (~64.5 km/h)
      final step1500m = SprintTrainAiController.updateFinalKilometers(
        distanceToFinishMeters: 1200.0,
        existingTrains: trains,
        ridersMap: setup.ridersMap,
        riderStates: setup.riderStates,
        independentSprinterIds: const <String>[],
      );
      trains = step1500m.trains;
      final train1500m = trains.single;
      final locoAt1500 = train1500m.members.firstWhere((m) => m.role == LeadoutRole.locomotive3);
      final lifterAt1500 = train1500m.members.firstWhere((m) => m.role == LeadoutRole.speedLifter2);
      final pilotAt1500 = train1500m.members.firstWhere((m) => m.role == LeadoutRole.finalPilot);
      expect(locoAt1500.isSwungOff, isTrue);
      expect(locoAt1500.targetWatts, lessThan(250));
      expect(lifterAt1500.isSwungOff, isFalse);
      expect(pilotAt1500.isSwungOff, isFalse);
      expect(train1500m.activeLeadoutRiderId, equals('team_alpha_lifter2'));
      expect(train1500m.trainSpeedKmh, greaterThan(train3km.trainSpeedKmh));
      expect(train1500m.trainSpeedKmh, inInclusiveRange(62.5, 66.5));

      // Faza 3: 450 m do mety — Podkręcający #2 odczepia się, Ostatni Pilot rozpędza do ~68.5 km/h
      final step600m = SprintTrainAiController.updateFinalKilometers(
        distanceToFinishMeters: 450.0,
        existingTrains: trains,
        ridersMap: setup.ridersMap,
        riderStates: setup.riderStates,
        independentSprinterIds: const <String>[],
      );
      trains = step600m.trains;
      final train600m = trains.single;
      final lifterAt600 = train600m.members.firstWhere((m) => m.role == LeadoutRole.speedLifter2);
      final pilotAt600 = train600m.members.firstWhere((m) => m.role == LeadoutRole.finalPilot);
      final sprinterAt600 = train600m.members.firstWhere((m) => m.role == LeadoutRole.sprinter);
      expect(lifterAt600.isSwungOff, isTrue);
      expect(pilotAt600.isSwungOff, isFalse);
      expect(pilotAt600.targetWatts, inInclusiveRange(950, 1250));
      expect(sprinterAt600.isSwungOff, isFalse);
      expect(train600m.activeLeadoutRiderId, equals('team_alpha_pilot1'));
      expect(train600m.trainSpeedKmh, greaterThan(train1500m.trainSpeedKmh));
      expect(train600m.trainSpeedKmh, inInclusiveRange(67.0, 70.0));
      expect(step600m.sprinterDecisions.single.isSprinting, isFalse);

      // Faza 4: 200 m do mety — Ostatni Pilot spływa, Sprinter odpala finisz (70-76 km/h)
      final step200m = SprintTrainAiController.updateFinalKilometers(
        distanceToFinishMeters: 200.0,
        existingTrains: trains,
        ridersMap: setup.ridersMap,
        riderStates: setup.riderStates,
        independentSprinterIds: const <String>[],
      );
      final train200m = step200m.trains.single;
      final leadoutSwungCount = train200m.members
          .where((m) => m.role != LeadoutRole.sprinter && m.isSwungOff)
          .length;
      expect(leadoutSwungCount, equals(3));
      expect(train200m.activeLeadoutRiderId, equals('team_alpha_sprinter'));
      expect(train200m.trainSpeedKmh, inInclusiveRange(70.0, 76.0));
      expect(step200m.fastestSpeedKmh, inInclusiveRange(70.0, 76.0));

      final sprinterDecision = step200m.sprinterDecisions.single;
      expect(sprinterDecision.isSprinting, isTrue);
      expect(sprinterDecision.isBoxedIn, isFalse);
      expect(sprinterDecision.prematureLaunchPenalty, equals(0.0));
      expect(sprinterDecision.targetWatts, equals(1580));
    });

    test('Ciągła symulacja co 100 m na dystansie 3000 -> 0 m zachowuje monotoniczne odczepianie i narastanie prędkości', () {
      final setup = _buildFullSprintTrain();
      List<SprintTrain> trains = [setup.train];
      int previousSwungCount = 0;
      double previousSpeedKmh = 0.0;

      for (double dist = 3000.0; dist >= 0.0; dist -= 100.0) {
        final result = SprintTrainAiController.updateFinalKilometers(
          distanceToFinishMeters: dist,
          existingTrains: trains,
          ridersMap: setup.ridersMap,
          riderStates: setup.riderStates,
          independentSprinterIds: const <String>[],
        );
        trains = result.trains;
        final currentTrain = trains.single;
        final swungCount = currentTrain.members.where((m) => m.isSwungOff).length;

        expect(swungCount, greaterThanOrEqualTo(previousSwungCount));
        expect(currentTrain.trainSpeedKmh, greaterThanOrEqualTo(previousSpeedKmh));

        previousSwungCount = swungCount;
        previousSpeedKmh = currentTrain.trainSpeedKmh;
      }

      expect(previousSwungCount, equals(3));
      expect(previousSpeedKmh, inInclusiveRange(70.0, 76.0));
    });

    test('Solowy sprinter z wysokim bikeHandling/raceIq wygrywa koło pociągu, a zamknięty przy barierce traci moc', () {
      final mainSetup = _buildFullSprintTrain(
        teamId: 'team_alpha',
        lateralRoadPosition: -0.88,
        sprinterBikeHandling: 75,
        sprinterRaceIq: 72,
      );
      final rivalSetup = _buildFullSprintTrain(
        teamId: 'team_beta',
        teamName: 'Beta Sprint Squad',
        lateralRoadPosition: -0.70,
        sprinterBikeHandling: 90,
        sprinterRaceIq: 88,
      );

      final soloShark = _buildTestRider(
        id: 'solo_shark',
        teamId: 'team_gamma',
        specialization: RiderSpecialization.pureSprinter,
        ftpWatts: 390,
        watts5s: 1520,
        bikeHandling: 86,
        raceIq: 84,
      );
      final soloNovice = _buildTestRider(
        id: 'solo_novice',
        teamId: 'team_delta',
        specialization: RiderSpecialization.pureSprinter,
        ftpWatts: 380,
        watts5s: 1450,
        bikeHandling: 55,
        raceIq: 58,
      );

      final allRiders = <String, Rider>{
        ...mainSetup.ridersMap,
        ...rivalSetup.ridersMap,
        soloShark.id: soloShark,
        soloNovice.id: soloNovice,
      };
      final allStates = <String, RiderRaceState>{
        ...mainSetup.riderStates,
        ...rivalSetup.riderStates,
        soloShark.id: _buildRaceState(
          riderId: soloShark.id,
          teamId: 'team_gamma',
          lateralPositionRoad: 0.10,
        ),
        soloNovice.id: _buildRaceState(
          riderId: soloNovice.id,
          teamId: 'team_delta',
          lateralPositionRoad: 0.25,
        ),
      };

      final result = SprintTrainAiController.updateFinalKilometers(
        distanceToFinishMeters: 200.0,
        existingTrains: [mainSetup.train, rivalSetup.train],
        ridersMap: allRiders,
        riderStates: allStates,
        independentSprinterIds: [soloShark.id, soloNovice.id],
      );

      final alphaDecision = result.sprinterDecisions.firstWhere((d) => d.riderId == 'team_alpha_sprinter');
      expect(alphaDecision.isBoxedIn, isTrue);
      expect(alphaDecision.isSprinting, isFalse);
      expect(alphaDecision.targetWatts, lessThan(400));

      final sharkDecision = result.sprinterDecisions.firstWhere((d) => d.riderId == 'solo_shark');
      expect(sharkDecision.targetWheelRiderId, isNotNull);

      final noviceDecision = result.sprinterDecisions.firstWhere((d) => d.riderId == 'solo_novice');
      expect(noviceDecision.targetWheelRiderId, isNull);
      expect(noviceDecision.isSprinting, isTrue);
    });
  });

  group('SprintLeadoutAerodynamicSlingshot — fizyka procy aerodynamicznej i prędkość maksymalna (70–76 km/h)', () {
    test('Wzorcowy sprinter wystrzelony z koła pilota przy 65 km/h osiąga 70–76 km/h (docelowo 72–76 km/h)', () {
      const input = SprintSlingshotInput(
        sprinterId: 'elite_sprinter',
        leadoutRiderId: 'elite_pilot',
        distanceToFinishMeters: 240.0,
        launchSpeedKmh: 65.0,
        wPrimeTotalJoules: 24000.0,
        wPrimeRemainingJoules: 24000.0,
        criticalPowerWatts: 410.0,
        sprintSkill: 92,
        riderMassKg: 74.0,
        hasLeadoutWheel: true,
      );

      final summary = SprintLeadoutAerodynamicSlingshot.simulateFinal250m(input);

      expect(summary.slingshotTriggered, isTrue);
      expect(summary.peakSpeedKmh, inInclusiveRange(70.0, 76.0));
      expect(
        summary.peakSpeedKmh,
        inInclusiveRange(
          SprintLeadoutAerodynamicSlingshot.targetPeakSpeedMinKmh,
          SprintLeadoutAerodynamicSlingshot.targetPeakSpeedMaxKmh,
        ),
      );
      expect(summary.slingshotSpeedGainKmh, greaterThan(0.0));
      expect(summary.peakSpeedKmh, greaterThan(summary.peakSpeedWithoutSlingshotKmh));
      expect(summary.finishTimeSeconds, inInclusiveRange(10.0, 15.0));

      // Weryfikacja faz na osi czasu: najpierw delayedDragRamp (<= 1.5 s), potem fullExposureSprint, na końcu completed
      expect(
        summary.timeline.any((s) => s.phase == SlingshotPhase.delayedDragRamp),
        isTrue,
      );
      expect(
        summary.timeline.any((s) => s.phase == SlingshotPhase.fullExposureSprint),
        isTrue,
      );
      expect(summary.timeline.last.phase, equals(SlingshotPhase.completed));
      expect(summary.timeline.last.distanceToFinishMeters, equals(0.0));
    });

    test('Narastanie oporu czołowego (0.42 -> 1.00) trwa dokładnie 1.5 s z kołem rozprowadzającego', () {
      final atZero = SprintLeadoutAerodynamicSlingshot.computeFrontalDragMultiplier(
        elapsedSinceLaunchSeconds: 0.0,
        hasLeadoutWheel: true,
      );
      final atHalf = SprintLeadoutAerodynamicSlingshot.computeFrontalDragMultiplier(
        elapsedSinceLaunchSeconds: 0.75,
        hasLeadoutWheel: true,
      );
      final atEnd = SprintLeadoutAerodynamicSlingshot.computeFrontalDragMultiplier(
        elapsedSinceLaunchSeconds: 1.5,
        hasLeadoutWheel: true,
      );
      final withoutLeadout = SprintLeadoutAerodynamicSlingshot.computeFrontalDragMultiplier(
        elapsedSinceLaunchSeconds: 0.3,
        hasLeadoutWheel: false,
      );

      expect(atZero, closeTo(0.42, 1e-6));
      expect(atHalf, closeTo(0.71, 1e-3));
      expect(atEnd, closeTo(1.0, 1e-6));
      expect(withoutLeadout, equals(1.0));
    });

    test('Wyczerpane W\' oraz silny wiatr w twarz obniżają prędkość maksymalną finiszu', () {
      const freshInput = SprintSlingshotInput(
        sprinterId: 'sprinter_1',
        distanceToFinishMeters: 240.0,
        launchSpeedKmh: 65.0,
        wPrimeTotalJoules: 24000.0,
        wPrimeRemainingJoules: 24000.0,
        sprintSkill: 90,
        hasLeadoutWheel: true,
      );

      final tiredInput = freshInput.copyWith(wPrimeRemainingJoules: 2000.0);
      final headwindInput = freshInput.copyWith(headwindMs: 5.0);

      final freshSummary = SprintLeadoutAerodynamicSlingshot.simulateFinal250m(freshInput);
      final tiredSummary = SprintLeadoutAerodynamicSlingshot.simulateFinal250m(tiredInput);
      final headwindSummary = SprintLeadoutAerodynamicSlingshot.simulateFinal250m(headwindInput);

      expect(freshSummary.peakSpeedKmh, inInclusiveRange(70.0, 76.0));
      expect(tiredSummary.peakSpeedKmh, lessThan(freshSummary.peakSpeedKmh - 2.0));
      expect(headwindSummary.peakSpeedKmh, lessThan(freshSummary.peakSpeedKmh - 2.0));
    });
  });
}
