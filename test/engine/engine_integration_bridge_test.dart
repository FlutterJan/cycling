import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/engine_integration_bridge.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_simulation_loop.dart';
import 'package:pro_peloton_manager/models/equipment/bike_fit_configuration.dart';
import 'package:pro_peloton_manager/models/equipment/complete_bike.dart';
import 'package:pro_peloton_manager/models/equipment/equipment_wear_and_maintenance.dart';
import 'package:pro_peloton_manager/models/equipment/frame_model.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/generators/fictional_brands_catalog.dart';
import 'package:pro_peloton_manager/services/generators/world_teams_generator.dart';

void main() {
  group('EngineIntegrationBridge (#206)', () {
    late RaceStage stage;
    late Map<String, Rider> ridersMap;
    late Map<String, CompleteBike> bikesMap;
    late Map<String, CyclingTeam> teamsMap;
    late String playerTeamId;
    late String testRiderId;

    setUp(() {
      final world = WorldTeamsGenerator.generateWorldTourSystem(seed: 77);
      final subsetRiders = world.allRiders.take(16).toList();
      playerTeamId = world.teams.first.id;
      testRiderId = subsetRiders.first.id;

      ridersMap = {for (final r in subsetRiders) r.id: r};
      final baseBike = FictionalBrandsCatalog.assembleBike(
        brandId: 'brand_aethel',
        frameCategory: FrameCategory.allRounder,
      );
      bikesMap = {for (final r in subsetRiders) r.id: baseBike};
      teamsMap = {for (final t in world.teams) t.id: t};

      stage = const RaceStage(
        id: 'test_stage_206',
        stageNumber: 1,
        name: 'Test Integration Stage',
        stageType: StageType.highMountain,
        baseTemperatureCelsius: 24.0,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 12.0,
        segments: [
          StageSegment(
            index: 0,
            startKm: 0.0,
            lengthKm: 25.0,
            startElevationM: 400.0,
            endElevationM: 2100.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 30.0,
            windDirectionDegrees: 0.0,
            roadBearingDegrees: 90.0,
            sprintOrKomClassification: SegmentClassification.horsCategorie,
          ),
        ],
      );
    });

    test('BikeFitConfiguration (#130) directly alters effectiveCdA and rider speed', () {
      const aeroFit = BikeFitConfiguration(
        saddleHeightMm: 745.0,
        saddleSetbackMm: 55.0,
        saddleTiltDegrees: -2.5,
        cockpitWidthMm: 360,
        stemLengthMm: 135,
        spacersStackMm: 0,
        hoodInwardTiltDegrees: 14.0,
        crankArmLengthMm: 165.0,
        cleatOffsetMm: -3.0,
      );
      const uprightFit = BikeFitConfiguration(
        saddleHeightMm: 745.0,
        saddleSetbackMm: 55.0,
        saddleTiltDegrees: 0.0,
        cockpitWidthMm: 440,
        stemLengthMm: 95,
        spacersStackMm: 30,
        hoodInwardTiltDegrees: 0.0,
        crankArmLengthMm: 175.0,
        cleatOffsetMm: 0.0,
      );

      final aeroBridge = EngineIntegrationBridge.initializeStage(
        stage: stage,
        playerTeamId: playerTeamId,
        allRidersMap: ridersMap,
        allBikesMap: bikesMap,
        allTeamsMap: teamsMap,
        customBikeFits: {testRiderId: aeroFit},
        raceSeed: 1,
      );
      final uprightBridge = EngineIntegrationBridge.initializeStage(
        stage: stage,
        playerTeamId: playerTeamId,
        allRidersMap: ridersMap,
        allBikesMap: bikesMap,
        allTeamsMap: teamsMap,
        customBikeFits: {testRiderId: uprightFit},
        raceSeed: 1,
      );

      final loopAero = StageSimulationLoop.initializeStage(
        stage: stage,
        playerTeamId: playerTeamId,
        allRidersMap: ridersMap,
        allBikesMap: bikesMap,
        allTeamsMap: teamsMap,
      );
      final rider = ridersMap[testRiderId]!;
      final bike = bikesMap[testRiderId]!;
      final rState = loopAero.state.riderStates[testRiderId]!;

      final outAero = aeroBridge.evaluateRiderPreStep(
        rider: rider,
        bike: bike,
        riderState: rState,
        stage: stage,
        segment: stage.segments.first,
        currentDraftingModifier: 0.0,
        timeStepSeconds: 1.0,
        isPlayerRider: true,
        distanceRemainingKm: 25.0,
      );
      final outUpright = uprightBridge.evaluateRiderPreStep(
        rider: rider,
        bike: bike,
        riderState: rState,
        stage: stage,
        segment: stage.segments.first,
        currentDraftingModifier: 0.0,
        timeStepSeconds: 1.0,
        isPlayerRider: true,
        distanceRemainingKm: 25.0,
      );

      expect(outAero.effectiveCdA, lessThan(outUpright.effectiveCdA));

      final speedAero = aeroBridge.solveSpeedForIntegratedStep(
        stepOutput: outAero,
        bike: bike,
        segment: stage.segments.first,
        currentSpeedMs: 12.0,
        actualExecutedWatts: 380.0,
        timeStepSeconds: 1.0,
      );
      final speedUpright = uprightBridge.solveSpeedForIntegratedStep(
        stepOutput: outUpright,
        bike: bike,
        segment: stage.segments.first,
        currentSpeedMs: 12.0,
        actualExecutedWatts: 380.0,
        timeStepSeconds: 1.0,
      );

      expect(speedAero.newSpeedMs, greaterThan(speedUpright.newSpeedMs));
    });

    test('Tire pressure (#132) and chain wax (#133) directly affect Crr, drivetrainLoss and speed', () {
      final washedOutWear = EquipmentWearAndMaintenance(
        chain: const ChainAndWaxCondition(
          lubricantType: DrivetrainLubricantType.strippedNoLube,
          waxFilmRemainingPercent: 0.0,
          chainElongationPercent: 0.65,
          totalChainMileageKm: 2400.0,
          mileageSinceLastWaxKm: 300.0,
          isWashedOut: true,
        ),
        frontTire: TireWearCondition.brandNew(isTubeless: true),
        rearTire: TireWearCondition.brandNew(isTubeless: true),
        frontBrake: BrakeWearCondition.brandNew(),
        rearBrake: BrakeWearCondition.brandNew(),
        electronicBatteryPercent: 100.0,
      );

      final badBikes = Map<String, CompleteBike>.from(bikesMap);
      badBikes[testRiderId] = bikesMap[testRiderId]!.applyWear(washedOutWear);

      final goodBridge = EngineIntegrationBridge.initializeStage(
        stage: stage,
        playerTeamId: playerTeamId,
        allRidersMap: ridersMap,
        allBikesMap: bikesMap,
        allTeamsMap: teamsMap,
        raceSeed: 1,
      );
      final badBridge = EngineIntegrationBridge.initializeStage(
        stage: stage,
        playerTeamId: playerTeamId,
        allRidersMap: ridersMap,
        allBikesMap: badBikes,
        allTeamsMap: teamsMap,
        customTirePressures: {
          testRiderId: const RiderTirePressureSetup(
            frontPressureBar: 8.5,
            rearPressureBar: 8.5,
          ),
        },
        raceSeed: 1,
      );

      final loop = StageSimulationLoop.initializeStage(
        stage: stage,
        playerTeamId: playerTeamId,
        allRidersMap: ridersMap,
        allBikesMap: bikesMap,
        allTeamsMap: teamsMap,
      );
      final rider = ridersMap[testRiderId]!;
      final rState = loop.state.riderStates[testRiderId]!.copyWith(
        currentSpeedMs: 11.0,
        currentWatts: 320,
      );

      final outGood = goodBridge.evaluateRiderPreStep(
        rider: rider,
        bike: bikesMap[testRiderId]!,
        riderState: rState,
        stage: stage,
        segment: stage.segments.first,
        currentDraftingModifier: 0.0,
        timeStepSeconds: 1.0,
        isPlayerRider: true,
        distanceRemainingKm: 25.0,
      );
      final outBad = badBridge.evaluateRiderPreStep(
        rider: rider,
        bike: badBikes[testRiderId]!,
        riderState: rState,
        stage: stage,
        segment: stage.segments.first,
        currentDraftingModifier: 0.0,
        timeStepSeconds: 1.0,
        isPlayerRider: true,
        distanceRemainingKm: 25.0,
      );

      expect(outBad.effectiveCrr, greaterThan(outGood.effectiveCrr));
      expect(
        outBad.effectiveDrivetrainLoss,
        greaterThan(outGood.effectiveDrivetrainLoss),
      );

      final speedGood = goodBridge.solveSpeedForIntegratedStep(
        stepOutput: outGood,
        bike: bikesMap[testRiderId]!,
        segment: stage.segments.first,
        currentSpeedMs: 11.0,
        actualExecutedWatts: 320.0,
        timeStepSeconds: 1.0,
      );
      final speedBad = badBridge.solveSpeedForIntegratedStep(
        stepOutput: outBad,
        bike: badBikes[testRiderId]!,
        segment: stage.segments.first,
        currentSpeedMs: 11.0,
        actualExecutedWatts: 320.0,
        timeStepSeconds: 1.0,
      );

      expect(speedGood.newSpeedMs, greaterThan(speedBad.newSpeedMs));
    });

    test('StageSimulationLoop integrates all 7 subsystems and Boids updates lateral/drafting', () {
      final loop = StageSimulationLoop.initializeStage(
        stage: stage,
        playerTeamId: playerTeamId,
        allRidersMap: ridersMap,
        allBikesMap: bikesMap,
        allTeamsMap: teamsMap,
      );

      for (int i = 0; i < 5; i++) {
        loop.step(dt: 1.0);
      }

      expect(loop.state.elapsedSeconds, 5.0);
      for (final rState in loop.state.riderStates.values) {
        expect(rState.distanceCoveredMeters, greaterThan(0.0));
        expect(rState.currentSpeedMs, greaterThan(0.0));
        expect(rState.lateralPositionRoad, inInclusiveRange(-1.0, 1.0));
        expect(loop.integrationBridge.contextForRider(rState.riderId), isNotNull);
      }
    });
  });
}
