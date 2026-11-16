import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/simulation/deterministic_rng_seed_manager.dart';

void main() {
  group('DeterministicPrngStream', () {
    test('produces bit-identical sequences for the same seed', () {
      final a = DeterministicPrngStream(domain: RngDomain.aiBehavior, seed: 20260704);
      final b = DeterministicPrngStream(domain: RngDomain.aiBehavior, seed: 20260704);

      for (int i = 0; i < 200; i++) {
        expect(a.nextUint32(), equals(b.nextUint32()));
        expect(a.nextDouble(), equals(b.nextDouble()));
        expect(a.nextInt(176), equals(b.nextInt(176)));
        expect(a.nextBool(), equals(b.nextBool()));
      }
      expect(a.callCount, equals(b.callCount));
    });

    test('implements math.Random and respects bounds', () {
      final math.Random rng = DeterministicPrngStream(domain: RngDomain.incidents, seed: 0);
      for (int i = 0; i < 500; i++) {
        final v = rng.nextInt(10);
        expect(v, inInclusiveRange(0, 9));
        final d = rng.nextDouble();
        expect(d, greaterThanOrEqualTo(0.0));
        expect(d, lessThan(1.0));
      }

      expect(() => rng.nextInt(0), throwsRangeError);
      expect(() => rng.nextInt(-5), throwsRangeError);
    });

    test('supports snapshot save and restore mid-stream', () {
      final stream = DeterministicPrngStream(domain: RngDomain.weather, seed: 987654);
      for (int i = 0; i < 40; i++) {
        stream.nextDouble();
      }
      final snapshot = stream.saveState();
      final expectedInts = List.generate(25, (_) => stream.nextInt(10000));

      stream.restoreState(snapshot);
      final replayedInts = List.generate(25, (_) => stream.nextInt(10000));
      expect(replayedInts, equals(expectedInts));

      final restoredFromFactory = DeterministicPrngStream.fromSnapshot(snapshot);
      final factoryInts = List.generate(25, (_) => restoredFromFactory.nextInt(10000));
      expect(factoryInts, equals(expectedInts));
    });

    test('shuffle and pickOne are deterministic and validate empty lists', () {
      final a = DeterministicPrngStream(domain: RngDomain.pelotonMicroMovement, seed: 42);
      final b = DeterministicPrngStream(domain: RngDomain.pelotonMicroMovement, seed: 42);

      final listA = List.generate(20, (i) => 'rider_$i');
      final listB = List.generate(20, (i) => 'rider_$i');
      a.shuffle(listA);
      b.shuffle(listB);

      expect(listA, equals(listB));
      expect(a.pickOne(listA), equals(b.pickOne(listB)));
      expect(() => a.pickOne(<String>[]), throwsArgumentError);
    });
  });

  group('DeterministicRngSeedManager', () {
    test('isolates RngDomains so drawing from one does not shift another', () {
      final clean = DeterministicRngSeedManager(stageSeed: 777123);
      final noisy = DeterministicRngSeedManager(stageSeed: 777123);

      // Symulujemy dodatkowe losowania w domenie AI i kamery
      for (int i = 0; i < 150; i++) {
        noisy.streamFor(RngDomain.aiBehavior).nextDouble();
        noisy.streamFor(RngDomain.replayCamera).nextInt(10);
      }

      for (int i = 0; i < 50; i++) {
        expect(
          noisy.streamFor(RngDomain.windGusts).nextDouble(),
          equals(clean.streamFor(RngDomain.windGusts).nextDouble()),
        );
        expect(
          noisy.streamFor(RngDomain.incidents).nextInt(1000),
          equals(clean.streamFor(RngDomain.incidents).nextInt(1000)),
        );
      }
    });

    test('forStage computes deterministic stageSeed from careerSeed, stageId, and stageNumber', () {
      final m1 = DeterministicRngSeedManager.forStage(
        careerSeed: 123456,
        stageId: 'tdf_stage_14_tourmalet',
        stageNumber: 14,
      );
      final m2 = DeterministicRngSeedManager.forStage(
        careerSeed: 123456,
        stageId: 'tdf_stage_14_tourmalet',
        stageNumber: 14,
      );
      final m3 = DeterministicRngSeedManager.forStage(
        careerSeed: 123456,
        stageId: 'tdf_stage_15_plateau_de_beille',
        stageNumber: 15,
      );

      expect(m1.stageSeed, equals(m2.stageSeed));
      expect(m1.stageSeed, isNot(equals(m3.stageSeed)));
    });

    test('sampleWindGustAtMs is deterministic and identical on random-access replay seeking', () {
      final liveRun = DeterministicRngSeedManager(stageSeed: 555001);
      final replaySeek = DeterministicRngSeedManager(stageSeed: 555001);

      final timestamps = [0, 1, 250, 1000, 4321, 18750, 125432, 3600001];
      final liveSamples = timestamps
          .map(
            (ms) => liveRun.sampleWindGustAtMs(
              elapsedMs: ms,
              baseWindSpeedKmh: 28.0,
              baseWindDirectionDegrees: 115.0,
              exposureFactor: 1.0,
            ),
          )
          .toList();

      // Odtwarzanie w odwrotnej kolejności (jak przewijanie w StageReplayRecorder)
      for (int i = timestamps.length - 1; i >= 0; i--) {
        final seeked = replaySeek.sampleWindGustAtMs(
          elapsedMs: timestamps[i],
          baseWindSpeedKmh: 28.0,
          baseWindDirectionDegrees: 115.0,
          exposureFactor: 1.0,
        );
        expect(seeked, equals(liveSamples[i]));
        expect(seeked.gustSpeedKmh, greaterThanOrEqualTo(0.0));
        expect(seeked.windDirectionDegrees, inInclusiveRange(0.0, 360.0));
        expect(seeked.turbulenceIntensity, inInclusiveRange(0.0, 1.0));
      }
    });

    test('sampleAiBehaviorAtMs is deterministic per rider and millisecond', () {
      final runA = DeterministicRngSeedManager(stageSeed: 991122);
      final runB = DeterministicRngSeedManager(stageSeed: 991122);

      final rollA1 = runA.sampleAiBehaviorAtMs(elapsedMs: 42317, riderId: 'rider_pogacar');
      final rollB1 = runB.sampleAiBehaviorAtMs(elapsedMs: 42317, riderId: 'rider_pogacar');
      final rollOtherMs = runB.sampleAiBehaviorAtMs(elapsedMs: 42318, riderId: 'rider_pogacar');
      final rollOtherRider = runB.sampleAiBehaviorAtMs(elapsedMs: 42317, riderId: 'rider_vingegaard');

      expect(rollA1, equals(rollB1));
      expect(rollA1.reactionDelayMs, inInclusiveRange(120, 1400));
      expect(rollA1, isNot(equals(rollOtherMs)));
      expect(rollA1, isNot(equals(rollOtherRider)));
    });

    test('exports and restores manifest with tactical command log and JSON roundtrip', () {
      final original = DeterministicRngSeedManager(
        stageSeed: 314159,
        stageId: 'roubaix_stage',
      );
      original.recordTacticalCommand(
        timestampMs: 120500,
        riderId: 'rider_1',
        orderName: 'attack',
        parameterValue: 1.0,
      );
      original.recordTacticalCommand(
        timestampMs: 185250,
        riderId: 'rider_2',
        orderName: 'protectLeader',
      );

      // Przesuwamy kilka strumieni
      original.streamFor(RngDomain.incidents).nextInt(100);
      original.streamFor(RngDomain.aiBehavior).nextDouble();

      final jsonStr = original.toJsonString();
      final restored = DeterministicRngSeedManager.fromJsonString(jsonStr);

      expect(restored.stageSeed, equals(original.stageSeed));
      expect(restored.stageId, equals(original.stageId));
      expect(restored.commandLog.length, equals(2));
      expect(restored.commandsInWindow(100000, 150000).single.riderId, equals('rider_1'));
      expect(
        restored.exportManifest().computeChecksum(),
        equals(original.exportManifest().computeChecksum()),
      );

      // Kolejne losowania po przywróceniu muszą być identyczne
      for (int i = 0; i < 20; i++) {
        expect(
          restored.streamFor(RngDomain.incidents).nextUint32(),
          equals(original.streamFor(RngDomain.incidents).nextUint32()),
        );
        expect(
          restored.streamFor(RngDomain.aiBehavior).nextDouble(),
          equals(original.streamFor(RngDomain.aiBehavior).nextDouble()),
        );
      }
    });
  });
}
