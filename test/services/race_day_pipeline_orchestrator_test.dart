import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/services/career/autosave_and_crash_recovery_guard.dart';
import 'package:pro_peloton_manager/services/career/race_day_pipeline_orchestrator.dart';
import 'package:pro_peloton_manager/services/generators/initial_game_seeder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AutosaveAndCrashRecoveryGuard guard;
  late RaceDayPipelineOrchestrator orchestrator;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ppm_race_day_pipeline_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tempDir.path,
    );
    guard = AutosaveAndCrashRecoveryGuard(
      directoryResolver: () async => tempDir,
    );
    orchestrator = RaceDayPipelineOrchestrator.withGuard(guard);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<CareerSave> buildSeededCareer() {
    return InitialGameSeeder.createSeededSave(
      const InitialGameSeedConfig(
        playerTeamId: 'wt_01',
        saveName: 'Test Pipeline Career',
        playerManagerName: 'Jan Testowy',
        seed: 42,
        saveToDisk: false,
      ),
    );
  }

  test('executes full headless race day pipeline from Calendar to AutoSave', () async {
    final initialSave = await buildSeededCareer();
    expect(initialSave.calendar.races, isNotEmpty);

    final resultState = await orchestrator.runHeadlessRaceDay(
      careerSave: initialSave,
      overrideStageIndex: 0,
      maxSimulationTicks: 40,
      tickDeltaSeconds: 10.0,
    );

    expect(resultState.phase, RaceDayPipelinePhase.completed);
    expect(resultState.errorMessage, isNull);
    expect(resultState.finalSummary, isNotNull);
    expect(resultState.stageSummaryReport, isNotNull);
    expect(resultState.sponsorEvaluation, isNotNull);
    expect(resultState.recoveryResult, isNotNull);
    expect(resultState.lastSaveReceipt, isNotNull);
    expect(resultState.lastSaveReceipt!.success, isTrue);

    final loggedPhases = resultState.stepLogs.map((l) => l.phase).toList();
    expect(
      loggedPhases,
      containsAll(<RaceDayPipelinePhase>[
        RaceDayPipelinePhase.calendarSelection,
        RaceDayPipelinePhase.preRaceBriefing,
        RaceDayPipelinePhase.liveSimulation3d,
        RaceDayPipelinePhase.stageResultsCalculation,
        RaceDayPipelinePhase.postStagePodium,
        RaceDayPipelinePhase.sponsorEvaluation,
        RaceDayPipelinePhase.recoveryProcessing,
        RaceDayPipelinePhase.autoSaving,
      ]),
    );

    final summary = resultState.finalSummary!;
    expect(summary.stageSummaryReport.results, isNotEmpty);
    expect(summary.recoveryResult.updatedRiders, isNotEmpty);
    expect(summary.updatedSave.currentDate.isAfter(initialSave.currentDate), isTrue);

    final checkpointInspection = await guard.inspectPreStageCheckpoint(initialSave.id);
    expect(checkpointInspection.hasRecoverableStage, isFalse);
  });

  test('supports step-by-step flow pausing at PostStagePodium before completing', () async {
    final initialSave = await buildSeededCareer();

    var state = await orchestrator.startFromCalendar(
      careerSave: initialSave,
    );
    expect(state.phase, RaceDayPipelinePhase.preRaceBriefing);
    expect(state.briefingConfig, isNotNull);
    expect(state.briefingConfig!.selectedRiderIds, isNotEmpty);

    final firstRiderId = state.briefingConfig!.selectedRiderIds.first;
    state = orchestrator.applyPreRaceBriefing(
      currentState: state,
      briefingConfig: state.briefingConfig!.copyWith(
        tacticalOrdersByRiderId: {firstRiderId: TacticalOrder.attack},
        directorSpeechMoraleDelta: 0.05,
        reconnaissanceCompleted: true,
      ),
    );
    expect(state.phase, RaceDayPipelinePhase.liveSimulation3d);

    state = orchestrator.launchSimulationForViewport(currentState: state);
    expect(state.phase, RaceDayPipelinePhase.liveSimulation3d);

    final simState = (await orchestrator.runHeadlessRaceDay(
      careerSave: initialSave,
      maxSimulationTicks: 20,
      persistCheckpointsAndAutosave: false,
    ))
        .simulationState!;

    final podiumState = await orchestrator.executePostStagePipeline(
      currentState: state,
      simulationState: simState,
      autoCompleteAfterPodium: false,
      persistAutoSave: false,
    );
    expect(podiumState.phase, RaceDayPipelinePhase.postStagePodium);
    expect(podiumState.stageSummaryReport, isNotNull);
    expect(podiumState.finalSummary, isNull);

    final completedState = await orchestrator.executePostStagePipeline(
      currentState: podiumState,
      simulationState: simState,
      precomputedReport: podiumState.stageSummaryReport,
      autoCompleteAfterPodium: true,
      persistAutoSave: true,
    );
    expect(completedState.phase, RaceDayPipelinePhase.completed);
    expect(completedState.finalSummary, isNotNull);
    expect(completedState.lastSaveReceipt?.success, isTrue);
  });

  test('fails gracefully when calendar has no races', () async {
    final initialSave = await buildSeededCareer();
    final emptySave = initialSave.copyWith(
      calendar: initialSave.calendar.copyWith(races: const []),
    );

    final state = await orchestrator.startFromCalendar(careerSave: emptySave);
    expect(state.phase, RaceDayPipelinePhase.failed);
    expect(state.errorMessage, isNotNull);
  });
}
