import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/nature_break_and_peloton_etiquette_engine.dart';

void main() {
  late NatureBreakAndPelotonEtiquetteEngine engine;

  setUp(() {
    engine = NatureBreakAndPelotonEtiquetteEngine();
  });

  PelotonEtiquetteStageContext openRoadContext({
    double distanceCompletedKm = 75.0,
    double totalStageDistanceKm = 180.0,
    double currentGradientPercent = 0.5,
    double crosswindIntensityKmh = 10.0,
    bool isBreakawayEstablished = true,
    bool isInFeedZone = false,
    bool isFinalClimbActive = false,
    bool raceLeaderCrashed = false,
    double raceLeaderGapSeconds = 0.0,
  }) {
    return PelotonEtiquetteStageContext(
      distanceCompletedKm: distanceCompletedKm,
      totalStageDistanceKm: totalStageDistanceKm,
      currentGradientPercent: currentGradientPercent,
      crosswindIntensityKmh: crosswindIntensityKmh,
      isBreakawayEstablished: isBreakawayEstablished,
      isInFeedZone: isInFeedZone,
      isFinalClimbActive: isFinalClimbActive,
      raceLeaderId: 'pog_1',
      raceLeaderName: 'T. Lider',
      raceLeaderTeamId: 'team_uae',
      raceLeaderCrashed: raceLeaderCrashed,
      raceLeaderGapSeconds: raceLeaderGapSeconds,
      patronRiderName: 'L. Patron',
    );
  }

  group('NatureBreakAndPelotonEtiquetteEngine - Nature Break', () {
    test('accepts Nature Break on calm open road and completes lifecycle', () {
      const initial = PelotonEtiquetteState();
      final context = openRoadContext();

      final started = engine.startNatureBreak(
        currentState: initial,
        context: context,
        teamId: 'team_player',
        riderName: 'M. Kwiatkowski',
        durationSeconds: 120.0,
        totalPelotonRiders: 150,
      );

      expect(started.mode, PelotonEtiquetteMode.natureBreakActive);
      expect(started.areAttacksSuspended, isTrue);
      expect(started.natureBreak, isNotNull);
      expect(started.natureBreak!.isActive, isTrue);

      final mods = engine.computeModifiers(started);
      expect(mods.attacksSuspended, isTrue);
      expect(mods.pelotonFtpCapRatio, closeTo(0.48, 0.01));

      final midStep = engine.step(
        currentState: started,
        context: context,
        deltaSeconds: 60.0,
      );
      expect(midStep.mode, PelotonEtiquetteMode.natureBreakActive);
      expect(midStep.natureBreak!.progress, closeTo(0.5, 0.01));

      final finished = engine.step(
        currentState: midStep,
        context: context,
        deltaSeconds: 65.0,
      );
      expect(finished.mode, PelotonEtiquetteMode.normalRacing);
      expect(finished.natureBreak, isNull);
      expect(finished.natureBreaksCompletedThisStage, 1);
    });

    test('rejects Nature Break in crosswind, steep climb, or final 35 km', () {
      const initial = PelotonEtiquetteState();

      final windy = engine.requestNatureBreak(
        currentState: initial,
        context: openRoadContext(crosswindIntensityKmh: 30.0),
        teamId: 'team_player',
        riderName: 'Rider A',
      );
      expect(windy.accepted, isFalse);

      final climb = engine.requestNatureBreak(
        currentState: initial,
        context: openRoadContext(currentGradientPercent: 6.5),
        teamId: 'team_player',
        riderName: 'Rider A',
      );
      expect(climb.accepted, isFalse);

      final finale = engine.requestNatureBreak(
        currentState: initial,
        context: openRoadContext(distanceCompletedKm: 155.0),
        teamId: 'team_player',
        riderName: 'Rider A',
      );
      expect(finale.accepted, isFalse);
    });
  });

  group('NatureBreakAndPelotonEtiquetteEngine - Leader Crash Ceasefire', () {
    test('suspends attacks on leader crash outside final 25 km and ends on rejoin', () {
      const initial = PelotonEtiquetteState();
      final crashContext = openRoadContext(
        distanceCompletedKm: 110.0,
        raceLeaderCrashed: true,
        raceLeaderGapSeconds: 40.0,
      );

      final neutralized = engine.triggerLeaderCrashNeutralization(
        currentState: initial,
        context: crashContext,
        initialGapSeconds: 40.0,
      );

      expect(
        neutralized.mode,
        PelotonEtiquetteMode.leaderCrashNeutralization,
      );
      expect(neutralized.areAttacksSuspended, isTrue);
      expect(neutralized.crashNeutralization?.currentGapSeconds, 40.0);

      final afterWait = engine.step(
        currentState: neutralized,
        context: openRoadContext(
          distanceCompletedKm: 112.0,
          raceLeaderCrashed: false,
          raceLeaderGapSeconds: 0.0,
        ),
        deltaSeconds: 120.0,
      );

      expect(afterWait.mode, PelotonEtiquetteMode.normalRacing);
      expect(afterWait.crashNeutralization, isNull);
    });

    test('does not suspend attacks when leader crashes inside final 25 km', () {
      const initial = PelotonEtiquetteState();
      final redZoneCrash = openRoadContext(
        distanceCompletedKm: 162.0,
        totalStageDistanceKm: 180.0,
        raceLeaderCrashed: true,
        raceLeaderGapSeconds: 35.0,
      );

      final result = engine.triggerLeaderCrashNeutralization(
        currentState: initial,
        context: redZoneCrash,
      );

      expect(result.mode, PelotonEtiquetteMode.normalRacing);
      expect(result.crashNeutralization, isNull);
    });
  });

  group('NatureBreakAndPelotonEtiquetteEngine - Violations, Fair Play & JSON', () {
    test('penalizes attack during crash ceasefire and rewards honoring truce', () {
      const initial = PelotonEtiquetteState(playerRespectScore: 70.0);
      final context = openRoadContext(distanceCompletedKm: 95.0);

      final truce = engine.triggerLeaderCrashNeutralization(
        currentState: initial,
        context: context,
        initialGapSeconds: 35.0,
      );

      final honored = engine.honorNeutralization(
        currentState: truce,
        context: context,
        teamId: 'team_player',
      );
      expect(honored.playerRespectScore, closeTo(74.0, 0.01));

      final breached = engine.reportAttackAttempt(
        currentState: honored,
        context: context,
        attackingTeamId: 'team_player',
        attackingRiderName: 'K. Oportunista',
      );
      expect(breached.mode, PelotonEtiquetteMode.etiquetteBreachPursuit);
      expect(breached.playerRespectScore, closeTo(46.0, 0.01));

      final mods = engine.computeModifiers(breached);
      expect(mods.pelotonChaseBoostMultiplier, closeTo(1.40, 0.01));
    });

    test('serializes and deserializes PelotonEtiquetteState cleanly', () {
      final state = engine.startNatureBreak(
        currentState: const PelotonEtiquetteState(playerRespectScore: 82.0),
        context: openRoadContext(),
        teamId: 'team_player',
        riderName: 'M. Kwiatkowski',
      );

      final restored = PelotonEtiquetteState.fromJson(state.toJson());
      expect(restored.mode, state.mode);
      expect(restored.playerRespectScore, state.playerRespectScore);
      expect(
        restored.natureBreak?.initiatedByRiderName,
        state.natureBreak?.initiatedByRiderName,
      );
      expect(restored.eventLog.length, state.eventLog.length);
    });
  });

  group('NatureBreakAndPelotonEtiquettePanel - Responsive UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders without overflow at ${size.width}x${size.height}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final context = openRoadContext();
        final state = engine.startNatureBreak(
          currentState: const PelotonEtiquetteState(playerRespectScore: 75.0),
          context: context,
          teamId: 'team_player',
          riderName: 'R. Majka',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: NatureBreakAndPelotonEtiquettePanel(
                  state: state,
                  stageContext: context,
                  onRequestNatureBreak: () {},
                  onSimulateLeaderCrash: () {},
                  onHonorNeutralization: () {},
                  onAttackDuringTruce: () {},
                  onAdvanceStep: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Etykieta Peletonu & Nature Break'), findsOneWidget);
        expect(find.text('Ogłoś Nature Break'), findsOneWidget);
        expect(find.text('Szanuj Rozejm (Fair Play)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
