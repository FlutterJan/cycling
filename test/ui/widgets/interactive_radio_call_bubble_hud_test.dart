// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/peloton/team_radio_voice_synthesis_and_chatter.dart';
import 'package:pro_peloton_manager/ui/widgets/interactive_radio_call_bubble_hud.dart';

TeamRadioChatterEvent _buildSampleEvent({
  bool requiresDecision = true,
  List<RadioInitiativeOption>? options,
  String? selectedOptionId,
  double? decisionExpiresAtSeconds = 5460.0,
}) {
  return TeamRadioChatterEvent(
    id: 'radio_evt_527',
    riderId: 'rider_1',
    riderName: 'Michał Kwiatkowski',
    teamName: 'INEOS Grenadiers',
    scenario: RadioChatterScenario.attackInitiative,
    urgency: RadioChatterUrgency.high,
    tone: RadioVoiceTone.urgent,
    headline: 'Okazja do kontrataku na podjeździe!',
    dialogueText: 'Peleton zwalnia przed szczytem, mam świeże nogi i 15 sekund luki.',
    dsPromptQuestion: 'Czy mamy ruszać teraz na pełny gaz?',
    requiresDecision: requiresDecision,
    decisionExpiresAtSeconds: decisionExpiresAtSeconds,
    options: options ??
        const [
          RadioInitiativeOption(
            id: 'opt_attack',
            decisionType: RadioInitiativeDecisionType.approveInitiative,
            label: 'Atakuj teraz!',
            dsResponseText: 'Jedziesz! Pełny gaz przez szczyt.',
            tacticalSummary: 'Natychmiastowy skok (+12% W/kg)',
            moraleDelta: 6,
            staminaCostHint: 'Wysoki koszt W\'',
            isRecommended: true,
          ),
          RadioInitiativeOption(
            id: 'opt_hold',
            decisionType: RadioInitiativeDecisionType.holdPosition,
            label: 'Trzymaj koło',
            dsResponseText: 'Spokojnie, zostań w grupie faworytów.',
            tacticalSummary: 'Oszczędzanie energii przed finałem',
            moraleDelta: 0,
            staminaCostHint: 'Niski koszt',
          ),
        ],
    selectedOptionId: selectedOptionId,
    voiceProfile: const VoiceSynthesisProfile(
      riderId: 'rider_1',
      pitchHz: 142.0,
      speechRateMultiplier: 1.15,
      breathiness: 0.42,
      rfStaticLevel: 0.18,
      waveformBars: [0.3, 0.7, 0.9, 0.5, 0.85, 0.6, 0.4, 0.75, 0.65, 0.35],
    ),
    kilometerMark: 142.5,
    elapsedSeconds: 5400.0,
  );
}

Widget _wrapWithApp(Widget child, {Size size = const Size(1024, 768)}) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(
        body: Align(
          alignment: Alignment.bottomLeft,
          child: SizedBox(
            width: size.width,
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('InteractiveRadioCallBubbleHud', () {
    testWidgets('renders nothing when event is null', (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          const InteractiveRadioCallBubbleHud(event: null),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Michał Kwiatkowski'), findsNothing);
      expect(find.byType(InteractiveRadioCallBubbleHud), findsOneWidget);
    });

    testWidgets('renders cleanly across 390x844, 1024x768 and 1600x900 without overflow',
        (tester) async {
      final event = _buildSampleEvent();
      final viewports = <Size>[
        const Size(390, 844),
        const Size(1024, 768),
        const Size(1600, 900),
      ];

      for (final viewport in viewports) {
        await tester.binding.setSurfaceSize(viewport);
        await tester.pumpWidget(
          _wrapWithApp(
            InteractiveRadioCallBubbleHud(
              event: event,
              currentElapsedSeconds: 5415.0,
              onDecisionSelected: (_) {},
              onDismiss: () {},
              onToggleMute: () {},
            ),
            size: viewport,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Michał Kwiatkowski'), findsOneWidget);
        expect(find.text('Atakuj teraz!'), findsOneWidget);
        expect(find.text('Trzymaj koło'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('triggers decision, mute and dismiss callbacks', (tester) async {
      RadioInitiativeOption? chosen;
      bool dismissed = false;
      bool toggledMute = false;

      await tester.pumpWidget(
        _wrapWithApp(
          InteractiveRadioCallBubbleHud(
            event: _buildSampleEvent(),
            currentElapsedSeconds: 5410.0,
            onDecisionSelected: (opt) => chosen = opt,
            onDismiss: () => dismissed = true,
            onToggleMute: () => toggledMute = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pump(const Duration(milliseconds: 100));
      expect(toggledMute, isTrue);

      await tester.tap(find.text('Atakuj teraz!'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(chosen?.id, equals('opt_attack'));

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 100));
      expect(dismissed, isTrue);
    });

    testWidgets('respects disabled state and hover interactions', (tester) async {
      RadioInitiativeOption? chosen;

      await tester.pumpWidget(
        _wrapWithApp(
          InteractiveRadioCallBubbleHud(
            event: _buildSampleEvent(),
            isDisabled: true,
            onDecisionSelected: (opt) => chosen = opt,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.text('Atakuj teraz!')));
      await tester.pump(const Duration(milliseconds: 150));

      await tester.tap(find.text('Atakuj teraz!'));
      await tester.pump(const Duration(milliseconds: 150));

      expect(chosen, isNull);
      await gesture.removePointer();
    });

    testWidgets('displays resolved decision banner when event is already resolved',
        (tester) async {
      final resolvedEvent = _buildSampleEvent(selectedOptionId: 'opt_hold');

      await tester.pumpWidget(
        _wrapWithApp(
          InteractiveRadioCallBubbleHud(
            event: resolvedEvent,
            currentElapsedSeconds: 5420.0,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.textContaining('Decyzja DS: Trzymaj koło'), findsOneWidget);
    });

    testWidgets('InteractiveRadioCallBubbleOverlay integrates with teamRadioChatterProvider',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(teamRadioChatterProvider.notifier).processRiderContext(
            const RiderRadioChatterContext(
              riderId: 'r_leader',
              riderName: 'Tadej Pogačar',
              teamName: 'UAE Team Emirates',
              hasPuncture: true,
              wPrimePercent: 90.0,
              gradientPercent: 8.5,
              distanceToFinishKm: 18.0,
              kilometerMark: 162.0,
              elapsedSeconds: 6100.0,
            ),
            forceTrigger: true,
          );

      RadioDecisionResolution? resolved;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _wrapWithApp(
            InteractiveRadioCallBubbleOverlay(
              currentElapsedSeconds: 6105.0,
              onDecisionResolved: (res) => resolved = res,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tadej Pogačar'), findsOneWidget);

      final active = container.read(teamRadioChatterProvider).activeInitiative;
      if (active != null && active.options.isNotEmpty) {
        await tester.tap(find.text(active.options.first.label));
        await tester.pump(const Duration(milliseconds: 300));
        expect(resolved, isNotNull);
        expect(container.read(teamRadioChatterProvider).activeInitiative, isNull);
      }
    });
  });
}
