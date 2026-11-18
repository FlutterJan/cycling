import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/broadcast/tv_director_live_production_model.dart';

void main() {
  group('TvDirectorLiveProductionModel', () {
    test('default Tour de France stage initializes 12 independent cameras and 6-monitor deck', () {
      final model = TvDirectorLiveProductionModel.createDefaultTourDeFranceStage();

      expect(BroadcastCameraType.values.length, 12);
      expect(model.cameraFeeds.length, 12);
      expect(model.sixMonitorDeckFeeds.length, 6);
      expect(model.programCamera.cameraId, 'heliCam1');
      expect(model.previewCamera.cameraId, 'heliCam2');
      expect(model.viewershipMetrics.dramaRating, inInclusiveRange(0.0, 100.0));
      expect(model.productionBudget.remainingBudgetEur, 220000.0);
    });

    test('camera switching, preview cueing and TAKE transition update state accurately', () {
      var model = TvDirectorLiveProductionModel.createDefaultTourDeFranceStage();

      model = model.cuePreviewCamera('motoCamPeloton');
      expect(model.previewCameraId, 'motoCamPeloton');
      expect(
        model.previewCamera.signalStatus,
        CameraSignalStatus.previewReady,
      );

      model = model.takePreviewToProgram(
        transition: BroadcastTransitionType.dissolve,
        raceSecondOverride: 120,
      );

      expect(model.programCameraId, 'motoCamPeloton');
      expect(model.previewCameraId, 'heliCam1');
      expect(model.totalCameraCuts, 1);
      expect(model.capturedPeakMomentsCount, 1);
      expect(model.lastTransitionType, BroadcastTransitionType.dissolve);
      expect(model.lastTransitionDurationMs, 320);
    });

    test('graphics queue triggers on air, deducts budget and boosts drama rating', () {
      var model = TvDirectorLiveProductionModel.createDefaultTourDeFranceStage();
      final initialDrama = model.viewershipMetrics.dramaRating;
      final initialBudget = model.productionBudget.remainingBudgetEur;

      model = model.triggerGraphicOnAir(
        'gfx_wkg_battle_01',
        raceSecondOverride: 45,
      );

      final active = model.activeOnAirGraphic;
      expect(active, isNotNull);
      expect(active!.id, 'gfx_wkg_battle_01');
      expect(active.status, TvGraphicQueueStatus.onAir);
      expect(active.airedAtRaceSec, 45);
      expect(model.viewershipMetrics.dramaRating, greaterThan(initialDrama));
      expect(
        model.productionBudget.remainingBudgetEur,
        closeTo(initialBudget - 420.0, 0.001),
      );

      for (var i = 0; i < 12; i++) {
        model = model.tickSecond(deltaSeconds: 1, stageActionIntensity: 78.0);
      }

      expect(model.activeOnAirGraphic, isNull);
      expect(model.currentRaceSecond, 57);
      expect(model.productionBudget.spentToDateEur, greaterThan(420.0));
    });

    test('JSON serialization round-trip preserves all fields', () {
      final original = TvDirectorLiveProductionModel.createDefaultTourDeFranceStage()
          .switchProgramCamera('onBoardHandlebarsCam', raceSecondOverride: 30)
          .triggerGraphicOnAir('gfx_climb_3d_01', raceSecondOverride: 30)
          .tickSecond(deltaSeconds: 15, stageActionIntensity: 85.0);

      final jsonMap = original.toJson();
      final restored = TvDirectorLiveProductionModel.fromJson(jsonMap);

      expect(restored.productionId, original.productionId);
      expect(restored.cameraFeeds.length, 12);
      expect(restored.programCameraId, original.programCameraId);
      expect(restored.previewCameraId, original.previewCameraId);
      expect(restored.totalCameraCuts, original.totalCameraCuts);
      expect(
        restored.viewershipMetrics.dramaRating,
        closeTo(original.viewershipMetrics.dramaRating, 0.0001),
      );
      expect(
        restored.productionBudget.spentToDateEur,
        closeTo(original.productionBudget.spentToDateEur, 0.0001),
      );
      expect(restored.graphicsQueue.length, original.graphicsQueue.length);
      expect(restored.viewershipMetrics.historySamples.length,
          original.viewershipMetrics.historySamples.length);
    });
  });
}
