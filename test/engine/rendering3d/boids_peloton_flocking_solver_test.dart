import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/boids_peloton_flocking_solver.dart';

void main() {
  group('BoidsPelotonFlockingSolver', () {
    test('handles empty and inactive rider lists safely', () {
      final solver = BoidsPelotonFlockingSolver();
      final emptyResult = solver.step(const []);
      expect(emptyResult.agents, isEmpty);
      expect(emptyResult.activeRiderCount, 0);

      final inactiveResult = solver.step(const [
        PelotonBoidAgent(
          riderId: 'dnf-1',
          distanceMeters: 100.0,
          lateralOffsetMeters: 0.0,
          speedMs: 11.0,
          desiredSpeedMs: 11.0,
          isActive: false,
        ),
      ]);
      expect(inactiveResult.activeRiderCount, 0);
      expect(inactiveResult.agents.single.speedMs, 0.0);
    });

    test('Separation enforces minimum 0.45m lateral clearance', () {
      final solver = BoidsPelotonFlockingSolver();
      var agents = [
        const PelotonBoidAgent(
          riderId: 'r1',
          distanceMeters: 500.0,
          lateralOffsetMeters: 0.0,
          speedMs: 12.0,
          desiredSpeedMs: 12.0,
        ),
        const PelotonBoidAgent(
          riderId: 'r2',
          distanceMeters: 500.3,
          lateralOffsetMeters: 0.1,
          speedMs: 12.0,
          desiredSpeedMs: 12.0,
        ),
      ];

      for (var i = 0; i < 30; i++) {
        agents = solver.step(agents, dtSeconds: 1.0 / 60.0).agents;
      }

      final lateralGap =
          (agents[0].lateralOffsetMeters - agents[1].lateralOffsetMeters).abs();
      expect(lateralGap, greaterThanOrEqualTo(0.45 - 1e-3));
    });

    test('Alignment matches speed to rider ahead in same corridor', () {
      final solver = BoidsPelotonFlockingSolver();
      const agents = [
        PelotonBoidAgent(
          riderId: 'leader',
          distanceMeters: 1003.0,
          lateralOffsetMeters: 0.0,
          speedMs: 10.5,
          desiredSpeedMs: 10.5,
        ),
        PelotonBoidAgent(
          riderId: 'follower',
          distanceMeters: 1000.0,
          lateralOffsetMeters: 0.05,
          speedMs: 12.0,
          desiredSpeedMs: 10.8,
        ),
      ];

      final res = solver.step(
        agents,
        dtSeconds: 1.0 / 60.0,
        collectBreakdowns: true,
      );
      final followerBreakdown = res.breakdowns['follower']!;
      expect(followerBreakdown.alignment.longitudinal, lessThan(0.0));
      expect(res.agents[1].speedMs, lessThan(12.0));
    });

    test('DraftSeeking finds lowest CdA pocket and shifts with crosswind', () {
      final solver = BoidsPelotonFlockingSolver();
      var agents = [
        const PelotonBoidAgent(
          riderId: 'leader',
          distanceMeters: 2001.4,
          lateralOffsetMeters: 0.0,
          speedMs: 12.5,
          desiredSpeedMs: 12.5,
        ),
        const PelotonBoidAgent(
          riderId: 'drafter',
          distanceMeters: 2000.0,
          lateralOffsetMeters: 0.6,
          speedMs: 12.5,
          desiredSpeedMs: 12.5,
        ),
      ];

      final res = solver.step(
        agents,
        dtSeconds: 1.0 / 60.0,
        crosswindSpeedMs: 6.0,
        windAngleRad: math.pi / 2,
        collectBreakdowns: true,
      );
      final drafter = res.agents[1];
      final breakdown = res.breakdowns['drafter']!;

      expect(drafter.draftLeaderId, 'leader');
      expect(drafter.estimatedCda, lessThan(solver.config.baseRiderCda));
      expect(drafter.draftSavingsRatio, greaterThan(0.0));
      expect(breakdown.draftSeeking.magnitude, greaterThan(0.0));
    });

    test('OvertakeLaneShift triggers when deltaV > 0.8 m/s', () {
      final solver = BoidsPelotonFlockingSolver();
      var agents = [
        const PelotonBoidAgent(
          riderId: 'slow',
          distanceMeters: 3004.0,
          lateralOffsetMeters: 0.0,
          speedMs: 10.0,
          desiredSpeedMs: 10.0,
        ),
        const PelotonBoidAgent(
          riderId: 'attacker',
          distanceMeters: 3000.0,
          lateralOffsetMeters: 0.05,
          speedMs: 11.5,
          desiredSpeedMs: 13.0, // deltaV = 3.0 > 0.8 m/s
        ),
      ];

      final firstStep = solver.step(
        agents,
        dtSeconds: 1.0 / 60.0,
        collectBreakdowns: true,
      );
      final breakdown = firstStep.breakdowns['attacker']!;
      expect(breakdown.overtakeDirection, isNot(0));
      expect(breakdown.overtakeLaneShift.lateral.abs(), greaterThan(0.0));

      agents = firstStep.agents;
      for (var i = 0; i < 40; i++) {
        agents = solver.step(agents, dtSeconds: 1.0 / 60.0).agents;
      }
      expect(agents[1].lateralOffsetMeters.abs(), greaterThan(0.35));
    });

    test('176-rider peloton 1000-step simulation stays bounded and fast (< 2.0ms/step)', () {
      final solver = BoidsPelotonFlockingSolver();
      var agents = List<PelotonBoidAgent>.generate(176, (i) {
        final row = i ~/ 8;
        final col = i % 8;
        return PelotonBoidAgent(
          riderId: 'rider-$i',
          distanceMeters: 5000.0 - row * 2.1,
          lateralOffsetMeters: -2.45 + col * 0.70,
          speedMs: 12.2 + (i % 5) * 0.15,
          desiredSpeedMs: 12.2 + (i % 7) * 0.2,
        );
      });

      final sw = Stopwatch()..start();
      for (var s = 0; s < 1000; s++) {
        agents = solver.step(agents, dtSeconds: 1.0 / 60.0).agents;
      }
      sw.stop();

      final avgMs = sw.elapsedMicroseconds / 1000.0 / 1000.0;
      expect(avgMs, lessThan(2.0));

      for (final a in agents) {
        expect(a.distanceMeters.isFinite, isTrue);
        expect(a.lateralOffsetMeters.isFinite, isTrue);
        expect(a.lateralOffsetMeters.abs(), lessThanOrEqualTo(3.5));
        expect(a.speedMs, greaterThanOrEqualTo(0.0));
      }
    });
  });
}
