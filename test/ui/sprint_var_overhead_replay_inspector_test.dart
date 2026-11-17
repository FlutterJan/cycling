import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/uci_commissaire_rulebook_and_var_model.dart';
import 'package:pro_peloton_manager/ui/widgets/sprint_var_overhead_replay_inspector.dart';

void main() {
  group('SprintVarOverheadCalculator & Models', () {
    test('interpolates lateral position and classifies deviation zones', () {
      final data = SprintVarOverheadReplayData.demoIrregularSprint();
      final suspect = data.tracks.firstWhere((t) => t.isSuspect);

      final at200 = SprintVarOverheadCalculator.interpolateAtDistance(
        samples: suspect.samples,
        distanceToFinishMeters: 200.0,
        toleranceMeters: data.deviationToleranceMeters,
      );
      expect(at200.deviationFromBaselineMeters, closeTo(0.0, 0.001));
      expect(at200.zoneLevel, SprintDeviationZoneLevel.clean);

      final at60 = SprintVarOverheadCalculator.interpolateAtDistance(
        samples: suspect.samples,
        distanceToFinishMeters: 60.0,
        toleranceMeters: data.deviationToleranceMeters,
      );
      expect(at60.deviationFromBaselineMeters, closeTo(1.55, 0.01));
      expect(at60.zoneLevel, SprintDeviationZoneLevel.violation);

      final summary = SprintVarOverheadCalculator.summarizeTrack(
        track: suspect,
        toleranceMeters: data.deviationToleranceMeters,
      );
      expect(summary.maxDeviationMeters, greaterThan(1.5));
      expect(summary.minClearanceMeters, closeTo(0.28, 0.01));
      expect(summary.worstZone, SprintDeviationZoneLevel.violation);
    });

    test('JSON round-trip preserves SprintVarOverheadReplayData', () {
      final original = SprintVarOverheadReplayData.demoIrregularSprint();
      final json = original.toJson();
      final decoded = SprintVarOverheadReplayData.fromJson(json);

      expect(decoded.incidentId, original.incidentId);
      expect(decoded.stageName, original.stageName);
      expect(decoded.tracks.length, original.tracks.length);
      expect(decoded.tracks.first.riderName, original.tracks.first.riderName);
      expect(
        decoded.tracks.first.samples.length,
        original.tracks.first.samples.length,
      );
    });
  });

  group('SprintVarOverheadReplayInspector Widget', () {
    Future<void> pumpInspectorAtSize(
      WidgetTester tester, {
      required Size size,
      required SprintVarOverheadReplayData data,
      bool isReadOnly = false,
      ValueChanged<SprintVarVerdict>? onVerdictConfirmed,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SprintVarOverheadReplayInspector(
                data: data,
                isReadOnly: isReadOnly,
                onVerdictConfirmed: onVerdictConfirmed,
              ),
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
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await pumpInspectorAtSize(
            tester,
            size: size,
            data: SprintVarOverheadReplayData.demoIrregularSprint(),
          );
          expect(find.text('VAR Sprint Deviation Inspector'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('renders empty state cleanly when no tracks provided',
        (tester) async {
      await pumpInspectorAtSize(
        tester,
        size: const Size(1024, 768),
        data: SprintVarOverheadReplayData.empty(),
      );
      expect(
        find.text('Brak danych powtórki VAR dla ostatnich 200 m'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('playback, scrub, camera, and verdict actions work',
        (tester) async {
      SprintVarVerdict? confirmed;
      await pumpInspectorAtSize(
        tester,
        size: const Size(1600, 900),
        data: SprintVarOverheadReplayData.demoIrregularSprint(),
        onVerdictConfirmed: (v) => confirmed = v,
      );

      // Step forward +5m (from 200.0 -> 195.0 m).
      await tester.tap(find.text('+5m'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('195.0 m do mety'), findsOneWidget);

      // Jump to max deviation.
      await tester.tap(find.byIcon(Icons.crisis_alert_rounded));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('30.0 m do mety'), findsOneWidget);

      // Play and pause.
      await tester.tap(find.text('Odtwórz'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Pauza'), findsOneWidget);
      await tester.tap(find.text('Pauza'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Odtwórz'), findsOneWidget);

      // Switch camera.
      await tester.tap(find.text('Linia mety'));
      await tester.pump(const Duration(milliseconds: 100));

      // Confirm commissaire decision.
      await tester.tap(find.text('Relegacja + Kartka'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(confirmed, isNotNull);
      expect(
        confirmed!.status,
        SprintVarVerdictStatus.yellowCardAndRelegated,
      );
      expect(confirmed!.cardIssued, UciCardType.yellow);
    });

    testWidgets('isReadOnly disables commissaire verdict buttons',
        (tester) async {
      SprintVarVerdict? confirmed;
      await pumpInspectorAtSize(
        tester,
        size: const Size(1600, 900),
        data: SprintVarOverheadReplayData.demoIrregularSprint(),
        isReadOnly: true,
        onVerdictConfirmed: (v) => confirmed = v,
      );

      expect(find.text('TYLKO PODGLĄD'), findsOneWidget);
      await tester.tap(find.text('Czysty sprint'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(confirmed, isNull);
    });
  });
}
