import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/brake_rotor_heat_and_fade_descent_solver.dart';
import 'package:pro_peloton_manager/models/broadcast/tv_director_live_production_model.dart';

void main() {
  group('TV Director Mode — 12 Cameras & Viewership', () {
    test('initializes all 12 broadcast camera types and 6-monitor deck', () {
      final model = TvDirectorLiveProductionModel.createDefaultTourDeFranceStage();

      expect(model.cameraFeeds.length, 12);
      final types = model.cameraFeeds.map((c) => c.type).toSet();
      expect(types, equals(BroadcastCameraType.values.toSet()));

      expect(model.programCameraId, 'heliCam1');
      expect(model.previewCameraId, 'heliCam2');
      expect(model.programCamera.signalStatus, CameraSignalStatus.onAirProgram);
      expect(model.previewCamera.signalStatus, CameraSignalStatus.previewReady);
      expect(model.sixMonitorDeckFeeds.length, 6);
      expect(model.totalCameraCuts, 0);
    });

    test('switches across all 12 cameras with transitions and updates status', () {
      var model = TvDirectorLiveProductionModel.createDefaultTourDeFranceStage();
      const transitions = BroadcastTransitionType.values;

      var expectedCuts = 0;
      for (var i = 1; i < model.cameraFeeds.length; i++) {
        final target = model.cameraFeeds[i];
        final transition = transitions[i % transitions.length];
        final previousId = model.programCameraId;

        model = model.switchProgramCamera(
          target.cameraId,
          transition: transition,
          raceSecondOverride: i * 10,
        );
        expectedCuts++;

        expect(model.programCameraId, target.cameraId);
        expect(model.programCamera.signalStatus, CameraSignalStatus.onAirProgram);
        expect(model.programCamera.lastCutTimestampSec, i * 10);
        expect(model.lastTransitionType, transition);
        expect(model.lastTransitionDurationMs, transition.defaultDurationMs);
        expect(model.totalCameraCuts, expectedCuts);

        final prevCam =
            model.cameraFeeds.firstWhere((c) => c.cameraId == previousId);
        expect(
          prevCam.signalStatus,
          previousId == model.previewCameraId
              ? CameraSignalStatus.previewReady
              : CameraSignalStatus.liveReady,
        );
      }

      // Switching back to the initial camera completes the full 12-camera cycle.
      model = model.switchProgramCamera(
        'heliCam1',
        transition: BroadcastTransitionType.replayStinger,
        raceSecondOverride: 120,
      );
      expect(model.programCameraId, 'heliCam1');
      expect(model.totalCameraCuts, 12);
    });

    test('cuePreviewCamera and takePreviewToProgram swap PROGRAM and PREVIEW', () {
      var model = TvDirectorLiveProductionModel.createDefaultTourDeFranceStage();

      model = model.cuePreviewCamera('motoCamPeloton');
      expect(model.previewCameraId, 'motoCamPeloton');
      expect(
        model.previewCamera.signalStatus,
        CameraSignalStatus.previewReady,
      );

      final oldProgramId = model.programCameraId;
      model = model.takePreviewToProgram(
        transition: BroadcastTransitionType.dissolve,
        raceSecondOverride: 45,
      );

      expect(model.programCameraId, 'motoCamPeloton');
      expect(model.previewCameraId, oldProgramId);
      expect(model.totalCameraCuts, 1);
      expect(model.lastTransitionType, BroadcastTransitionType.dissolve);
    });

    test('blocks cutting to unavailable cameras (rfDropOut, standby, low battery)', () {
      final base = TvDirectorLiveProductionModel.createDefaultTourDeFranceStage();
      final degradedFeeds = base.cameraFeeds.map((cam) {
        if (cam.cameraId == 'motoCamChase') {
          return cam.copyWith(signalStatus: CameraSignalStatus.rfDropOut);
        }
        if (cam.cameraId == 'droneTrackingCam') {
          return cam.copyWith(signalStatus: CameraSignalStatus.standby);
        }
        if (cam.cameraId == 'onBoardSaddleCam') {
          return cam.copyWith(batteryOrFuelPercent: 0.4);
        }
        return cam;
      }).toList();

      final model = base.copyWith(cameraFeeds: degradedFeeds);

      expect(model.switchProgramCamera('motoCamChase').programCameraId, 'heliCam1');
      expect(model.switchProgramCamera('droneTrackingCam').programCameraId, 'heliCam1');
      expect(model.switchProgramCamera('onBoardSaddleCam').programCameraId, 'heliCam1');
      expect(model.switchProgramCamera('nonExistentCam').programCameraId, 'heliCam1');
    });

    test('assigns monitor deck slots and preserves state across JSON round-trip', () {
      var model = TvDirectorLiveProductionModel.createDefaultTourDeFranceStage();
      model = model.assignMonitorDeckSlot(0, 'droneTrackingCam');
      expect(model.sixMonitorDeckIds[0], 'droneTrackingCam');

      // Invalid slot or unknown camera is a no-op.
      expect(model.assignMonitorDeckSlot(-1, 'heliCam1').sixMonitorDeckIds[0],
          'droneTrackingCam');
      expect(model.assignMonitorDeckSlot(6, 'heliCam1').sixMonitorDeckIds[0],
          'droneTrackingCam');
      expect(model.assignMonitorDeckSlot(0, 'unknown').sixMonitorDeckIds[0],
          'droneTrackingCam');

      final restored = TvDirectorLiveProductionModel.fromJson(model.toJson());
      expect(restored.productionId, model.productionId);
      expect(restored.cameraFeeds.length, 12);
      expect(restored.sixMonitorDeckIds, model.sixMonitorDeckIds);
      expect(restored.graphicsQueue.length, model.graphicsQueue.length);
      expect(
        restored.viewershipMetrics.dramaRating,
        closeTo(model.viewershipMetrics.dramaRating, 1e-6),
      );
    });

    test('calculates viewership, drama rating, peak moments, and budget on hot camera', () {
      var model = TvDirectorLiveProductionModel.createDefaultTourDeFranceStage();
      final initialDrama = model.viewershipMetrics.dramaRating;
      final initialSkill = model.viewershipMetrics.directorSkillScore;

      // Switch to motoCamPeloton (actionHeatScore: 79.0 >= 70.0 -> hot moment).
      model = model.switchProgramCamera('motoCamPeloton', raceSecondOverride: 5);
      expect(model.capturedPeakMomentsCount, 1);
      expect(model.viewershipMetrics.dramaRating, greaterThan(initialDrama));
      expect(model.viewershipMetrics.directorSkillScore, greaterThan(initialSkill));

      // Boost camera heat & stage action intensity to push drama >= 75 and earn bonus.
      final hotFeeds = model.cameraFeeds.map((cam) {
        if (cam.cameraId == 'motoCamPeloton') {
          return cam.copyWith(actionHeatScore: 95.0);
        }
        return cam;
      }).toList();
      model = model.copyWith(cameraFeeds: hotFeeds);

      final initialViewers = model.viewershipMetrics.viewershipMillions;
      for (var s = 0; s < 30; s++) {
        model = model.tickSecond(deltaSeconds: 1, stageActionIntensity: 95.0);
      }

      expect(model.currentRaceSecond, 35);
      expect(model.viewershipMetrics.dramaRating, greaterThan(75.0));
      expect(model.viewershipMetrics.viewershipMillions, greaterThan(initialViewers));
      expect(
        model.viewershipMetrics.peakViewershipMillions,
        greaterThanOrEqualTo(model.viewershipMetrics.viewershipMillions),
      );
      expect(model.viewershipMetrics.consecutiveDeadAirSeconds, 0);
      expect(model.productionBudget.spentToDateEur, greaterThan(0.0));
      expect(model.productionBudget.motoCrewAndRfRelayCostEur, greaterThan(0.0));
      expect(model.productionBudget.viewershipBonusEarnedEur, greaterThan(0.0));
      expect(model.viewershipMetrics.historySamples, isNotEmpty);
    });

    test('penalizes dead air when ignoring hottest action and counts missed events', () {
      var model = TvDirectorLiveProductionModel.createDefaultTourDeFranceStage();
      final feedsWithPeak = model.cameraFeeds.map((cam) {
        if (cam.cameraId == 'motoCamFront') {
          return cam.copyWith(actionHeatScore: 92.0);
        }
        return cam;
      }).toList();
      model = model.copyWith(cameraFeeds: feedsWithPeak);

      // Cut to finishLineOverhead (actionHeatScore: 25.0) while motoCamFront is at 92.0.
      model = model.switchProgramCamera('finishLineOverhead');
      final dramaBefore = model.viewershipMetrics.dramaRating;
      final skillBefore = model.viewershipMetrics.directorSkillScore;

      model = model.tickSecond(deltaSeconds: 5, stageActionIntensity: 80.0);

      expect(model.viewershipMetrics.consecutiveDeadAirSeconds, 5);
      expect(model.missedActionEventsCount, 1);
      expect(model.viewershipMetrics.dramaRating, lessThan(dramaBefore));
      expect(model.viewershipMetrics.directorSkillScore, lessThan(skillBefore));
    });

    test('triggers graphics on air, boosts viewership, and completes after duration', () {
      var model = TvDirectorLiveProductionModel.createDefaultTourDeFranceStage();
      final dramaBefore = model.viewershipMetrics.dramaRating;
      final viewersBefore = model.viewershipMetrics.viewershipMillions;

      model = model.triggerGraphicOnAir('gfx_wkg_battle_01', raceSecondOverride: 10);

      expect(model.activeOnAirGraphic?.id, 'gfx_wkg_battle_01');
      expect(model.viewershipMetrics.dramaRating, greaterThan(dramaBefore));
      expect(model.viewershipMetrics.viewershipMillions, greaterThan(viewersBefore));
      expect(model.productionBudget.graphicsAndReplayOpsCostEur, 420.0);

      // Tick through the 12-second graphic duration.
      model = model.tickSecond(deltaSeconds: 12);
      expect(model.activeOnAirGraphic, isNull);
      final completed =
          model.graphicsQueue.firstWhere((g) => g.id == 'gfx_wkg_battle_01');
      expect(completed.status, TvGraphicQueueStatus.completed);

      expect(
        ViewershipDramaTier.fromRating(10.0),
        ViewershipDramaTier.lull,
      );
      expect(
        ViewershipDramaTier.fromRating(35.0),
        ViewershipDramaTier.building,
      );
      expect(
        ViewershipDramaTier.fromRating(60.0),
        ViewershipDramaTier.heated,
      );
      expect(
        ViewershipDramaTier.fromRating(82.0),
        ViewershipDramaTier.thriller,
      );
      expect(
        ViewershipDramaTier.fromRating(95.0),
        ViewershipDramaTier.historicClassic,
      );
    });
  });

  group('Alpine Descent Brake Rotor Heat & Brake Fade Physics', () {
    test('computeFadeFactor preserves full braking <= threshold and fades above 450C', () {
      expect(
        BrakeRotorHeatAndFadeDescentSolver.computeFadeFactor(
          rotorTempCelsius: 250.0,
        ),
        1.0,
      );
      expect(
        BrakeRotorHeatAndFadeDescentSolver.computeFadeFactor(
          rotorTempCelsius: 450.0,
          padCompound: BrakePadCompound.worldTourFinned,
        ),
        1.0,
      );

      final fade480 = BrakeRotorHeatAndFadeDescentSolver.computeFadeFactor(
        rotorTempCelsius: 480.0,
        padCompound: BrakePadCompound.worldTourFinned,
      );
      final fade560 = BrakeRotorHeatAndFadeDescentSolver.computeFadeFactor(
        rotorTempCelsius: 560.0,
        padCompound: BrakePadCompound.worldTourFinned,
      );
      final fade800 = BrakeRotorHeatAndFadeDescentSolver.computeFadeFactor(
        rotorTempCelsius: 800.0,
        padCompound: BrakePadCompound.worldTourFinned,
      );

      expect(fade480, lessThan(1.0));
      expect(fade560, lessThan(fade480));
      expect(fade800, greaterThanOrEqualTo(BrakePadCompound.worldTourFinned.minFadeFloor));

      // Sintered pads resist fade better than resin pads at 460C.
      final resinFade460 = BrakeRotorHeatAndFadeDescentSolver.computeFadeFactor(
        rotorTempCelsius: 460.0,
        padCompound: BrakePadCompound.resinOrganic,
      );
      final sinteredFade460 = BrakeRotorHeatAndFadeDescentSolver.computeFadeFactor(
        rotorTempCelsius: 460.0,
        padCompound: BrakePadCompound.sinteredMetallic,
      );
      expect(sinteredFade460, greaterThan(resinFade460));
    });

    test('classifyThermalZone maps temperature bands accurately', () {
      expect(
        BrakeRotorHeatAndFadeDescentSolver.classifyThermalZone(95.0),
        RotorThermalZone.optimal,
      );
      expect(
        BrakeRotorHeatAndFadeDescentSolver.classifyThermalZone(220.0),
        RotorThermalZone.warm,
      );
      expect(
        BrakeRotorHeatAndFadeDescentSolver.classifyThermalZone(380.0),
        RotorThermalZone.hot,
      );
      expect(
        BrakeRotorHeatAndFadeDescentSolver.classifyThermalZone(475.0),
        RotorThermalZone.fadeOnset,
      );
      expect(
        BrakeRotorHeatAndFadeDescentSolver.classifyThermalZone(560.0),
        RotorThermalZone.criticalBoil,
      );
    });

    test('cooling power and interval cooling reflect rotor size, tech, and wet road', () {
      final cooling140Std = BrakeRotorHeatAndFadeDescentSolver.computeCoolingPowerWatts(
        rotorTempCelsius: 400.0,
        ambientTempCelsius: 18.0,
        bikeSpeedMs: 20.0,
        rotor: BrakeRotorDiameter.mm140,
        coolingTech: BrakeRotorCoolingTech.standardSteel,
        altitudeMeters: 1800.0,
      );
      final cooling160Ice = BrakeRotorHeatAndFadeDescentSolver.computeCoolingPowerWatts(
        rotorTempCelsius: 400.0,
        ambientTempCelsius: 18.0,
        bikeSpeedMs: 20.0,
        rotor: BrakeRotorDiameter.mm160,
        coolingTech: BrakeRotorCoolingTech.iceTechFinned,
        altitudeMeters: 1800.0,
      );
      final coolingWet = BrakeRotorHeatAndFadeDescentSolver.computeCoolingPowerWatts(
        rotorTempCelsius: 400.0,
        ambientTempCelsius: 18.0,
        bikeSpeedMs: 20.0,
        rotor: BrakeRotorDiameter.mm160,
        coolingTech: BrakeRotorCoolingTech.iceTechFinned,
        altitudeMeters: 1800.0,
        environment: const DescentEnvironmentConditions(isWetRoad: true),
      );

      expect(cooling140Std, greaterThan(0.0));
      expect(cooling160Ice, greaterThan(cooling140Std));
      expect(coolingWet, greaterThan(cooling160Ice));

      final cooledTemp = BrakeRotorHeatAndFadeDescentSolver.simulateCoolingInterval(
        startTempCelsius: 420.0,
        intervalDistanceMeters: 400.0,
        averageSpeedKmh: 75.0,
        rotor: BrakeRotorDiameter.mm160,
        coolingTech: BrakeRotorCoolingTech.iceTechFinned,
        altitudeMeters: 1800.0,
      );
      expect(cooledTemp, lessThan(420.0));
      expect(cooledTemp, greaterThanOrEqualTo(18.0));
    });

    test('single hairpin braking heats front rotor more than rear and extends distance on fade', () {
      const config = BrakeRotorSystemConfig(
        frontRotor: BrakeRotorDiameter.mm140,
        rearRotor: BrakeRotorDiameter.mm140,
        coolingTech: BrakeRotorCoolingTech.standardSteel,
        padCompound: BrakePadCompound.worldTourFinned,
        totalSystemMassKg: 82.0,
        frontBrakeBias: 0.72,
      );
      const corner = AlpineHairpinCornerSpec(
        index: 1,
        entrySpeedKmh: 88.0,
        apexSpeedKmh: 24.0,
        gradientPercent: -9.0,
        altitudeMeters: 2100.0,
        availableBrakingRunwayMeters: 58.0,
      );

      final coldStep = BrakeRotorHeatAndFadeDescentSolver.simulateSingleHairpinBraking(
        corner: corner,
        config: config,
        frontTempBeforeCelsius: 80.0,
        rearTempBeforeCelsius: 60.0,
      );
      expect(coldStep.frontEnergyKj, greaterThan(coldStep.rearEnergyKj));
      expect(coldStep.frontTempAfterCelsius, greaterThan(coldStep.frontTempBeforeCelsius));
      expect(coldStep.fadeFactor, 1.0);
      expect(coldStep.brakingDistanceExtensionMeters, 0.0);

      final hotStep = BrakeRotorHeatAndFadeDescentSolver.simulateSingleHairpinBraking(
        corner: corner,
        config: config,
        frontTempBeforeCelsius: 495.0,
        rearTempBeforeCelsius: 280.0,
      );
      expect(hotStep.isFading, isTrue);
      expect(hotStep.fadeFactor, lessThan(1.0));
      expect(hotStep.brakeForceLossPercent, greaterThan(0.0));
      expect(
        hotStep.actualBrakingDistanceMeters,
        greaterThan(hotStep.baselineBrakingDistanceMeters),
      );
      expect(hotStep.brakingDistanceExtensionMeters, greaterThan(0.0));
      expect(hotStep.timeLostToFadeSeconds, greaterThan(0.0));
    });

    test('simulates Passo dello Stelvio descent and shows 160mm rotor thermal advantage over 140mm', () {
      final stelvioCorners = BrakeRotorHeatAndFadeDescentSolver.buildPresetCorners(
        AlpineDescentPreset.passoDelloStelvio,
      );
      expect(stelvioCorners.length, AlpineDescentPreset.passoDelloStelvio.hairpinCount);

      const heavyRiderStandard = BrakeRotorSystemConfig(
        coolingTech: BrakeRotorCoolingTech.standardSteel,
        padCompound: BrakePadCompound.resinOrganic,
        totalSystemMassKg: 86.0,
        descenderSkill: 60,
      );
      const hotSummer = DescentEnvironmentConditions(
        ambientTempCelsius: 30.0,
        isWetRoad: false,
      );

      final comparison = BrakeRotorHeatAndFadeDescentSolver.compare140mmVs160mm(
        baseConfig: heavyRiderStandard,
        corners: stelvioCorners,
        environment: hotSummer,
      );

      expect(comparison.result140mm.hairpinSteps.length, 24);
      expect(comparison.result160mm.hairpinSteps.length, 24);
      expect(comparison.peakTempDifferenceCelsius, greaterThan(0.0));
      expect(
        comparison.result140mm.peakFrontTempCelsius,
        greaterThan(comparison.result160mm.peakFrontTempCelsius),
      );
      expect(comparison.result140mm.fadeTriggeredHairpinCount, greaterThan(0));
      expect(comparison.fadeHairpinsAvoidedWith160mm, greaterThanOrEqualTo(0));
      expect(comparison.maxExtensionDifferenceMeters, greaterThanOrEqualTo(0.0));
      expect(comparison.totalTimeSavedWith160mmSeconds, greaterThanOrEqualTo(0.0));

      // Higher descender skill avoids drag braking and keeps rotors cooler.
      final proDescender = BrakeRotorHeatAndFadeDescentSolver.simulateAlpineDescent(
        config: heavyRiderStandard.copyWith(
          frontRotor: BrakeRotorDiameter.mm140,
          rearRotor: BrakeRotorDiameter.mm140,
          descenderSkill: 96,
        ),
        corners: stelvioCorners,
        environment: hotSummer,
      );
      expect(
        proDescender.peakFrontTempCelsius,
        lessThan(comparison.result140mm.peakFrontTempCelsius),
      );
    });

    test('handles empty hairpin list gracefully', () {
      final emptyResult = BrakeRotorHeatAndFadeDescentSolver.simulateAlpineDescent(
        config: const BrakeRotorSystemConfig(),
        corners: const [],
        environment: const DescentEnvironmentConditions(ambientTempCelsius: 22.0),
      );

      expect(emptyResult.hairpinSteps, isEmpty);
      expect(emptyResult.peakFrontTempCelsius, 22.0);
      expect(emptyResult.peakRearTempCelsius, 22.0);
      expect(emptyResult.fadeTriggeredHairpinCount, 0);
      expect(emptyResult.minFadeFactorObserved, 1.0);
      expect(emptyResult.peakThermalZone, RotorThermalZone.optimal);
    });
  });
}
