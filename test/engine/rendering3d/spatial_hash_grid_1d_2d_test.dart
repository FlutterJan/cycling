import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/boids_peloton_flocking_solver.dart';
import 'package:pro_peloton_manager/engine/rendering3d/spatial_hash_grid_1d_2d.dart';

void main() {
  group('SpatialHashGrid1d2d', () {
    test('1D 5m buckets return exact longitudinal neighbors and ignore hash collisions', () {
      // Mała tablica haszująca (64) wymusza kolizje haszy dla odległych koszyków.
      final grid = SpatialHashGrid1d2d(
        longitudinalBucketMeters: 5.0,
        hashTableSize: 64,
      );

      grid.beginFrame(5);
      grid.insert(0, 100.0); // koszyk 20
      grid.insert(1, 104.9); // koszyk 20
      grid.insert(2, 105.0); // koszyk 21
      grid.insert(3, 420.0); // koszyk 84 (84 - 20 = 64 -> kolizja slotu z koszykiem 20!)
      grid.insert(4, -2.0); // koszyk -1 (ujemne współrzędne)

      final out = Int32List(16);
      final count = grid.queryLongitudinalInto(99.0, 106.0, out, excludeIndex: 0);
      final found = out.sublist(0, count)..sort();
      expect(found, equals([1, 2]));

      final view = grid.queryLongitudinalView(-4.0, -1.0);
      expect(view, equals([4]));

      final visited = <int>[];
      grid.forEachInLongitudinalRange(419.0, 421.0, visited.add);
      expect(visited, equals([3]));

      final stats = grid.computeStats();
      expect(stats.itemCount, 5);
      expect(stats.occupiedBuckets, 3);
      expect(stats.maxBucketDepth, 3);
      expect(stats.longitudinalBucketMeters, 5.0);
      expect(stats.is2dMode, isFalse);
    });

    test('2D mode filters by both longitudinal and lateral buckets and respects activeFlags', () {
      final grid = SpatialHashGrid1d2d(
        longitudinalBucketMeters: 5.0,
        lateralBucketMeters: 1.0,
      );

      final distances = Float64List.fromList([50.0, 52.0, 52.5, 58.0]);
      final laterals = Float64List.fromList([0.2, 0.8, 2.6, 0.3]);
      final active = Uint8List.fromList([1, 1, 1, 0]); // indeks 3 nieaktywny

      grid.rebuildFromArrays(
        4,
        distances,
        laterals: laterals,
        activeFlags: active,
      );

      final out = Int32List(16);
      final count = grid.query2dInto(49.0, 60.0, 0.0, 0.9, out);
      final found = out.sublist(0, count)..sort();
      expect(found, equals([0, 1]));

      final visited2d = <int>[];
      grid.forEachIn2dRange(50.0, 55.0, 2.0, 3.0, visited2d.add);
      expect(visited2d, equals([2]));
    });

    test('176-rider drafting and collision avoidance runs below 0.4 ms per frame', () {
      final solver = BoidsPelotonFlockingSolver();
      var agents = List<PelotonBoidAgent>.generate(176, (i) {
        final row = i ~/ 8;
        final col = i % 8;
        return PelotonBoidAgent(
          riderId: 'rider-$i',
          distanceMeters: 12000.0 - row * 2.05,
          lateralOffsetMeters: -2.45 + col * 0.70,
          speedMs: 12.2 + (i % 5) * 0.12,
          desiredSpeedMs: 12.4 + (i % 7) * 0.15,
        );
      });

      // Rozgrzewka JIT (200 klatek).
      for (var w = 0; w < 200; w++) {
        agents = solver.step(agents, dtSeconds: 1.0 / 60.0).agents;
      }

      const measuredFrames = 1000;
      final sw = Stopwatch()..start();
      for (var f = 0; f < measuredFrames; f++) {
        agents = solver.step(agents, dtSeconds: 1.0 / 60.0).agents;
      }
      sw.stop();

      final avgMsPerFrame = sw.elapsedMicroseconds / 1000.0 / measuredFrames;
      expect(avgMsPerFrame, lessThan(0.4));
    });
  });
}
