import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/boids_steering_collision_avoidance.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

void main() {
  group('BoidsSteeringCollisionAvoidance', () {
    const engine = BoidsSteeringCollisionAvoidance();

    test('Separacja odpycha kolarzy i gwarantuje brak clippingu 1.85m x 0.65m', () {
      final riders = [
        const BoidRiderState(
          riderId: 'r1',
          distanceMeters: 100.0,
          lateralOffsetMeters: 0.0,
          longitudinalSpeedMs: 12.0,
          targetSpeedMs: 12.0,
        ),
        const BoidRiderState(
          riderId: 'r2',
          distanceMeters: 100.2,
          lateralOffsetMeters: 0.1,
          longitudinalSpeedMs: 12.0,
          targetSpeedMs: 12.0,
        ),
      ];

      var current = riders;
      late BoidsFrameResult result;
      for (var frame = 0; frame < 30; frame++) {
        result = engine.stepFrame(riders: current, roadWidthMeters: 7.0);
        current = result.riders;
      }

      final r1 = current.firstWhere((r) => r.riderId == 'r1');
      final r2 = current.firstWhere((r) => r.riderId == 'r2');

      final dx = (r1.distanceMeters - r2.distanceMeters).abs();
      final dy = (r1.lateralOffsetMeters - r2.lateralOffsetMeters).abs();
      final overlaps = dx < 1.85 && dy < 0.65;

      expect(overlaps, isFalse);
      expect(dy, greaterThanOrEqualTo(0.65));
    });

    test('176 kolarzy w 60 FPS nie przenika przez siebie i miesci sie w czasie klatki', () {
      final rng = math.Random(42);
      final riders = List<BoidRiderState>.generate(176, (i) {
        final row = i ~/ 6;
        final col = i % 6;
        return BoidRiderState(
          riderId: 'rider_${i.toString().padLeft(3, '0')}',
          distanceMeters: 1000.0 - row * 2.1 + (rng.nextDouble() - 0.5) * 0.4,
          lateralOffsetMeters: -2.2 + col * 0.85 + (rng.nextDouble() - 0.5) * 0.2,
          longitudinalSpeedMs: 12.5,
          targetSpeedMs: 12.2 + (i % 5) * 0.15,
        );
      });

      var current = riders;
      final sw = Stopwatch()..start();
      for (var frame = 0; frame < 60; frame++) {
        final res = engine.stepFrame(riders: current, roadWidthMeters: 7.0);
        current = res.riders;
      }
      sw.stop();

      // Sprawdzamy absolutny brak nakladania kopul 1.85m x 0.65m po symulacji.
      for (var i = 0; i < current.length; i++) {
        for (var j = i + 1; j < current.length; j++) {
          final dx = (current[i].distanceMeters - current[j].distanceMeters).abs();
          final dy = (current[i].lateralOffsetMeters - current[j].lateralOffsetMeters).abs();
          expect(
            dx < 1.849 && dy < 0.649,
            isFalse,
            reason: 'Kolizja miedzy ${current[i].riderId} a ${current[j].riderId}: dx=$dx, dy=$dy',
          );
        }
      }

      // 60 klatek dla 176 kolarzy powinno wykonac sie w rozsadnym czasie (ponizej 500ms).
      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('Draft Seeking formuje wachlarz po przekatnej przy wietrze bocznym', () {
      const leader = BoidRiderState(
        riderId: 'leader',
        distanceMeters: 200.0,
        lateralOffsetMeters: 0.0,
        longitudinalSpeedMs: 13.0,
        targetSpeedMs: 13.0,
      );
      const follower = BoidRiderState(
        riderId: 'follower',
        distanceMeters: 196.5,
        lateralOffsetMeters: 0.0,
        longitudinalSpeedMs: 13.0,
        targetSpeedMs: 13.0,
      );

      var current = [leader, follower];
      late BoidsFrameResult lastResult;
      for (var frame = 0; frame < 60; frame++) {
        lastResult = engine.stepFrame(
          riders: current,
          roadWidthMeters: 7.0,
          signedCrosswindKmh: 28.0,
        );
        current = lastResult.riders;
      }

      final updatedFollower = current.firstWhere((r) => r.riderId == 'follower');
      expect(updatedFollower.draftingTargetRiderId, equals('leader'));
      // Przy dodatnim wietrze bocznym kolarz ustawia sie lekko po przekatnej (> 0.15 m).
      expect(updatedFollower.lateralOffsetMeters, greaterThan(0.15));
    });

    test('Overtaking Lane Finder wybiera wolny korytarz w 15m, wychyla rower i wyprzedza', () {
      final riders = [
        // Wolniejszy kolarz blokujacy srodek
        const BoidRiderState(
          riderId: 'blocker',
          distanceMeters: 503.0,
          lateralOffsetMeters: 0.0,
          longitudinalSpeedMs: 9.5,
          targetSpeedMs: 9.5,
        ),
        // Kolarz blokujacy prawa strone w promieniu 15m -> wolna powinna byc lewa strona
        const BoidRiderState(
          riderId: 'right_guard',
          distanceMeters: 506.0,
          lateralOffsetMeters: 1.0,
          longitudinalSpeedMs: 10.0,
          targetSpeedMs: 10.0,
        ),
        // Szybki atakujacy kolarz za plecami blockera
        const BoidRiderState(
          riderId: 'attacker',
          distanceMeters: 500.0,
          lateralOffsetMeters: 0.0,
          longitudinalSpeedMs: 11.0,
          targetSpeedMs: 14.0,
          tacticalOrder: TacticalOrder.attack,
        ),
      ];

      var current = riders;
      var sawLeftLane = false;
      var maxAbsLean = 0.0;

      for (var frame = 0; frame < 90; frame++) {
        final res = engine.stepFrame(riders: current, roadWidthMeters: 7.0);
        current = res.riders;
        final attacker = current.firstWhere((r) => r.riderId == 'attacker');
        if (attacker.overtakeLane == OvertakeLaneDirection.left) {
          sawLeftLane = true;
        }
        maxAbsLean = math.max(maxAbsLean, attacker.leanAngleRad.abs());
      }

      final finalAttacker = current.firstWhere((r) => r.riderId == 'attacker');
      final finalBlocker = current.firstWhere((r) => r.riderId == 'blocker');

      expect(sawLeftLane, isTrue);
      expect(maxAbsLean, greaterThan(0.02));
      expect(finalAttacker.distanceMeters, greaterThan(finalBlocker.distanceMeters));
    });

    test('Zwezenie szosy na bruk 3.2m wywoluje efekt akordeonu (gruppo allungato)', () {
      const cobbleSegment = StageSegment(
        index: 1,
        startKm: 10.0,
        lengthKm: 2.5,
        startElevationM: 40.0,
        endElevationM: 42.0,
        surfaceType: SegmentSurfaceType.cobblestonesSector4,
        technicalDifficulty: 85.0,
        windDirectionDegrees: 0.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.none,
      );

      final initialRiders = List<BoidRiderState>.generate(40, (i) {
        final row = i ~/ 8;
        final col = i % 8;
        return BoidRiderState(
          riderId: 'p_$i',
          distanceMeters: 500.0 - row * 2.1,
          lateralOffsetMeters: -2.8 + col * 0.8,
          longitudinalSpeedMs: 11.5,
          targetSpeedMs: 11.5,
        );
      });

      final wideResult = engine.stepFrame(
        riders: initialRiders,
        roadWidthMeters: 7.0,
      );

      var narrowCurrent = initialRiders;
      late BoidsFrameResult narrowResult;
      for (var frame = 0; frame < 60; frame++) {
        narrowResult = engine.stepFrame(
          riders: narrowCurrent,
          segment: cobbleSegment,
        );
        narrowCurrent = narrowResult.riders;
      }

      expect(narrowResult.effectiveRoadWidthMeters, equals(3.2));
      expect(
        narrowResult.pelotonLengthMeters,
        greaterThan(wideResult.pelotonLengthMeters),
      );

      // Kazdy kolarz musi zmiescic sie w waskim korytarzu bruku 3.2 m.
      for (final r in narrowCurrent) {
        expect(r.lateralOffsetMeters.abs(), lessThanOrEqualTo(1.28));
      }
    });
  });
}
