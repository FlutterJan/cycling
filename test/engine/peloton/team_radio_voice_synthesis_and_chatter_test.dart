import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/team_radio_voice_synthesis_and_chatter.dart';

void main() {
  group('TeamRadioVoiceSynthesisAndChatterEngine', () {
    const engine = TeamRadioVoiceSynthesisAndChatterEngine();

    test('detects attack initiative when rider has high W\', good day form and climb', () {
      const ctx = RiderRadioChatterContext(
        riderId: 'r_pog',
        riderName: 'Tadej Novak',
        teamName: 'UAE Team',
        wPrimePercent: 88.0,
        dayFormDelta: 3,
        morale: 90.0,
        gradientPercent: 7.5,
        distanceToFinishKm: 18.0,
        elapsedSeconds: 7200.0,
        kilometerMark: 162.4,
      );

      final event = engine.evaluateContext(ctx);
      expect(event, isNotNull);
      expect(event!.scenario, RadioChatterScenario.attackInitiative);
      expect(event.requiresDecision, isTrue);
      expect(event.options.length, 2);
      expect(event.voiceProfile.waveformBars.length, 24);
    });

    test('enforces scenario cooldown unless forceTrigger is true', () {
      const ctx = RiderRadioChatterContext(
        riderId: 'r_1',
        riderName: 'Jan Kowalski',
        teamName: 'Bora',
        hasPuncture: true,
        elapsedSeconds: 1000.0,
      );

      final first = engine.evaluateContext(ctx);
      expect(first, isNotNull);
      expect(first!.scenario, RadioChatterScenario.mechanicalOrPuncture);

      final blocked = engine.evaluateContext(
        ctx,
        lastTriggeredAt: {RadioChatterScenario.mechanicalOrPuncture: 950.0},
      );
      expect(blocked, isNull);

      final forced = engine.evaluateContext(
        ctx,
        lastTriggeredAt: {RadioChatterScenario.mechanicalOrPuncture: 950.0},
        forceTrigger: true,
      );
      expect(forced, isNotNull);
    });

    test('synthesizes valid stereo PCM audio cue and round-trips JSON', () {
      const ctx = RiderRadioChatterContext(
        riderId: 'r_2',
        riderName: 'Jonas Berg',
        teamName: 'Visma',
        crosswindKmh: 36.0,
        elapsedSeconds: 3600.0,
        language: 'en',
      );

      final event = engine.evaluateContext(ctx);
      expect(event, isNotNull);
      expect(event!.scenario, RadioChatterScenario.crosswindAlert);

      final buffer = engine.synthesizeChatterAudioCue(event);
      expect(buffer.frameCount, greaterThan(1000));
      expect(buffer.left.every((s) => s >= -1.0 && s <= 1.0), isTrue);

      final restored = TeamRadioChatterEvent.fromJson(event.toJson());
      expect(restored.id, event.id);
      expect(restored.scenario, event.scenario);
      expect(restored.dialogueText, event.dialogueText);
      expect(restored.options.length, event.options.length);
    });
  });

  group('TeamRadioChatterNotifier & TeamRadioChatterConsolePanel', () {
    test('notifier processes context and resolves initiative', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(teamRadioChatterProvider.notifier);
      final event = notifier.processRiderContext(
        const RiderRadioChatterContext(
          riderId: 'r_lead',
          riderName: 'Michał Nowak',
          teamName: 'Polska Pro',
          dayFormDelta: -3,
          gradientPercent: 8.0,
          wPrimePercent: 35.0,
          elapsedSeconds: 4500.0,
        ),
      );

      expect(event, isNotNull);
      expect(container.read(teamRadioChatterProvider).activeInitiative, isNotNull);

      final optionId = event!.options.first.id;
      final res = notifier.decideActiveInitiative(optionId, currentElapsedSeconds: 4510.0);
      expect(res, isNotNull);
      expect(container.read(teamRadioChatterProvider).activeInitiative, isNull);
      expect(container.read(teamRadioChatterProvider).totalDecisionsMade, 1);
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders responsively without overflow at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(teamRadioChatterProvider.notifier).processRiderContext(
              const RiderRadioChatterContext(
                riderId: 'r_ui',
                riderName: 'Rafał Majka',
                teamName: 'UAE',
                dayFormDelta: 3,
                morale: 88.0,
                wPrimePercent: 85.0,
                gradientPercent: 6.8,
                distanceToFinishKm: 20.0,
                elapsedSeconds: 6100.0,
              ),
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: TeamRadioChatterConsolePanel(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Radio Wyścigowe — Inicjatywy Kolarzy'), findsOneWidget);
        expect(find.textContaining('Rafał Majka'), findsWidgets);

        await tester.tap(find.text('Zgoda — Atakuj teraz!'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(container.read(teamRadioChatterProvider).activeInitiative, isNull);
        expect(container.read(teamRadioChatterProvider).totalDecisionsMade, 1);
      });
    }
  });
}
