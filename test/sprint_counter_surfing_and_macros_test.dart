import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/peloton/sprinter_train_counter_surfing_ai.dart';
import 'package:pro_peloton_manager/ui/widgets/quick_tactical_macro_recorder_widget.dart';

void main() {
  group('SprinterTrainCounterSurfingAi — Modele i Serializacja', () {
    test('Enumy CounterSurf obsługują fromJson z fallbackiem dla nieznanych wartości', () {
      expect(
        CounterSurfPhase.fromJson('slingshotLaunch'),
        CounterSurfPhase.slingshotLaunch,
      );
      expect(CounterSurfPhase.fromJson('UNKNOWN'), CounterSurfPhase.standby);

      expect(
        CounterSurfAggression.fromJson('aggressiveWheelThief'),
        CounterSurfAggression.aggressiveWheelThief,
      );
      expect(
        CounterSurfAggression.fromJson('unknown'),
        CounterSurfAggression.balancedSurfer,
      );

      expect(
        WheelHopReason.fromJson('barrierBoxRisk'),
        WheelHopReason.barrierBoxRisk,
      );
      expect(WheelHopReason.fromJson('invalid'), WheelHopReason.none);

      expect(SurfTargetQuality.fromJson('prime'), SurfTargetQuality.prime);
      expect(SurfTargetQuality.fromJson('invalid'), SurfTargetQuality.solid);
    });

    test('RivalTrainSnapshot oraz SprinterSurfProfile zachowują dane w JSON round-trip', () {
      const train = RivalTrainSnapshot(
        teamId: 'team_alpecin',
        teamName: 'Alpecin-Deceuninck',
        targetSprinterId: 'philipsen',
        targetSprinterName: 'J. Philipsen',
        activeLeadoutRiderId: 'mvdp',
        remainingHelpers: 2,
        trainSpeedKmh: 64.2,
        lateralRoadPosition: -0.25,
        leadoutPowerWatts: 630,
        leadoutFatigueFraction: 0.22,
        wheelGapOpen: true,
        rivalWheelDefenseSkill: 82,
      );
      final decodedTrain = RivalTrainSnapshot.fromJson(train.toJson());
      expect(decodedTrain.teamId, train.teamId);
      expect(decodedTrain.trainSpeedKmh, closeTo(64.2, 1e-6));
      expect(decodedTrain.wheelGapOpen, isTrue);
      expect(decodedTrain.copyWith(remainingHelpers: 1).remainingHelpers, 1);

      const sprinter = SprinterSurfProfile(
        riderId: 's_1',
        riderName: 'O. Kooij',
        ftpWatts: 405,
        power5sWatts: 1560,
        sprintSkill: 93,
        bikeHandling: 89,
        raceIq: 87,
        aggression: 82,
        wPrimeTotalJoules: 24000.0,
        wPrimeRemainingJoules: 18000.0,
        currentLateralPosition: 0.1,
        currentSpeedKmh: 62.0,
      );
      final decodedSprinter = SprinterSurfProfile.fromJson(sprinter.toJson());
      expect(decodedSprinter.riderId, 's_1');
      expect(decodedSprinter.wPrimeRemainingFraction, closeTo(0.75, 1e-6));

      final zeroWPrime = sprinter.copyWith(wPrimeTotalJoules: 0.0);
      expect(zeroWPrime.wPrimeRemainingFraction, 0.0);
    });
  });

  group('SprinterTrainCounterSurfingAi — Logika Taktyczna i Fizyka', () {
    SprinterSurfProfile buildSprinter({
      int bikeHandling = 88,
      int raceIq = 86,
      double lateral = 0.0,
      double wPrimeRemaining = 22000.0,
    }) {
      return SprinterSurfProfile(
        riderId: 'sprinter_1',
        riderName: 'T. Merlier',
        ftpWatts: 400,
        power5sWatts: 1600,
        sprintSkill: 94,
        bikeHandling: bikeHandling,
        raceIq: raceIq,
        aggression: 85,
        wPrimeTotalJoules: 24000.0,
        wPrimeRemainingJoules: wPrimeRemaining,
        currentLateralPosition: lateral,
        currentSpeedKmh: 61.5,
      );
    }

    const primeTrain = RivalTrainSnapshot(
      teamId: 'team_prime',
      teamName: 'Alpecin-Deceuninck',
      targetSprinterId: 'philipsen',
      targetSprinterName: 'J. Philipsen',
      activeLeadoutRiderId: 'mvdp',
      remainingHelpers: 3,
      trainSpeedKmh: 64.5,
      lateralRoadPosition: 0.15,
      leadoutPowerWatts: 620,
      leadoutFatigueFraction: 0.18,
      wheelGapOpen: true,
      rivalWheelDefenseSkill: 76,
    );

    const fadingTrain = RivalTrainSnapshot(
      teamId: 'team_fading',
      teamName: 'Gasnący Pociąg',
      targetSprinterId: 'r_fading',
      targetSprinterName: 'A. Sprinter',
      activeLeadoutRiderId: 'lead_fading',
      remainingHelpers: 0,
      trainSpeedKmh: 58.0,
      lateralRoadPosition: -0.20,
      leadoutPowerWatts: 480,
      leadoutFatigueFraction: 0.85,
      wheelGapOpen: true,
      rivalWheelDefenseSkill: 70,
    );

    test('poza strefą 3 km pozostaje w standby, a za metą przechodzi w completed', () {
      final sprinter = buildSprinter();

      final standby = SprinterTrainCounterSurfingAi.evaluateStep(
        CounterSurfStepInput(
          sprinter: sprinter,
          rivalTrains: const [primeTrain],
          distanceToFinishMeters: 3500.0,
        ),
      );
      expect(standby.phase, CounterSurfPhase.standby);
      expect(standby.selectedTrainTeamId, isNull);
      expect(standby.targetWatts, (sprinter.ftpWatts * 0.68).round());

      final completed = SprinterTrainCounterSurfingAi.evaluateStep(
        CounterSurfStepInput(
          sprinter: sprinter,
          rivalTrains: const [primeTrain],
          distanceToFinishMeters: 0.0,
          currentTargetTeamId: primeTrain.teamId,
        ),
      );
      expect(completed.phase, CounterSurfPhase.completed);
      expect(completed.targetWatts, (sprinter.ftpWatts * 0.55).round());
    });

    test('brak pociągów rywali wewnątrz 3 km obsługuje scanningTrains oraz samotny slingshotLaunch', () {
      final sprinter = buildSprinter();

      final scanning = SprinterTrainCounterSurfingAi.evaluateStep(
        CounterSurfStepInput(
          sprinter: sprinter,
          rivalTrains: const [],
          distanceToFinishMeters: 1200.0,
        ),
      );
      expect(scanning.phase, CounterSurfPhase.scanningTrains);
      expect(scanning.isSlingshotReady, isFalse);

      final soloLaunch = SprinterTrainCounterSurfingAi.evaluateStep(
        CounterSurfStepInput(
          sprinter: sprinter,
          rivalTrains: const [],
          distanceToFinishMeters: 180.0,
        ),
      );
      expect(soloLaunch.phase, CounterSurfPhase.slingshotLaunch);
      expect(soloLaunch.isSlingshotReady, isTrue);
      expect(soloLaunch.targetWatts, sprinter.power5sWatts);
    });

    test('evaluateRivalTrains sortuje pociągi, wykrywa gasnący pociąg i premiuje osłonę wiatrową', () {
      final sprinter = buildSprinter();
      final evals = SprinterTrainCounterSurfingAi.evaluateRivalTrains(
        sprinter: sprinter,
        rivalTrains: const [fadingTrain, primeTrain],
        distanceToFinishMeters: 1500.0,
        crosswindDirection: 0.6,
        aggressionMode: CounterSurfAggression.balancedSurfer,
      );

      expect(evals.length, 2);
      expect(evals.first.train.teamId, primeTrain.teamId);
      expect(evals.first.quality, SurfTargetQuality.prime);
      expect(evals.last.train.teamId, fadingTrain.teamId);
      expect(evals.last.quality, SurfTargetQuality.fading);
      expect(evals.first.score, greaterThan(evals.last.score));
    });

    test('przeskok (Wheel Hop) następuje przy gasnącym pociągu lub ręcznym rozkazie DS', () {
      final sprinter = buildSprinter();

      final fadeHop = SprinterTrainCounterSurfingAi.evaluateStep(
        CounterSurfStepInput(
          sprinter: sprinter,
          rivalTrains: const [fadingTrain, primeTrain],
          distanceToFinishMeters: 1100.0,
          currentTargetTeamId: fadingTrain.teamId,
        ),
      );
      expect(fadeHop.didWheelHop, isTrue);
      expect(fadeHop.hopReason, WheelHopReason.leadoutFading);
      expect(fadeHop.phase, CounterSurfPhase.wheelHopping);
      expect(fadeHop.selectedTrainTeamId, primeTrain.teamId);

      final manualOrder = SprinterTrainCounterSurfingAi.evaluateStep(
        CounterSurfStepInput(
          sprinter: sprinter,
          rivalTrains: const [fadingTrain, primeTrain],
          distanceToFinishMeters: 1100.0,
          currentTargetTeamId: primeTrain.teamId,
          manualLockedTeamId: fadingTrain.teamId,
        ),
      );
      expect(manualOrder.didWheelHop, isTrue);
      expect(manualOrder.hopReason, WheelHopReason.manualDirectorOrder);
      expect(manualOrder.selectedTrainTeamId, fadingTrain.teamId);
    });

    test('zamknięcie przy barierce (Boxed In) uruchamia unik, a elitarny bikeHandling pozwala uciec', () {
      const barrierTrain = RivalTrainSnapshot(
        teamId: 'team_barrier',
        teamName: 'Barrier Team',
        targetSprinterId: 'b1',
        targetSprinterName: 'B. Rider',
        activeLeadoutRiderId: 'b_lead',
        remainingHelpers: 2,
        trainSpeedKmh: 62.5,
        lateralRoadPosition: -0.88,
        leadoutPowerWatts: 590,
        leadoutFatigueFraction: 0.3,
        wheelGapOpen: true,
        rivalWheelDefenseSkill: 75,
      );
      const blockingTrain = RivalTrainSnapshot(
        teamId: 'team_blocker',
        teamName: 'Blocker Team',
        targetSprinterId: 'b2',
        targetSprinterName: 'C. Blocker',
        activeLeadoutRiderId: 'c_lead',
        remainingHelpers: 2,
        trainSpeedKmh: 61.8,
        lateralRoadPosition: -0.70,
        leadoutPowerWatts: 580,
        leadoutFatigueFraction: 0.35,
        wheelGapOpen: false,
        rivalWheelDefenseSkill: 80,
      );

      final boxedDecision = SprinterTrainCounterSurfingAi.evaluateStep(
        CounterSurfStepInput(
          sprinter: buildSprinter(bikeHandling: 78, raceIq: 75, lateral: -0.88),
          rivalTrains: const [barrierTrain, blockingTrain],
          distanceToFinishMeters: 900.0,
          currentTargetTeamId: barrierTrain.teamId,
        ),
      );
      expect(boxedDecision.isBoxedIn, isTrue);
      expect(boxedDecision.phase, CounterSurfPhase.boxedInRecovery);
      expect(boxedDecision.targetLateralPosition, greaterThan(-0.88));

      final escapedDecision = SprinterTrainCounterSurfingAi.evaluateStep(
        CounterSurfStepInput(
          sprinter: buildSprinter(bikeHandling: 92, raceIq: 88, lateral: -0.88),
          rivalTrains: const [barrierTrain, blockingTrain],
          distanceToFinishMeters: 900.0,
          currentTargetTeamId: barrierTrain.teamId,
        ),
      );
      expect(escapedDecision.isBoxedIn, isFalse);
      expect(escapedDecision.phase, isNot(CounterSurfPhase.boxedInRecovery));
    });

    test('okno Slingshot (<220 m) odpala procę z koła i zużywa W\' bez NaN', () {
      final sprinter = buildSprinter(lateral: 0.14, wPrimeRemaining: 20000.0);
      final launch = SprinterTrainCounterSurfingAi.evaluateStep(
        CounterSurfStepInput(
          sprinter: sprinter,
          rivalTrains: const [primeTrain],
          distanceToFinishMeters: 180.0,
          currentTargetTeamId: primeTrain.teamId,
          timeStepSeconds: 2.0,
        ),
      );

      expect(launch.phase, CounterSurfPhase.slingshotLaunch);
      expect(launch.isSlingshotReady, isTrue);
      expect(launch.targetWatts, greaterThanOrEqualTo(850));
      expect(launch.wPrimeDeltaJoules, lessThan(0.0));
      expect(launch.newWPrimeRemainingJoules, lessThan(20000.0));
      expect(launch.newWPrimeRemainingJoules, greaterThanOrEqualTo(0.0));
    });

    test('simulateFinalApproach przeprowadza pełny finisz od 2400 m do mety bez NaN', () {
      final history = SprinterTrainCounterSurfingAi.simulateFinalApproach(
        initialSprinter: buildSprinter(),
        rivalTrains: const [primeTrain, fadingTrain],
        startDistanceMeters: 2400.0,
        timeStepSeconds: 2.0,
      );

      expect(history, isNotEmpty);
      expect(
        history.any((d) => d.phase == CounterSurfPhase.slingshotLaunch),
        isTrue,
      );
      for (final step in history) {
        expect(step.targetWatts.isFinite, isTrue);
        expect(step.targetLateralPosition.isFinite, isTrue);
        expect(step.newWPrimeRemainingJoules.isNaN, isFalse);
        expect(step.wheelBattleScore.isNaN, isFalse);
      }
    });
  });

  group('SprinterTrainCounterSurfingPanel — Responsywność UI', () {
    Future<void> pumpSurfingPanelAtSize(
      WidgetTester tester,
      Size size,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SprinterTrainCounterSurfingPanel(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się poprawnie bez przepełnień w ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await pumpSurfingPanelAtSize(tester, size);
          expect(tester.takeException(), isNull);
          expect(find.byType(SprinterTrainCounterSurfingPanel), findsOneWidget);
        },
      );
    }
  });

  group('QuickTacticalMacroManager — Logika i Serializacja Makr', () {
    test('Enumy makr obsługują fromJson oraz właściwości UI', () {
      expect(
        TacticalMacroCategory.fromJson('sprintLeadout'),
        TacticalMacroCategory.sprintLeadout,
      );
      expect(
        TacticalMacroCategory.fromJson('unknown'),
        TacticalMacroCategory.custom,
      );
      expect(
        MacroTriggerCondition.fromJson('onClimbStart'),
        MacroTriggerCondition.onClimbStart,
      );
      expect(
        MacroTriggerCondition.fromJson('invalid'),
        MacroTriggerCondition.immediate,
      );
      expect(MacroTargetScope.labelFor(MacroTargetScope.allTeam, null), 'Cała drużyna');
      expect(MacroTargetScope.labelFor(MacroTargetScope.leadersOnly, null), 'Liderzy');
      expect(MacroTargetScope.labelFor(MacroTargetScope.domestiquesOnly, null), 'Pomocnicy');
      expect(MacroTargetScope.labelFor('r_1', 'T. Pogačar'), 'T. Pogačar');
    });

    test('exportMacrosToJson i importMacrosFromJson wykonują pełny round-trip i walidują tablicę', () {
      final defaults = QuickTacticalMacroManager.defaultTeamMacros();
      expect(defaults.length, 4);

      final exported = QuickTacticalMacroManager.exportMacrosToJson(defaults);
      final imported = QuickTacticalMacroManager.importMacrosFromJson(exported);
      expect(imported.length, defaults.length);
      expect(imported.first.id, defaults.first.id);
      expect(imported.first.steps.length, defaults.first.steps.length);
      expect(imported.first.totalDurationMs, defaults.first.totalDurationMs);
      expect(imported.first.affectedTargets, defaults.first.affectedTargets);

      expect(
        () => QuickTacticalMacroManager.importMacrosFromJson('{"invalid": true}'),
        throwsFormatException,
      );
    });

    test('TacticalMacroStep.fromJson ogranicza targetEffortPercent do [50, 120]', () {
      final low = TacticalMacroStep.fromJson(const {
        'id': 's_low',
        'targetEffortPercent': 10.0,
      });
      final high = TacticalMacroStep.fromJson(const {
        'id': 's_high',
        'targetEffortPercent': 250.0,
      });
      expect(low.targetEffortPercent, 50.0);
      expect(high.targetEffortPercent, 120.0);
    });

    test('countAffectedRiders poprawnie zlicza aktywnych liderów, pomocników i cały skład', () {
      const roster = [
        MacroTeamRiderSlot(
          id: 'r1',
          name: 'Lider',
          bibNumber: 1,
          roleLabel: 'GC',
          isLeader: true,
          isActive: true,
        ),
        MacroTeamRiderSlot(
          id: 'r2',
          name: 'Pomocnik Aktywny',
          bibNumber: 2,
          roleLabel: 'Dom',
          isLeader: false,
          isActive: true,
        ),
        MacroTeamRiderSlot(
          id: 'r3',
          name: 'Pomocnik Wycofany',
          bibNumber: 3,
          roleLabel: 'Dom',
          isLeader: false,
          isActive: false,
        ),
      ];

      final allMacro = QuickTacticalMacro(
        id: 'm_all',
        name: 'All',
        category: TacticalMacroCategory.custom,
        createdAt: DateTime(2026),
        steps: const [
          TacticalMacroStep(
            id: '1',
            stepIndex: 0,
            targetId: MacroTargetScope.allTeam,
            targetLabel: 'Cała drużyna',
            order: TacticalOrder.pullGroup,
            targetEffortPercent: 90,
          ),
        ],
      );
      expect(QuickTacticalMacroManager.countAffectedRiders(allMacro, roster), 2);

      final leadersMacro = allMacro.copyWith(
        steps: const [
          TacticalMacroStep(
            id: '2',
            stepIndex: 0,
            targetId: MacroTargetScope.leadersOnly,
            targetLabel: 'Liderzy',
            order: TacticalOrder.attack,
            targetEffortPercent: 110,
          ),
        ],
      );
      expect(QuickTacticalMacroManager.countAffectedRiders(leadersMacro, roster), 1);

      final inactiveSingleMacro = allMacro.copyWith(
        steps: const [
          TacticalMacroStep(
            id: '3',
            stepIndex: 0,
            targetId: 'r3',
            targetLabel: 'Pomocnik Wycofany',
            order: TacticalOrder.saveEnergy,
            targetEffortPercent: 60,
          ),
        ],
      );
      expect(
        QuickTacticalMacroManager.countAffectedRiders(inactiveSingleMacro, roster),
        0,
      );
    });

    test('validateMacro odrzuca puste nazwy, zbyt długie nazwy oraz brak kroków', () {
      const dummyStep = TacticalMacroStep(
        id: 's1',
        stepIndex: 0,
        targetId: MacroTargetScope.allTeam,
        targetLabel: 'Cała drużyna',
        order: TacticalOrder.pullGroup,
        targetEffortPercent: 95,
      );

      expect(
        QuickTacticalMacroManager.validateMacro(name: '   ', steps: const [dummyStep]),
        isNotNull,
      );
      expect(
        QuickTacticalMacroManager.validateMacro(
          name: 'A' * 49,
          steps: const [dummyStep],
        ),
        isNotNull,
      );
      expect(
        QuickTacticalMacroManager.validateMacro(name: 'Poprawne Makro', steps: const []),
        isNotNull,
      );
      expect(
        QuickTacticalMacroManager.validateMacro(
          name: 'Poprawne Makro',
          steps: const [dummyStep],
        ),
        isNull,
      );
    });
  });

  group('QuickTacticalMacroRecorderWidget — Responsywność i Interakcje UI', () {
    Future<void> pumpRecorderAtSize(
      WidgetTester tester,
      Size size, {
      bool enabled = true,
      ValueChanged<MacroExecutionResult>? onExecuteMacro,
      ValueChanged<TacticalMacroStep>? onApplyStep,
      ValueChanged<List<QuickTacticalMacro>>? onMacrosChanged,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickTacticalMacroRecorderWidget(
              roster: QuickTacticalMacroManager.defaultRoster(),
              enabled: enabled,
              onExecuteMacro: onExecuteMacro,
              onApplyStep: onApplyStep,
              onMacrosChanged: onMacrosChanged,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnień w ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await pumpRecorderAtSize(tester, size);
          expect(tester.takeException(), isNull);
          expect(find.text('Pociąg Sprinterski 3 km'), findsOneWidget);
          expect(find.text('Nagraj Makro'), findsOneWidget);
        },
      );
    }

    testWidgets('1-klikowe uruchomienie makra wyzwala callbacki i obsługuje timer odtwarzania', (tester) async {
      MacroExecutionResult? executedResult;
      final appliedSteps = <TacticalMacroStep>[];

      await pumpRecorderAtSize(
        tester,
        const Size(1280, 800),
        onExecuteMacro: (res) => executedResult = res,
        onApplyStep: appliedSteps.add,
      );

      await tester.tap(find.text('Odpal').first);
      await tester.pump(const Duration(milliseconds: 300));
      // Przewinięcie czasu aż do zakończenia timera playback (3 kroki * 280 ms)
      await tester.pump(const Duration(milliseconds: 900));

      expect(executedResult, isNotNull);
      expect(executedResult!.macro.id, 'macro_sprint_3km');
      expect(executedResult!.affectedRidersCount, 6);
      expect(appliedSteps.length, 3);
    });

    testWidgets('nagrywanie, przechwycenie kroku i zapis nowego makra aktualizuje listę', (tester) async {
      List<QuickTacticalMacro>? updatedMacros;

      await pumpRecorderAtSize(
        tester,
        const Size(1280, 800),
        onMacrosChanged: (list) => updatedMacros = list,
      );

      await tester.tap(find.text('Nagraj Makro'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text(TacticalOrder.attack.label).last);
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(
        find.byType(TextField).first,
        'Finiszowy Kontratak',
      );
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Zapisz Makro'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(updatedMacros, isNotNull);
      expect(updatedMacros!.first.name, 'Finiszowy Kontratak');
      expect(updatedMacros!.first.steps.length, 1);
    });

    testWidgets('tryb disabled blokuje uruchomienie makra i nagrywanie', (tester) async {
      MacroExecutionResult? executedResult;

      await pumpRecorderAtSize(
        tester,
        const Size(1280, 800),
        enabled: false,
        onExecuteMacro: (res) => executedResult = res,
      );

      await tester.tap(find.text('Odpal').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(executedResult, isNull);
    });
  });
}
