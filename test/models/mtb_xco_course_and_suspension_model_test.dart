import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/mtb_xco_course_and_suspension_model.dart';

void main() {
  group('MtbXcoCourseAndSuspensionModel', () {
    test('noveMestoWorldCup preset has 4.2 km lap, rock gardens, drops and roots', () {
      final course = MtbXcoCourseAndSuspensionModel.noveMestoWorldCup();

      expect(course.lapDistanceKm, 4.2);
      expect(course.totalLaps, 6);
      expect(course.totalRaceDistanceKm, closeTo(26.02, 0.01));
      expect(course.rockGardenCount, greaterThanOrEqualTo(1));
      expect(course.dropCount, greaterThanOrEqualTo(1));
      expect(course.rootSectionCount, greaterThanOrEqualTo(1));
      expect(course.recommendedTravelMm, 120);
      expect(course.aLineShareRatio, greaterThan(0.0));
    });

    test('segmentAtDistance resolves segments across lap distance', () {
      final course = MtbXcoCourseAndSuspensionModel.olympicXcoDefault();

      final startSeg = course.segmentAtDistance(150.0);
      expect(startSeg?.featureType, MtbXcoFeatureType.startLoop);

      final rockSeg = course.segmentAtDistance(750.0);
      expect(rockSeg?.featureType, MtbXcoFeatureType.rockGarden);
      expect(rockSeg?.hasLineSplit, isTrue);

      final wrappedSeg = course.segmentAtDistance(4350.0);
      expect(wrappedSeg?.featureType, MtbXcoFeatureType.startLoop);
    });

    test('JSON round-trip preserves course and segments', () {
      final original = MtbXcoCourseAndSuspensionModel.noveMestoWorldCup();
      final decoded =
          MtbXcoCourseAndSuspensionModel.fromJson(original.toJson());

      expect(decoded.courseId, original.courseId);
      expect(decoded.name, original.name);
      expect(decoded.lapDistanceKm, original.lapDistanceKm);
      expect(decoded.segments.length, original.segments.length);
      expect(
        decoded.segments[1].aLine?.timeAdvantageSeconds,
        original.segments[1].aLine?.timeAdvantageSeconds,
      );
    });
  });

  group('MtbXcoBikeConfiguration & Suspension', () {
    test('evaluateCourseReadiness returns high score for 120mm full-suspension setup', () {
      final course = MtbXcoCourseAndSuspensionModel.noveMestoWorldCup();
      const bike = MtbXcoBikeConfiguration(
        bikeId: 'wc_xc_120',
        modelName: 'Pro XCO 120 Flight',
        totalWeightKg: 9.9,
        suspension: MtbForkAndShockSetup(
          architecture: MtbSuspensionArchitecture.fullSuspensionDowncountry120,
          forkTravelMm: 120,
          rearShockTravelMm: 120,
          hasElectronicFlightAttendant: true,
        ),
        dropperPost: DropperPostSpec(travelMm: 125, isWirelessElectronic: true),
        tireSetup: MtbTire24Setup(widthInches: 2.4, hasRimInsert: true),
      );

      final report = bike.evaluateCourseReadiness(course, 68.0);
      expect(report.overallScore, greaterThan(80.0));
      expect(report.warnings, isEmpty);
      expect(report.estimatedLapTimeSeconds, greaterThan(600.0));
    });

    test('hardtail on rough 120mm course triggers travel warning', () {
      final course = MtbXcoCourseAndSuspensionModel.noveMestoWorldCup();
      const hardtail = MtbXcoBikeConfiguration(
        bikeId: 'ht_100',
        modelName: 'Hardtail XC 100',
        totalWeightKg: 8.8,
        suspension: MtbForkAndShockSetup(
          architecture: MtbSuspensionArchitecture.hardtail,
          forkTravelMm: 100,
          rearShockTravelMm: 0,
        ),
        dropperPost: DropperPostSpec(travelMm: 60),
        tireSetup: MtbTire24Setup(
          frontPressureBar: 1.05,
          rearPressureBar: 1.05,
          hasRimInsert: false,
        ),
      );

      final report = hardtail.evaluateCourseReadiness(course, 75.0);
      expect(report.warnings, isNotEmpty);
      expect(report.recommendations, isNotEmpty);
    });

    test('JSON round-trip preserves MtbXcoBikeConfiguration', () {
      const original = MtbXcoBikeConfiguration(
        bikeId: 'xc_test',
        modelName: 'Test XC 120',
      );
      final decoded = MtbXcoBikeConfiguration.fromJson(original.toJson());

      expect(decoded.bikeId, original.bikeId);
      expect(decoded.suspension.forkTravelMm, 120);
      expect(decoded.dropperPost.travelMm, 100);
      expect(decoded.tireSetup.widthInches, 2.4);
    });
  });
}
