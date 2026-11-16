import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/cyclocross_course_and_mud_model.dart';

void main() {
  group('CyclocrossCourseAndMudModel', () {
    test('createFlandersMudClassic meets UCI 2.5-3.2 km & Nov-Jan window', () {
      final course = CyclocrossCourseAndMudModel.createFlandersMudClassic();

      expect(course.isValidUciLapLength, isTrue);
      expect(course.lapLengthKm, inInclusiveRange(2.5, 3.2));
      expect(course.isWinterWindowValid, isTrue);
      expect(course.raceMonth, CyclocrossMonth.december);
      expect(course.totalRaceDistanceKm, closeTo(22.8, 0.001));
    });

    test('calculates Deep Mud, Sand Pit, Off-Camber, Planks & Stairs metrics', () {
      final course = CyclocrossCourseAndMudModel.createFlandersMudClassic();

      expect(course.deepMudDistanceMeters, closeTo(680.0, 0.01));
      expect(course.sandPitDistanceMeters, closeTo(165.0, 0.01));
      expect(course.offCamberDistanceMeters, closeTo(190.0, 0.01));
      expect(course.totalPlankObstaclesCount, 2);
      expect(course.totalStairStepsCount, 28);
      expect(course.mudRatio, closeTo(680.0 / 2850.0, 0.0001));
      expect(course.sandRatio, closeTo(165.0 / 2850.0, 0.0001));
      expect(course.technicalDifficultyScore, inInclusiveRange(35.0, 85.0));
    });

    test('DoublePitLaneConfig detects both access zones & computes next pit', () {
      final course = CyclocrossCourseAndMudModel.createFlandersMudClassic();
      final pit = course.doublePitLane;

      expect(pit.isBidirectional, isTrue);
      expect(pit.isWithinPitZone(1150.0), isTrue);
      expect(pit.isWithinPitZone(2360.0), isTrue);
      expect(pit.isWithinPitZone(500.0), isFalse);
      expect(
        pit.distanceToNextPitMeters(500.0, course.lapLengthMeters),
        closeTo(620.0, 0.01),
      );
      expect(
        pit.distanceToNextPitMeters(2500.0, course.lapLengthMeters),
        closeTo(1470.0, 0.01),
      );
    });

    test('dismount rules & Crr reflect mud, sand, planks 40cm and stairs', () {
      final course = CyclocrossCourseAndMudModel.createFlandersMudClassic();
      final paved = course.segments.first;
      final mud = course.segmentsByType(CyclocrossTerrainType.deepMud).first;
      final sand = course.segmentsByType(CyclocrossTerrainType.sandPit).first;
      final planks = course.segmentsByType(CyclocrossTerrainType.planks).first;
      final stairs =
          course.segmentsByType(CyclocrossTerrainType.staircaseRunUp).first;

      expect(mud.requiresDismount, isTrue);
      expect(sand.requiresDismount, isTrue);
      expect(stairs.requiresDismount, isTrue);
      expect(planks.plankHeightCm, 40.0);
      expect(planks.requiresDismount, isFalse);

      expect(
        sand.baseRollingResistanceCrr,
        greaterThan(paved.baseRollingResistanceCrr),
      );
      expect(
        mud.baseRollingResistanceCrr,
        greaterThan(paved.baseRollingResistanceCrr),
      );
    });

    test('mud buildup & pit swap recommendation scale with laps', () {
      final course = CyclocrossCourseAndMudModel.createFlandersMudClassic();

      expect(course.estimateMudWeightKgOnBike(lapsSinceLastPitSwap: 0), 0.0);
      final after3Laps = course.estimateMudWeightKgOnBike(
        lapsSinceLastPitSwap: 3,
      );
      expect(after3Laps, greaterThan(1.25));
      expect(
        course.shouldRecommendPitBikeSwap(
          lapsSinceLastPitSwap: 3,
          tireClogRatio: 0.4,
        ),
        isTrue,
      );
    });

    test('segmentAtLapDistance & JSON serialization roundtrip work cleanly', () {
      final course = CyclocrossCourseAndMudModel.createFlandersMudClassic();

      final seg = course.segmentAtLapDistance(1375.0);
      expect(seg?.terrainType, CyclocrossTerrainType.planks);

      final wrapped = course.segmentAtLapDistance(2850.0 + 100.0);
      expect(wrapped?.terrainType, CyclocrossTerrainType.pavedStartFinish);

      final json = course.toJson();
      final decoded = CyclocrossCourseAndMudModel.fromJson(json);
      expect(decoded, equals(course));
      expect(decoded.hashCode, equals(course.hashCode));
    });
  });
}
