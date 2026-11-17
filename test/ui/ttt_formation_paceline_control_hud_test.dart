import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/team_time_trial_rider_drop_strategy.dart';
import 'package:pro_peloton_manager/ui/widgets/ttt_formation_paceline_control_hud.dart';

void main() {
  group('TttFormationPacelineHudData & Calculator', () {
    test('serializuje i deserializuje JSON oraz normalizuje NaN / Infinity', () {
      final TttFormationPacelineHudData sample =
          TttFormationPacelineHudData.sample();
      final Map<String, dynamic> json = sample.toJson();
      final TttFormationPacelineHudData restored =
          TttFormationPacelineHudData.fromJson(json);

      expect(restored.teamName, sample.teamName);
      expect(restored.teamCode, sample.teamCode);
      expect(restored.countingRiderRank, 5);
      expect(restored.riders.length, sample.riders.length);
      expect(restored.formationType, sample.formationType);
      expect(restored.tempoPreset, sample.tempoPreset);

      const TttFormationPacelineHudData invalid = TttFormationPacelineHudData(
        teamName: 'Test',
        teamCode: 'TST',
        stageName: 'TTT',
        stageDistanceKm: -5.0,
        distanceRemainingKm: double.nan,
        elapsedSeconds: double.infinity,
        splitDeltaSeconds: double.nan,
        pacelineSpeedKmh: -12.0,
        windSpeedKmh: double.nan,
        crosswindAngleDeg: double.infinity,
        pullDurationSeconds: 5,
        pullElapsedSeconds: 999.0,
        targetEffortPercent: 200,
      );

      expect(invalid.safeStageDistanceKm, 0.1);
      expect(invalid.safeDistanceRemainingKm, 0.0);
      expect(invalid.safeElapsedSeconds, 0.0);
      expect(invalid.safeSplitDeltaSeconds, 0.0);
      expect(invalid.safePacelineSpeedKmh, 0.0);
      expect(invalid.safePullDurationSeconds, 10);
      expect(invalid.safeTargetEffortPercent, 135);
    });

    test('wyznacza 5. kolarza, status bezpieczeństwa i blokadę zrzutu poniżej 5', () {
      final TttFormationPacelineHudData sample =
          TttFormationPacelineHudData.sample();

      final TttPacelineRiderState? fifth =
          TttFormationPacelineCalculator.countingRider(sample);
      expect(fifth, isNotNull);
      expect(fifth!.riderId, 'r5');
      expect(fifth.riderName, 'K. Gradek');
      expect(
        TttFormationPacelineCalculator.fifthRiderStatus(sample),
        TttFifthRiderStatus.gappedAlert,
      );
      expect(TttFormationPacelineCalculator.safetyBufferCount(sample), 1);
      expect(TttFormationPacelineCalculator.canDropAnotherRider(sample), isTrue);

      // Kolejny na czele pomija r3 (skipPullEnabled = true) i wybiera r2
      final TttPacelineRiderState? next =
          TttFormationPacelineCalculator.nextPullingRider(sample);
      expect(next?.riderId, 'r2');

      // Gdy zostaje dokładnie 5 aktywnych kolarzy, nie wolno zrzucić kolejnego
      final TttFormationPacelineHudData fiveLeft = sample.copyWith(
        riders: sample.riders
            .map(
              (r) => r.riderId == 'r6'
                  ? r.copyWith(role: TttRiderPullRole.dropped)
                  : r,
            )
            .toList(),
      );
      expect(TttFormationPacelineCalculator.safetyBufferCount(fiveLeft), 0);
      expect(
        TttFormationPacelineCalculator.canDropAnotherRider(fiveLeft),
        isFalse,
      );

      // Gdy zostaje < 5 aktywnych kolarzy, status to insufficientRiders
      final TttFormationPacelineHudData fourLeft = fiveLeft.copyWith(
        riders: fiveLeft.riders
            .map(
              (r) => r.riderId == 'r5'
                  ? r.copyWith(role: TttRiderPullRole.dropped)
                  : r,
            )
            .toList(),
      );
      expect(
        TttFormationPacelineCalculator.fifthRiderStatus(fourLeft),
        TttFifthRiderStatus.insufficientRiders,
      );
    });

    test('formatuje zegar wyścigowy i deltę czasową poprawnie', () {
      expect(TttFormationPacelineCalculator.formatRaceClock(1624.4), '27:04.4');
      expect(TttFormationPacelineCalculator.formatRaceClock(3665.2), '1:01:05.2');
      expect(TttFormationPacelineCalculator.formatGapDelta(-4.23), '-4.23 s');
      expect(TttFormationPacelineCalculator.formatGapDelta(1.85), '+1.85 s');
      expect(TttFormationPacelineCalculator.formatGapDelta(0.0), '0.00 s');
    });
  });

  group('TttFormationPacelineControlHud Widget', () {
    Widget buildHarness({
      required TttFormationPacelineHudData data,
      bool enabled = true,
      bool initiallyExpanded = true,
      ValueChanged<TttPacelineFormationType>? onFormationChanged,
      ValueChanged<TttPacelineTempoPreset>? onTempoPresetChanged,
      ValueChanged<int>? onPullDurationChanged,
      ValueChanged<int>? onTargetEffortChanged,
      VoidCallback? onForceRotationNow,
      ValueChanged<bool>? onToggleWaitForFifth,
      ValueChanged<String>? onToggleRiderSkipPull,
      ValueChanged<String>? onSendRiderToFront,
      ValueChanged<String>? onDropRider,
      VoidCallback? onTriggerKamikazePull,
      Size surfaceSize = const Size(1280, 800),
    }) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0F1115),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: surfaceSize.width - 24,
                child: TttFormationPacelineControlHud(
                  data: data,
                  enabled: enabled,
                  initiallyExpanded: initiallyExpanded,
                  onFormationChanged: onFormationChanged,
                  onTempoPresetChanged: onTempoPresetChanged,
                  onPullDurationChanged: onPullDurationChanged,
                  onTargetEffortChanged: onTargetEffortChanged,
                  onForceRotationNow: onForceRotationNow,
                  onToggleWaitForFifth: onToggleWaitForFifth,
                  onToggleRiderSkipPull: onToggleRiderSkipPull,
                  onSendRiderToFront: onSendRiderToFront,
                  onDropRider: onDropRider,
                  onTriggerKamikazePull: onTriggerKamikazePull,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('wyświetla zegar 5. kolarza, listę pociągu i obsługuje akcje sterowania', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool rotated = false;
      bool waitToggled = false;
      int? selectedDuration;
      TttPacelineFormationType? selectedFormation;
      TttPacelineTempoPreset? selectedPreset;
      bool kamikazeTriggered = false;

      await tester.pumpWidget(
        buildHarness(
          data: TttFormationPacelineHudData.sample(),
          onForceRotationNow: () => rotated = true,
          onToggleWaitForFifth: (bool val) => waitToggled = val,
          onPullDurationChanged: (int sec) => selectedDuration = sec,
          onFormationChanged: (TttPacelineFormationType f) =>
              selectedFormation = f,
          onTempoPresetChanged: (TttPacelineTempoPreset p) =>
              selectedPreset = p,
          onTriggerKamikazePull: () => kamikazeTriggered = true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('TTT HUD'), findsOneWidget);
      expect(find.text('27:06.3'), findsOneWidget);
      expect(find.text('-4.23 s'), findsOneWidget);
      expect(find.text('CZAS #5'), findsOneWidget);

      await tester.tap(find.text('Zmiana Teraz'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(rotated, isTrue);

      await tester.tap(find.text('Czekaj na 5. kolarza'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(waitToggled, isTrue);

      await tester.tap(find.text('30s'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(selectedDuration, 30);

      await tester.tap(find.text('Podwójny wachlarz'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(selectedFormation, TttPacelineFormationType.doublePaceline);

      await tester.tap(find.text('Finał All-Out (118%)'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(selectedPreset, TttPacelineTempoPreset.allOut);

      await tester.tap(
        find.text(
          'Kamikaze Pull & Drop (${KamikazePullDropPhase.standby.labelPl})',
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(kamikazeTriggered, isTrue);
    });

    testWidgets('obsługuje stan pusty oraz stan disabled', (
      WidgetTester tester,
    ) async {
      bool callbackCalled = false;
      const TttFormationPacelineHudData emptyData = TttFormationPacelineHudData(
        teamName: 'Empty Team',
        teamCode: 'EMP',
        stageName: 'Test TTT',
        stageDistanceKm: 20.0,
        distanceRemainingKm: 10.0,
        elapsedSeconds: 600.0,
        splitDeltaSeconds: 0.0,
        pacelineSpeedKmh: 50.0,
      );

      await tester.pumpWidget(
        buildHarness(
          data: emptyData,
          enabled: false,
          onPullDurationChanged: (_) => callbackCalled = true,
          onForceRotationNow: () => callbackCalled = true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Brak aktywnych kolarzy w pociągu TTT.'),
        findsOneWidget,
      );

      await tester.tap(find.text('30s'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(callbackCalled, isFalse);
    });

    testWidgets('obsługuje zwijanie, rozwijanie oraz zdarzenie hover', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildHarness(data: TttFormationPacelineHudData.sample()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Zmiana Teraz')));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byIcon(Icons.expand_less_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);
    });

    testWidgets(
      'renderuje się bez przepełnień w 390x844, 1024x768 i 1600x900',
      (WidgetTester tester) async {
        const List<Size> viewports = <Size>[
          Size(390, 844),
          Size(1024, 768),
          Size(1600, 900),
        ];

        for (final Size size in viewports) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            buildHarness(
              data: TttFormationPacelineHudData.sample(),
              surfaceSize: size,
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
        }

        await tester.binding.setSurfaceSize(null);
      },
    );
  });
}
