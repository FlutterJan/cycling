import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/events/race_protest_and_course_reroute_engine.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

RaceStage _buildMountainStage() {
  return const RaceStage(
    id: 'stage_18_galibier',
    stageNumber: 18,
    name: 'Etap 18: Briançon -> Col du Galibier',
    stageType: StageType.highMountain,
    baseTemperatureCelsius: 4.0,
    weatherCondition: WeatherCondition.heavyStorm,
    windSpeedKmh: 55.0,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 30.0,
        startElevationM: 1200.0,
        endElevationM: 1350.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 20.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.intermediateSprint,
      ),
      StageSegment(
        index: 1,
        startKm: 30.0,
        lengthKm: 20.0,
        startElevationM: 1350.0,
        endElevationM: 2150.0,
        surfaceType: SegmentSurfaceType.roughAsphalt,
        technicalDifficulty: 45.0,
        windDirectionDegrees: 220.0,
        roadBearingDegrees: 45.0,
        sprintOrKomClassification: SegmentClassification.cat1,
      ),
      StageSegment(
        index: 2,
        startKm: 50.0,
        lengthKm: 18.0,
        startElevationM: 2150.0,
        endElevationM: 1400.0,
        surfaceType: SegmentSurfaceType.roughAsphalt,
        technicalDifficulty: 75.0,
        windDirectionDegrees: 200.0,
        roadBearingDegrees: 30.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 3,
        startKm: 68.0,
        lengthKm: 22.0,
        startElevationM: 1400.0,
        endElevationM: 2642.0,
        surfaceType: SegmentSurfaceType.roughAsphalt,
        technicalDifficulty: 55.0,
        windDirectionDegrees: 270.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      ),
      StageSegment(
        index: 4,
        startKm: 90.0,
        lengthKm: 15.0,
        startElevationM: 2642.0,
        endElevationM: 1850.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 65.0,
        windDirectionDegrees: 270.0,
        roadBearingDegrees: 180.0,
        sprintOrKomClassification: SegmentClassification.finishLine,
      ),
    ],
  );
}

void main() {
  group('RaceProtestAndCourseRerouteEngine', () {
    const engine = RaceProtestAndCourseRerouteEngine();

    test('evaluates green protocol in calm conditions', () {
      final stage = _buildMountainStage();
      final result = engine.evaluateExtremeWeather(
        ExtremeWeatherTelemetryInput(
          stage: stage,
          currentRaceKm: 10.0,
          airTemperatureCelsius: 18.0,
          summitTemperatureCelsius: 11.0,
          windGustKmh: 22.0,
          precipitationMmPerHour: 0.0,
          visibilityMeters: 5000.0,
        ),
      );

      expect(result.triggerLevel, UciProtocolTriggerLevel.green);
      expect(result.hazardType, ExtremeWeatherHazardType.none);
      expect(result.recommendedAction, CourseRerouteAction.none);
      expect(result.severityScore, lessThan(28.0));
    });

    test('evaluates red/black blizzard protocol with freezing summit and ice', () {
      final stage = _buildMountainStage();
      final result = engine.evaluateExtremeWeather(
        ExtremeWeatherTelemetryInput(
          stage: stage,
          currentRaceKm: 25.0,
          airTemperatureCelsius: 3.0,
          summitTemperatureCelsius: -2.5,
          windGustKmh: 72.0,
          precipitationMmPerHour: 8.0,
          visibilityMeters: 60.0,
          iceOnRoadSurface: true,
          pelotonColdStressIndex: 85.0,
          cpaRepresentativeSupport: 0.85,
        ),
      );

      expect(result.hazardType, ExtremeWeatherHazardType.blizzardAndSnow);
      expect(
        result.triggerLevel == UciProtocolTriggerLevel.red ||
            result.triggerLevel == UciProtocolTriggerLevel.black,
        isTrue,
      );
      expect(result.recommendedAction, isNot(CourseRerouteAction.none));
      expect(result.triggeredRules, isNotEmpty);
    });

    test('evaluates landslide ahead of peloton and recommends reroute', () {
      final stage = _buildMountainStage();
      final result = engine.evaluateExtremeWeather(
        ExtremeWeatherTelemetryInput(
          stage: stage,
          currentRaceKm: 15.0,
          airTemperatureCelsius: 14.0,
          summitTemperatureCelsius: 9.0,
          windGustKmh: 25.0,
          precipitationMmPerHour: 5.0,
          visibilityMeters: 1500.0,
          hasLandslideReport: true,
          landslideKm: 55.0,
        ),
      );

      expect(result.hazardType, ExtremeWeatherHazardType.landslideAndRockfall);
      expect(result.triggerLevel, UciProtocolTriggerLevel.red);
      expect(result.recommendedAction, CourseRerouteAction.bypassHighPass);
    });

    test('aggregates weighted peloton protest votes accurately', () {
      final consensus = engine.aggregatePelotonProtestVotes(const [
        RaceProtestVoteRecord(
          teamOrRiderId: 't1',
          displayName: 'CPA Rep',
          stance: RiderProtestStance.protestShorten,
          weight: 2.0,
        ),
        RaceProtestVoteRecord(
          teamOrRiderId: 't2',
          displayName: 'Team A',
          stance: RiderProtestStance.protestShorten,
          weight: 1.5,
        ),
        RaceProtestVoteRecord(
          teamOrRiderId: 't3',
          displayName: 'Team B',
          stance: RiderProtestStance.continueRacing,
          weight: 1.0,
        ),
      ]);

      expect(consensus.consensusStance, RiderProtestStance.protestShorten);
      expect(consensus.totalWeight, closeTo(4.5, 1e-6));
      expect(consensus.protestPressure, greaterThan(0.55));
    });

    test('bypassHighPass removes high mountain block and keeps contiguous km', () {
      final stage = _buildMountainStage();
      final rerouted = engine.applyDynamicCourseReroute(
        stage: stage,
        currentRaceKm: 10.0,
        action: CourseRerouteAction.bypassHighPass,
        hazardKm: 42.0,
      );

      expect(rerouted.isStageCancelled, isFalse);
      expect(rerouted.bypassSegmentsAdded, 1);
      expect(rerouted.removedSegmentIndices, isNotEmpty);
      expect(rerouted.cancelledKomPrimes, isNotEmpty);
      expect(rerouted.newDistanceKm, lessThan(rerouted.originalDistanceKm));

      final segs = rerouted.reroutedStage.segments;
      for (int i = 0; i < segs.length; i++) {
        expect(segs[i].index, i);
        if (i > 0) {
          expect(segs[i].startKm, closeTo(segs[i - 1].endKm, 1e-6));
        }
      }
    });

    test('relocateFinishLower truncates stage and sets finishLine', () {
      final stage = _buildMountainStage();
      final rerouted = engine.applyDynamicCourseReroute(
        stage: stage,
        currentRaceKm: 20.0,
        action: CourseRerouteAction.relocateFinishLower,
        hazardKm: 70.0,
      );

      expect(rerouted.isStageCancelled, isFalse);
      expect(rerouted.newDistanceKm, lessThan(rerouted.originalDistanceKm));
      expect(
        rerouted.reroutedStage.segments.last.sprintOrKomClassification,
        SegmentClassification.finishLine,
      );
    });

    test('neutralizeDescent lowers technicalDifficulty on future descents', () {
      final stage = _buildMountainStage();
      final rerouted = engine.applyDynamicCourseReroute(
        stage: stage,
        currentRaceKm: 10.0,
        action: CourseRerouteAction.neutralizeDescent,
      );

      expect(rerouted.neutralizedSegmentIndices, containsAll([2, 4]));
      expect(
        rerouted.reroutedStage.segments[2].technicalDifficulty,
        lessThanOrEqualTo(15.0),
      );
    });

    test('cancelStage clears segments and sets distance to zero', () {
      final stage = _buildMountainStage();
      final rerouted = engine.applyDynamicCourseReroute(
        stage: stage,
        currentRaceKm: 5.0,
        action: CourseRerouteAction.cancelStage,
      );

      expect(rerouted.isStageCancelled, isTrue);
      expect(rerouted.newDistanceKm, 0.0);
      expect(rerouted.reroutedStage.segments, isEmpty);
    });
  });

  group('RaceProtestAndCourseReroutePanel Widget Tests', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(raceProtestAndRerouteProvider.notifier).evaluateTelemetry(
            ExtremeWeatherTelemetryInput(
              stage: _buildMountainStage(),
              currentRaceKm: 15.0,
              airTemperatureCelsius: 2.0,
              summitTemperatureCelsius: -1.5,
              windGustKmh: 76.0,
              precipitationMmPerHour: 9.0,
              visibilityMeters: 75.0,
              iceOnRoadSurface: true,
              cpaRepresentativeSupport: 0.75,
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: RaceProtestAndCourseReroutePanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Protokół Ekstremalnej Pogody UCI'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    testWidgets('renders cleanly at 390x844 (mobile)', (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
    });

    testWidgets('renders cleanly at 1024x768 (tablet)', (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
    });

    testWidgets('renders cleanly at 1600x900 (desktop)', (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
    });
  });
}
