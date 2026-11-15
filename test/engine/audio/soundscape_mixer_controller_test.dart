import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/audio/procedural_cycling_audio_engine.dart';
import 'package:pro_peloton_manager/engine/audio/soundscape_mixer_controller.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

double _rmsEnergy(AudioStereoBuffer buffer) {
  if (buffer.frameCount == 0) return 0.0;
  double sumSq = 0.0;
  for (int i = 0; i < buffer.frameCount; i++) {
    final mid = 0.5 * (buffer.left[i] + buffer.right[i]);
    sumSq += mid * mid;
  }
  return math.sqrt(sumSq / buffer.frameCount);
}

void main() {
  group('SoundscapeMixerController (#172)', () {
    test('Szum wiatru rośnie proporcjonalnie do kwadratu prędkości v^2', () {
      final gain10 = WindNoiseV2Generator.computeQuadraticGain(10.0);
      final gain20 = WindNoiseV2Generator.computeQuadraticGain(20.0);
      expect(gain10, greaterThan(0.0));
      expect(gain20 / gain10, closeTo(4.0, 1e-6));

      final controller = SoundscapeMixerController();
      // Izolacja kanału wiatru
      controller.setChannelVolume(SoundscapeChannel.freehub, 0.0);
      controller.setChannelVolume(SoundscapeChannel.breathing, 0.0);
      controller.setChannelVolume(SoundscapeChannel.cowbells, 0.0);
      controller.setChannelVolume(SoundscapeChannel.crowd, 0.0);

      final slowBuf = controller.generateAudioBuffer(
        duration: const Duration(milliseconds: 300),
        telemetry: const SoundscapeTelemetry(
          speedKmh: 28.8, // 8 m/s
          powerWatts: 200.0,
          distanceToFinishMeters: 5000.0,
        ),
      );
      final slowRms = _rmsEnergy(slowBuf);

      controller.reset();
      final fastBuf = controller.generateAudioBuffer(
        duration: const Duration(milliseconds: 300),
        telemetry: const SoundscapeTelemetry(
          speedKmh: 57.6, // 16 m/s (2x prędkość -> 4x energia v^2)
          powerWatts: 200.0,
          distanceToFinishMeters: 5000.0,
        ),
      );
      final fastRms = _rmsEnergy(fastBuf);

      expect(slowRms, greaterThan(0.001));
      expect(fastRms, greaterThan(slowRms * 2.5));
    });

    test('Terkot bębenka wolnobiegu aktywny przy P = 0 W i wyłączony przy P > 0 W', () {
      final controller = SoundscapeMixerController();
      controller.setChannelVolume(SoundscapeChannel.wind, 0.0);
      controller.setChannelVolume(SoundscapeChannel.breathing, 0.0);
      controller.setChannelVolume(SoundscapeChannel.cowbells, 0.0);
      controller.setChannelVolume(SoundscapeChannel.crowd, 0.0);

      const coastingTel = SoundscapeTelemetry(
        speedKmh: 52.0,
        powerWatts: 0.0,
        cadenceRpm: 0.0,
        distanceToFinishMeters: 5000.0,
      );
      final coastingBuf = controller.generateAudioBuffer(
        duration: const Duration(milliseconds: 250),
        telemetry: coastingTel,
      );
      expect(_rmsEnergy(coastingBuf), greaterThan(0.01));
      expect(controller.state.layerIntensities.freehub, greaterThan(0.5));

      controller.reset();
      const pedalingTel = SoundscapeTelemetry(
        speedKmh: 52.0,
        powerWatts: 180.0,
        cadenceRpm: 88.0,
        distanceToFinishMeters: 5000.0,
      );
      final pedalingBuf = controller.generateAudioBuffer(
        duration: const Duration(milliseconds: 250),
        telemetry: pedalingTel,
      );
      expect(_rmsEnergy(pedalingBuf), lessThan(0.001));
      expect(controller.state.layerIntensities.freehub, equals(0.0));
    });

    test('Oddech kolarza aktywowany powyżej progu LT2 i cichy poniżej LT2', () {
      final controller = SoundscapeMixerController();
      controller.setChannelVolume(SoundscapeChannel.wind, 0.0);
      controller.setChannelVolume(SoundscapeChannel.freehub, 0.0);
      controller.setChannelVolume(SoundscapeChannel.cowbells, 0.0);
      controller.setChannelVolume(SoundscapeChannel.crowd, 0.0);

      const belowLt2 = SoundscapeTelemetry(
        speedKmh: 38.0,
        powerWatts: 310.0,
        lt2PowerWatts: 350.0,
        distanceToFinishMeters: 5000.0,
      );
      final calmBuf = controller.generateAudioBuffer(
        duration: const Duration(milliseconds: 400),
        telemetry: belowLt2,
      );
      expect(_rmsEnergy(calmBuf), lessThan(0.001));
      expect(controller.state.layerIntensities.breathing, equals(0.0));

      controller.reset();
      const aboveLt2 = SoundscapeTelemetry(
        speedKmh: 24.0,
        powerWatts: 460.0,
        lt2PowerWatts: 350.0,
        heartRateBpm: 184.0,
        distanceToFinishMeters: 5000.0,
      );
      final heavyBuf = controller.generateAudioBuffer(
        duration: const Duration(milliseconds: 800),
        telemetry: aboveLt2,
      );
      expect(_rmsEnergy(heavyBuf), greaterThan(0.01));
      expect(controller.state.layerIntensities.breathing, greaterThan(0.5));
    });

    test('Dzwonki krów i wrzawa tłumu narastają na ostatnich 500 m przed KOM i metą', () {
      const farTel = SoundscapeTelemetry(
        speedKmh: 20.0,
        powerWatts: 340.0,
        distanceToFinishMeters: 4000.0,
        distanceToNextKomMeters: 2500.0,
      );
      const kom450Tel = SoundscapeTelemetry(
        speedKmh: 20.0,
        powerWatts: 340.0,
        distanceToFinishMeters: 4000.0,
        distanceToNextKomMeters: 450.0,
      );
      const kom50Tel = SoundscapeTelemetry(
        speedKmh: 20.0,
        powerWatts: 340.0,
        distanceToFinishMeters: 4000.0,
        distanceToNextKomMeters: 50.0,
      );
      const finish100Tel = SoundscapeTelemetry(
        speedKmh: 62.0,
        powerWatts: 1050.0,
        distanceToFinishMeters: 100.0,
      );

      expect(CrowdSurgeGenerator.computeSurgeIntensity(farTel), equals(0.0));
      final surge450 = CrowdSurgeGenerator.computeSurgeIntensity(kom450Tel);
      final surge50 = CrowdSurgeGenerator.computeSurgeIntensity(kom50Tel);
      final surgeFinish = CrowdSurgeGenerator.computeSurgeIntensity(finish100Tel);

      expect(surge450, greaterThan(0.2));
      expect(surge50, greaterThan(surge450));
      expect(surgeFinish, greaterThan(0.8));

      expect(CowbellAtmosphereGenerator.computeIntensity(farTel), equals(0.0));
      expect(
        CowbellAtmosphereGenerator.computeIntensity(kom50Tel),
        greaterThan(CowbellAtmosphereGenerator.computeIntensity(kom450Tel)),
      );

      final controller = SoundscapeMixerController();
      controller.setChannelVolume(SoundscapeChannel.wind, 0.0);
      controller.setChannelVolume(SoundscapeChannel.freehub, 0.0);
      controller.setChannelVolume(SoundscapeChannel.breathing, 0.0);

      final komAudio = controller.generateAudioBuffer(
        duration: const Duration(milliseconds: 500),
        telemetry: kom50Tel,
      );
      expect(_rmsEnergy(komAudio), greaterThan(0.03));
    });

    test('fromStageProgress poprawnie wyznacza dystans do najbliższej premii KOM i mety', () {
      const segments = [
        StageSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 10.0,
          startElevationM: 200.0,
          endElevationM: 250.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 10.0,
          windDirectionDegrees: 0.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.none,
        ),
        StageSegment(
          index: 1,
          startKm: 10.0,
          lengthKm: 5.0,
          startElevationM: 250.0,
          endElevationM: 750.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 25.0,
          windDirectionDegrees: 0.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.cat1,
        ),
      ];

      final tel = SoundscapeTelemetry.fromStageProgress(
        currentKm: 14.6,
        totalStageKm: 25.0,
        segments: segments,
        speedKmh: 18.0,
        powerWatts: 410.0,
        lt2PowerWatts: 350.0,
      );

      expect(tel.distanceToNextKomMeters, closeTo(400.0, 0.5));
      expect(tel.distanceToFinishMeters, closeTo(10400.0, 0.5));
      expect(tel.nearestLandmarkDistanceMeters, closeTo(400.0, 0.5));
    });

    test('Wyciszenie, limiter soft-clip i eksport WAV RIFF działają poprawnie', () {
      final controller = SoundscapeMixerController();
      const extremeTel = SoundscapeTelemetry(
        speedKmh: 85.0,
        powerWatts: 0.0,
        distanceToFinishMeters: 30.0,
        distanceToNextKomMeters: 30.0,
      );

      final wav = controller.generateWavBytes(
        duration: const Duration(milliseconds: 100),
        telemetry: extremeTel,
      );
      expect(wav.length, greaterThan(44));
      expect(String.fromCharCodes(wav.sublist(0, 4)), equals('RIFF'));
      expect(String.fromCharCodes(wav.sublist(8, 12)), equals('WAVE'));

      final lastBuf = controller.state.lastBuffer!;
      for (int i = 0; i < lastBuf.frameCount; i++) {
        expect(lastBuf.left[i].abs(), lessThanOrEqualTo(1.0));
        expect(lastBuf.right[i].abs(), lessThanOrEqualTo(1.0));
      }

      controller.setMuted(true);
      final mutedBuf = controller.generateAudioBuffer(
        duration: const Duration(milliseconds: 50),
        telemetry: extremeTel,
      );
      expect(_rmsEnergy(mutedBuf), equals(0.0));
    });

    test('Provider Riverpod soundscapeMixerProvider poprawnie zarządza stanem', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(soundscapeMixerProvider.notifier);
      controller.updateTelemetry(
        const SoundscapeTelemetry(
          speedKmh: 54.0,
          powerWatts: 0.0,
          distanceToFinishMeters: 250.0,
        ),
      );

      final state = container.read(soundscapeMixerProvider);
      expect(state.layerIntensities.wind, greaterThan(0.2));
      expect(state.layerIntensities.freehub, greaterThan(0.5));
      expect(state.layerIntensities.crowd, greaterThan(0.5));
    });
  });
}
