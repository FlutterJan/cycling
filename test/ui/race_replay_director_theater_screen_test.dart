import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_replay_recorder.dart';
import 'package:pro_peloton_manager/ui/screens/race_replay_director_theater_screen.dart';

void main() {
  group('ReplayTacticalSuccessAnalyzer & ReplayTheaterSampleBuilder', () {
    test('demo recorder generates 3 clips with 176 riders per frame', () {
      final recorder = ReplayTheaterSampleBuilder.createDemoRecorder();
      final clips = ReplayTheaterSampleBuilder.extractClips(recorder);

      expect(clips.length, 3);
      expect(clips.first.frames.isNotEmpty, isTrue);
      expect(clips.first.frames.first.riders.length, 176);
    });

    test('analyzer handles empty clip gracefully', () {
      const emptyClip = ReplayClip(
        id: 'empty',
        title: 'Pusty klip',
        description: '',
        type: ReplayClipType.finalKilometer,
        startDistanceKm: 0,
        endDistanceKm: 0,
        startTimestampSeconds: 0,
        endTimestampSeconds: 0,
        frames: [],
      );

      final report = ReplayTacticalSuccessAnalyzer.analyze(
        clip: emptyClip,
        currentFrameIndex: 0,
      );

      expect(report.totalRidersInClip, 0);
      expect(report.factors, isEmpty);
      expect(report.headlineVerdict, contains('Brak klatek'));
    });

    test('analyzer identifies sprint peak power, drafting and bike throw', () {
      final recorder = ReplayTheaterSampleBuilder.createDemoRecorder();
      final clips = ReplayTheaterSampleBuilder.extractClips(recorder);
      final finishClip = clips.first;

      final report = ReplayTacticalSuccessAnalyzer.analyze(
        clip: finishClip,
        currentFrameIndex: finishClip.frames.length - 1,
      );

      expect(report.totalRidersInClip, 176);
      expect(report.winnerPeakPowerWatts, greaterThan(1000));
      expect(report.winnerPeakSpeedKmh, greaterThan(65.0));
      expect(report.usedBikeThrowAtFinish, isTrue);
      expect(report.factors.length, greaterThanOrEqualTo(3));
      expect(report.headlineVerdict, contains(report.winnerRiderName));
    });
  });

  group('RaceReplayDirectorTheaterScreen Widget Tests', () {
    Widget wrapWithSize(Widget child, Size size) {
      return MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
          home: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      );
    }

    testWidgets('renders empty state for empty StageReplayRecorder and loads demo',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final emptyRecorder = StageReplayRecorder(stageName: 'Pusty Etap');
      await tester.pumpWidget(
        wrapWithSize(
          RaceReplayDirectorTheaterScreen(recorder: emptyRecorder),
          const Size(1600, 900),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Brak zapisanych powtórek etapu'), findsOneWidget);

      await tester.tap(find.text('Wczytaj Pakiet Pokazowy (176 kolarzy)'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Kolarzy w klatce: 176'), findsOneWidget);
      expect(find.text('ANALIZA SUKCESU TAKTYCZNEGO'), findsOneWidget);
    });

    testWidgets('frame-by-frame stepping, camera switching, Aero Vision and rider search work',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapWithSize(
          const RaceReplayDirectorTheaterScreen(),
          const Size(1600, 900),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('KLATKA 1 / 45'), findsOneWidget);

      // Step forward +1 frame
      await tester.tap(find.byTooltip('Następna klatka (+1)'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('KLATKA 2 / 45'), findsOneWidget);

      // Step backward -1 frame
      await tester.tap(find.byTooltip('Poprzednia klatka (-1)'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('KLATKA 1 / 45'), findsOneWidget);

      // Toggle Aero Vision OFF and ON
      expect(find.text('Aero Vision: WŁ.'), findsOneWidget);
      await tester.tap(find.text('Aero Vision: WŁ.'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Aero Vision: WYŁ.'), findsOneWidget);

      // Switch camera to Helikopter
      await tester.tap(find.text('Helikopter'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Helikopter'), findsWidgets);

      // Search for rider #176
      await tester.enterText(find.byType(TextField), '176');
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('#176 Kolarz #176'), findsOneWidget);

      await tester.tap(find.text('#176 Kolarz #176'));
      await tester.pump(const Duration(milliseconds: 200));
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            wrapWithSize(
              const RaceReplayDirectorTheaterScreen(),
              size,
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.text('KINO POWTÓREK REŻYSERSKICH'), findsOneWidget);
        },
      );
    }
  });
}
