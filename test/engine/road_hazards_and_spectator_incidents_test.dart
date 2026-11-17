import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/events/road_hazards_and_spectator_incidents.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

RaceStage _buildMixedTestStage({
  WeatherCondition weather = WeatherCondition.lightRain,
}) {
  return RaceStage(
    id: 'stage_test_336',
    stageNumber: 12,
    name: 'Test Mixed Mountain & Sprint Stage',
    stageType: StageType.hilly,
    baseTemperatureCelsius: 16.0,
    weatherCondition: weather,
    windSpeedKmh: 18.0,
    segments: const [
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 18.0,
        startElevationM: 200.0,
        endElevationM: 210.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 25.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 180.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 1,
        startKm: 18.0,
        lengthKm: 6.0,
        startElevationM: 210.0,
        endElevationM: 690.0,
        surfaceType: SegmentSurfaceType.roughAsphalt,
        technicalDifficulty: 58.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 180.0,
        sprintOrKomClassification: SegmentClassification.cat1,
      ),
      StageSegment(
        index: 2,
        startKm: 24.0,
        lengthKm: 6.0,
        startElevationM: 690.0,
        endElevationM: 240.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 72.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 180.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 3,
        startKm: 30.0,
        lengthKm: 10.0,
        startElevationM: 240.0,
        endElevationM: 245.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 60.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 180.0,
        sprintOrKomClassification: SegmentClassification.finishLine,
      ),
    ],
  );
}

List<RiderHazardExposureInput> _buildTestRiders() {
  return const [
    RiderHazardExposureInput(
      riderId: 'r_break',
      riderName: 'Jan Kowalski',
      teamId: 'team_a',
      bibNumber: 11,
      isInBreakaway: true,
      pelotonPositionIndex: 0,
      groupSize: 4,
      currentSpeedKmh: 58.0,
      bikeHandlingSkill: 88.0,
      descendingSkill: 86.0,
      positioningSkill: 84.0,
      isLeader: true,
    ),
    RiderHazardExposureInput(
      riderId: 'r_front',
      riderName: 'Marco Rossi',
      teamId: 'team_b',
      bibNumber: 21,
      isInBreakaway: false,
      pelotonPositionIndex: 4,
      groupSize: 120,
      currentSpeedKmh: 60.0,
      bikeHandlingSkill: 82.0,
      descendingSkill: 80.0,
      positioningSkill: 85.0,
    ),
    RiderHazardExposureInput(
      riderId: 'r_back',
      riderName: 'Lucas Petit',
      teamId: 'team_c',
      bibNumber: 88,
      isInBreakaway: false,
      pelotonPositionIndex: 110,
      groupSize: 120,
      currentSpeedKmh: 58.0,
      bikeHandlingSkill: 65.0,
      descendingSkill: 64.0,
      positioningSkill: 62.0,
      fatigueRatio: 0.65,
    ),
  ];
}

void main() {
  const engine = RoadHazardsAndSpectatorincidents();

  group('RoadHazardsAndSpectatorincidents Engine', () {
    test('generates traffic islands in final 5 km and stage hazards deterministically', () {
      final stage = _buildMixedTestStage();
      final zonesA = engine.generateStageHazardZones(
        stage: stage,
        seed: 2026,
        spectatorDensity: 0.85,
      );
      final zonesB = engine.generateStageHazardZones(
        stage: stage,
        seed: 2026,
        spectatorDensity: 0.85,
      );

      expect(zonesA.length, zonesB.length);
      expect(zonesA, isNotEmpty);

      final islands = zonesA
          .where((z) => z.type == RoadHazardType.trafficIslandBottleneck)
          .toList();
      expect(islands, isNotEmpty);
      for (final island in islands) {
        expect(island.isInFinal5Km, isTrue);
        expect(island.hasYellowCones, isTrue);
        expect(island.roadWidthMeters, lessThan(4.5));
      }

      final types = zonesA.map((z) => z.type).toSet();
      expect(types, contains(RoadHazardType.railwayLevelCrossing));
      expect(types, contains(RoadHazardType.carelessSpectatorPhoto));
      expect(types, contains(RoadHazardType.wetPedestrianCrosswalk));
    });

    test('traffic island creates accordion delay for riders at back of peloton', () {
      const island = RoadHazardZone(
        id: 'island_1',
        type: RoadHazardType.trafficIslandBottleneck,
        kilometerMark: 182.5,
        distanceToFinishKm: 2.5,
        roadWidthMeters: 3.3,
        hasYellowCones: true,
        severity: HazardSeverityLevel.high,
        descriptionPl: 'Wysepka 2.5 km przed metą',
        radioWarningPl: 'Uwaga wysepka!',
      );

      final report = engine.evaluateHazardEncounter(
        hazard: island,
        input: RoadHazardEvaluationInput(
          weatherCondition: WeatherCondition.sunny,
          pelotonSpeedKmh: 61.0,
          riders: _buildTestRiders(),
          seed: 101,
        ),
      );

      expect(report.accordionDelayBackOfPelotonSeconds, greaterThan(0.0));
      final backImpact =
          report.affectedRiders.firstWhere((r) => r.riderId == 'r_back');
      expect(backImpact.timeLostSeconds, greaterThan(0.0));
      expect(backImpact.wPrimePenaltyJoules, greaterThan(0.0));
    });

    test('closed railway crossing holds peloton while breakaway gains advantage', () {
      const railway = RoadHazardZone(
        id: 'rail_1',
        type: RoadHazardType.railwayLevelCrossing,
        kilometerMark: 95.0,
        distanceToFinishKm: 45.0,
        railwayBarrierState: RailwayBarrierState.closed,
        barrierClosureDurationSeconds: 28.0,
        severity: HazardSeverityLevel.critical,
        descriptionPl: 'Zamknięty szlaban kolejowy',
        radioWarningPl: 'STOP przed przejazdem!',
      );

      final report = engine.evaluateHazardEncounter(
        hazard: railway,
        input: RoadHazardEvaluationInput(
          weatherCondition: WeatherCondition.overcast,
          pelotonSpeedKmh: 46.0,
          breakawayGapSeconds: 45.0,
          riders: _buildTestRiders(),
          seed: 7,
        ),
      );

      expect(report.triggered, isTrue);
      expect(report.barrierClosedForSeconds, 28.0);
      expect(report.breakawayAdvantageDeltaSeconds, 28.0);

      final breakawayImpact =
          report.affectedRiders.firstWhere((r) => r.riderId == 'r_break');
      final pelotonImpact =
          report.affectedRiders.firstWhere((r) => r.riderId == 'r_front');
      expect(breakawayImpact.outcome, RoadHazardActionOutcome.cleanPassage);
      expect(pelotonImpact.outcome, RoadHazardActionOutcome.neutralizedWait);
      expect(pelotonImpact.timeLostSeconds, 28.0);
    });

    test('risk score reflects wet crosswalks and high-speed oil slicks', () {
      const crosswalk = RoadHazardZone(
        id: 'zebra_1',
        type: RoadHazardType.wetPedestrianCrosswalk,
        kilometerMark: 140.0,
        distanceToFinishKm: 12.0,
        surfaceFrictionMu: 0.34,
        isWetSurface: true,
        severity: HazardSeverityLevel.high,
        descriptionPl: 'Mokre pasy',
        radioWarningPl: 'Śliskie pasy!',
      );
      const oil = RoadHazardZone(
        id: 'oil_1',
        type: RoadHazardType.descentOilSlick,
        kilometerMark: 120.0,
        distanceToFinishKm: 32.0,
        surfaceFrictionMu: 0.24,
        gradientPercent: -7.5,
        severity: HazardSeverityLevel.critical,
        descriptionPl: 'Plama oleju na zjeździe',
        radioWarningPl: 'Plama oleju!',
      );

      final wetRisk = engine.calculateHazardRiskScore(
        hazard: crosswalk,
        weatherCondition: WeatherCondition.heavyStorm,
        approachSpeedKmh: 52.0,
      );
      final oilRisk = engine.calculateHazardRiskScore(
        hazard: oil,
        weatherCondition: WeatherCondition.sunny,
        approachSpeedKmh: 76.0,
      );

      expect(wetRisk, greaterThan(0.45));
      expect(oilRisk, greaterThan(0.65));
    });

    test('JSON round-trip preserves RoadHazardIncidentReport', () {
      const zone = RoadHazardZone(
        id: 'climb_crowd_1',
        type: RoadHazardType.carelessSpectatorPhoto,
        kilometerMark: 155.4,
        distanceToFinishKm: 14.6,
        roadWidthMeters: 3.1,
        spectatorDensityFactor: 0.95,
        severity: HazardSeverityLevel.high,
        descriptionPl: 'Kibice z aparatami na podjeździe',
        radioWarningPl: 'Trzymać środek!',
      );

      final report = engine.evaluateHazardEncounter(
        hazard: zone,
        input: RoadHazardEvaluationInput(
          weatherCondition: WeatherCondition.sunny,
          pelotonSpeedKmh: 22.0,
          riders: _buildTestRiders(),
          seed: 99,
        ),
      );

      final decoded = RoadHazardIncidentReport.fromJson(report.toJson());
      expect(decoded.id, report.id);
      expect(decoded.hazard.type, RoadHazardType.carelessSpectatorPhoto);
      expect(decoded.affectedRiders.length, report.affectedRiders.length);
    });
  });

  group('RoadHazardsAndSpectatorIncidentsPanel Widget', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          final stage = _buildMixedTestStage();
          final hazards = engine.generateStageHazardZones(
            stage: stage,
            seed: 2026,
            spectatorDensity: 0.9,
          );
          RoadHazardZone? warnedZone;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: RoadHazardsAndSpectatorIncidentsPanel(
                    hazards: hazards,
                    onSendDsWarning: (z) => warnedZone = z,
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Zagrożenia Drogowe & Kibice'), findsOneWidget);
          expect(find.text('Ostrzeż kolarzy przez Radio'), findsOneWidget);

          await tester.tap(find.text('Ostrzeż kolarzy przez Radio'));
          await tester.pump(const Duration(milliseconds: 300));

          expect(warnedZone, isNotNull);
          expect(find.text('Ostrzeżenie wysłane'), findsOneWidget);
        },
      );
    }
  });
}
