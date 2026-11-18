import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/services/adaptive_dynamic_music_score_engine.dart';

void main() {
  group('AdaptiveDynamicMusicScoreEngine', () {
    const engine = AdaptiveDynamicMusicScoreEngine(sampleRate: 22050);

    test('dobiera odpowiednie akty muzyczne na podstawie telemetrii szosowej', () {
      final cruise = engine.evaluateTelemetry(
        rawTelemetry: RoadActionMusicTelemetry.pelotonCruise(),
      );
      expect(cruise.act, MusicScoreAct.pelotonCruise);
      expect(cruise.scale, HarmonicScaleMode.dMinorDorian);

      final breakaway = engine.evaluateTelemetry(
        rawTelemetry: RoadActionMusicTelemetry.breakawayChase(),
      );
      expect(breakaway.act, MusicScoreAct.breakawayTension);

      final mountain = engine.evaluateTelemetry(
        rawTelemetry: RoadActionMusicTelemetry.mountainClimb(),
      );
      expect(mountain.act, MusicScoreAct.mountainAscent);
      expect(mountain.mix.orchestralStrings, greaterThan(0.7));

      final echelon = engine.evaluateTelemetry(
        rawTelemetry: RoadActionMusicTelemetry.crosswindEchelon(),
      );
      expect(echelon.act, MusicScoreAct.crosswindEchelon);

      final sprint = engine.evaluateTelemetry(
        rawTelemetry: RoadActionMusicTelemetry.finalSprint(),
      );
      expect(sprint.act, MusicScoreAct.finalSprintClimax);
      expect(sprint.bpm, greaterThan(130.0));

      final podium = engine.evaluateTelemetry(
        rawTelemetry: RoadActionMusicTelemetry.podiumVictory(),
      );
      expect(podium.act, MusicScoreAct.podiumVictory);
      expect(podium.scale, HarmonicScaleMode.cMajorLydian);
    });

    test('bezpiecznie normalizuje wartości graniczne i NaN w telemetrii', () {
      const invalidTelemetry = RoadActionMusicTelemetry(
        speedKmh: double.nan,
        gradientPercent: 99.0,
        distanceRemainingMeters: -50.0,
        pelotonTension: 4.5,
        playerHeartRateZone: 99,
        riderCountNearby: -5,
      );

      final clamped = invalidTelemetry.clamped();
      expect(clamped.speedKmh, 0.0);
      expect(clamped.gradientPercent, 30.0);
      expect(clamped.distanceRemainingMeters, 0.0);
      expect(clamped.pelotonTension, 1.0);
      expect(clamped.playerHeartRateZone, 5);
      expect(clamped.riderCountNearby, 0);
    });

    test('syntetyzuje bufor stereo PCM w bezpiecznych granicach [-1.0, 1.0]', () {
      final cue = engine.evaluateTelemetry(
        rawTelemetry: RoadActionMusicTelemetry.finalSprint(),
      );
      final buffer = engine.synthesizePhraseBuffer(
        cue: cue,
        masterGain: 0.9,
        beats: 2,
      );

      expect(buffer.frameCount, greaterThan(0));
      expect(buffer.left.length, buffer.right.length);
      for (int i = 0; i < buffer.frameCount; i++) {
        expect(buffer.left[i].abs(), lessThanOrEqualTo(1.0));
        expect(buffer.right[i].abs(), lessThanOrEqualTo(1.0));
      }
      final peakDb = AdaptiveDynamicMusicScoreEngine.computePeakDb(buffer);
      expect(peakDb, greaterThan(-40.0));
      expect(peakDb, lessThanOrEqualTo(0.0));
    });

    test('zwraca ciszę przy masterGain == 0 lub wyciszeniu wszystkich stemów', () {
      final cue = engine.evaluateTelemetry(
        rawTelemetry: RoadActionMusicTelemetry.mountainClimb(),
      );
      final silentByGain = engine.synthesizePhraseBuffer(
        cue: cue,
        masterGain: 0.0,
        beats: 1,
      );
      expect(AdaptiveDynamicMusicScoreEngine.computePeakDb(silentByGain), -96.0);

      final allMuted = <MusicStemChannel, bool>{
        for (final ch in MusicStemChannel.values) ch: true,
      };
      final silentByMute = engine.synthesizePhraseBuffer(
        cue: cue,
        mutedStems: allMuted,
        masterGain: 0.85,
        beats: 1,
      );
      expect(AdaptiveDynamicMusicScoreEngine.computePeakDb(silentByMute), -96.0);
    });
  });

  group('AdaptiveDynamicMusicScoreNotifier', () {
    test('aktualizuje stan Riverpod, stemy i historię przejść', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(adaptiveDynamicMusicScoreProvider.notifier);
      notifier.triggerPresetScenario(MusicScoreAct.mountainAscent);

      var state = container.read(adaptiveDynamicMusicScoreProvider);
      expect(state.currentAct, MusicScoreAct.mountainAscent);
      expect(state.cueHistory, isNotEmpty);

      notifier.toggleStemMute(MusicStemChannel.cinematicBrass);
      state = container.read(adaptiveDynamicMusicScoreProvider);
      expect(state.isStemMuted(MusicStemChannel.cinematicBrass), isTrue);

      final buf = notifier.synthesizePreviewPhrase(beats: 1);
      expect(buf.frameCount, greaterThan(0));
      state = container.read(adaptiveDynamicMusicScoreProvider);
      expect(state.totalFramesSynthesized, buf.frameCount);
    });
  });

  group('AdaptiveDynamicMusicScorePanel responsiveness', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AdaptiveDynamicMusicScorePanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renderuje się poprawnie bez overflow w 390x844, 1024x768 i 1600x900',
        (tester) async {
      for (final size in const <Size>[
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpPanelAtSize(tester, size);
        expect(find.text('Silnik Muzyki Elektroniczno-Orkiestrowej'), findsOneWidget);
        expect(find.text('Mikser 5 Ścieżek (Stems)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('obsługuje interakcję przełączania aktu i syntezy PCM', (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));

      await tester.tap(find.text('Final Sprint Climax'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Aktywny: Final Sprint Climax'), findsOneWidget);

      await tester.tap(find.text('Syntetyzuj Frazę PCM (4 takty)'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });
}
