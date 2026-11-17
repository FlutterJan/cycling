import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/team_time_trial_rider_drop_strategy.dart';

List<TttDropStrategyRiderProfile> _buildSampleRoster({int count = 6}) {
  final all = <TttDropStrategyRiderProfile>[
    const TttDropStrategyRiderProfile(
      riderId: 'r1',
      riderName: 'Lider GC',
      ftpWatts: 410,
      wPrimeTotalJoules: 22000,
      wPrimeRemainingJoules: 19000,
      timeTrialSkill: 88,
      isGcLeader: true,
    ),
    const TttDropStrategyRiderProfile(
      riderId: 'r2',
      riderName: 'Silnik TT #1',
      ftpWatts: 435,
      wPrimeTotalJoules: 24000,
      wPrimeRemainingJoules: 21000,
      timeTrialSkill: 91,
      isDesignatedPacelineCaptain: true,
    ),
    const TttDropStrategyRiderProfile(
      riderId: 'r3',
      riderName: 'Silnik TT #2',
      ftpWatts: 420,
      wPrimeTotalJoules: 23000,
      wPrimeRemainingJoules: 20000,
      timeTrialSkill: 85,
    ),
    const TttDropStrategyRiderProfile(
      riderId: 'r4',
      riderName: 'Pomocnik Czasowy',
      ftpWatts: 412,
      wPrimeTotalJoules: 21000,
      wPrimeRemainingJoules: 18500,
      timeTrialSkill: 83,
    ),
    const TttDropStrategyRiderProfile(
      riderId: 'r5',
      riderName: 'Domestique Kamikaze',
      ftpWatts: 355,
      wPrimeTotalJoules: 24000,
      wPrimeRemainingJoules: 22000,
      timeTrialSkill: 70,
      fatigueFraction: 0.35,
    ),
    const TttDropStrategyRiderProfile(
      riderId: 'r6',
      riderName: 'Wyczerpany Pomocnik',
      ftpWatts: 345,
      wPrimeTotalJoules: 18000,
      wPrimeRemainingJoules: 1500,
      timeTrialSkill: 68,
    ),
  ];
  return all.take(count).toList();
}

void main() {
  group('TeamTimeTrialRiderDropStrategy', () {
    test('wybiera optymalnego kandydata i chroni lidera GC oraz silnik TT', () {
      final input = KamikazePullDropInput(
        riders: _buildSampleRoster(count: 6),
        distanceRemainingKm: 4.5,
        totalStageDistanceKm: 28.0,
        currentTrainSpeedKmh: 50.0,
        intensity: KamikazePullIntensity.classicKamikaze,
        safetyMode: TttCountingSafetyMode.fiveRiderBuffer,
      );

      final plan = TeamTimeTrialRiderDropStrategy.evaluatePlan(input);

      expect(plan.canExecuteSafely, isTrue);
      expect(plan.activeRidersCount, 6);
      expect(plan.minRequiredFinishers, 5);
      expect(plan.recommendedCandidate, isNotNull);
      expect(plan.recommendedCandidate!.riderId, 'r5');
      expect(plan.projectedPacelineSpeedKmh, greaterThan(50.0));
      expect(plan.projectedTeamTimeGainSeconds, greaterThan(0.0));
      expect(plan.triggerWindowScore, greaterThan(70.0));

      final leaderEval =
          plan.allEvaluations.firstWhere((e) => e.riderId == 'r1');
      expect(leaderEval.verdict, KamikazeCandidateVerdict.protectedGcLeader);

      final captainEval =
          plan.allEvaluations.firstWhere((e) => e.riderId == 'r2');
      expect(
        captainEval.verdict,
        KamikazeCandidateVerdict.protectedCoreTtEngine,
      );

      final exhaustedEval =
          plan.allEvaluations.firstWhere((e) => e.riderId == 'r6');
      expect(
        exhaustedEval.verdict,
        KamikazeCandidateVerdict.insufficientWPrime,
      );
    });

    test('blokuje manewr gdy liczba aktywnych kolarzy osiąga limit UCI/bufor', () {
      final inputBuffer = KamikazePullDropInput(
        riders: _buildSampleRoster(count: 5),
        distanceRemainingKm: 4.0,
        totalStageDistanceKm: 25.0,
        currentTrainSpeedKmh: 52.0,
        safetyMode: TttCountingSafetyMode.fiveRiderBuffer,
      );

      final planBuffer =
          TeamTimeTrialRiderDropStrategy.evaluatePlan(inputBuffer);
      expect(planBuffer.canExecuteSafely, isFalse);
      expect(planBuffer.recommendedCandidate, isNull);

      final abortedState = TeamTimeTrialRiderDropStrategy.initiateKamikazePull(
        currentState: const KamikazePullDropExecutionState(),
        input: inputBuffer,
        candidateRiderId: 'r5',
      );
      expect(abortedState.phase, KamikazePullDropPhase.abortedSafetyGuard);

      // Z trybem uciMinimumFour przy 5 kolarzach manewr jest dozwolony.
      final inputUci4 = KamikazePullDropInput(
        riders: _buildSampleRoster(count: 5),
        distanceRemainingKm: 4.0,
        totalStageDistanceKm: 25.0,
        currentTrainSpeedKmh: 50.0,
        safetyMode: TttCountingSafetyMode.uciMinimumFour,
      );
      final planUci4 = TeamTimeTrialRiderDropStrategy.evaluatePlan(inputUci4);
      expect(planUci4.canExecuteSafely, isTrue);
      expect(planUci4.recommendedCandidate?.riderId, 'r5');
    });

    test('przechodzi pełną maszynę stanów aż do przegrupowania pociągu', () {
      final input = KamikazePullDropInput(
        riders: _buildSampleRoster(count: 6),
        distanceRemainingKm: 5.0,
        totalStageDistanceKm: 30.0,
        currentTrainSpeedKmh: 51.5,
        intensity: KamikazePullIntensity.allOutNuclear,
        safetyMode: TttCountingSafetyMode.fiveRiderBuffer,
      );

      var state = TeamTimeTrialRiderDropStrategy.initiateKamikazePull(
        currentState: const KamikazePullDropExecutionState(
          activeRidersRemaining: 6,
          currentTrainSpeedKmh: 51.5,
        ),
        input: input,
        candidateRiderId: 'r5',
      );

      expect(state.phase, KamikazePullDropPhase.kamikazePullActive);
      expect(state.activeKamikazeRiderId, 'r5');
      expect(state.pullTargetWatts, closeTo(355.0 * 1.38, 0.1));

      // Symulujemy kroki aż do wyczerpania W' lub osiągnięcia maksymalnego czasu zmiany.
      for (int i = 0; i < 60; i++) {
        if (state.phase != KamikazePullDropPhase.kamikazePullActive) break;
        state = TeamTimeTrialRiderDropStrategy.stepExecution(
          state: state,
          input: input,
          dtSeconds: 2.0,
        );
      }

      expect(state.phase, KamikazePullDropPhase.swingOffAndDrop);
      expect(state.activeRidersRemaining, 5);
      expect(state.droppedByKamikazeCount, 1);
      expect(state.droppedRiderIds, contains('r5'));
      expect(state.cumulativeTimeGainedSeconds, greaterThan(0.0));

      state = TeamTimeTrialRiderDropStrategy.regroupPaceline(state: state);
      expect(state.phase, KamikazePullDropPhase.pacelineRegrouped);
    });

    test('serializacja JSON profilu i enumów działa poprawnie', () {
      final profile = _buildSampleRoster(count: 1).first;
      final restored =
          TttDropStrategyRiderProfile.fromJson(profile.toJson());
      expect(restored.riderId, profile.riderId);
      expect(restored.riderName, profile.riderName);
      expect(restored.ftpWatts, profile.ftpWatts);
      expect(restored.isGcLeader, profile.isGcLeader);

      expect(
        KamikazePullDropPhase.fromJson(
          KamikazePullDropPhase.kamikazePullActive.toJson(),
        ),
        KamikazePullDropPhase.kamikazePullActive,
      );
      expect(
        KamikazePullIntensity.fromJson(
          KamikazePullIntensity.allOutNuclear.toJson(),
        ),
        KamikazePullIntensity.allOutNuclear,
      );
      expect(
        TttCountingSafetyMode.fromJson(
          TttCountingSafetyMode.uciMinimumFour.toJson(),
        ),
        TttCountingSafetyMode.uciMinimumFour,
      );
    });
  });

  group('KamikazePullDropStrategyPanel responsiveness & interaction', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnień w rozdzielczości ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final input = KamikazePullDropInput(
            riders: _buildSampleRoster(count: 6),
            distanceRemainingKm: 4.5,
            totalStageDistanceKm: 28.0,
            currentTrainSpeedKmh: 53.0,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: KamikazePullDropStrategyPanel(initialInput: input),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('TTT: Kamikaze Pull & Drop'), findsOneWidget);
          expect(find.text('Odpal Kamikaze Pull'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Kliknięcie odpalenia manewru i weryfikacja aktualizacji fazy.
          await tester.tap(find.text('Odpal Kamikaze Pull'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('Kamikaze Pull'), findsOneWidget);

          await tester.tap(find.text('Zjazd & Drop'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('Przegrupuj Pociąg'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
